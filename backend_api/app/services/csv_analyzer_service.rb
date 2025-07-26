# app/services/csv_analyzer_service.rb
class CsvAnalyzerService
  require 'csv'
  require 'digest'

  attr_reader :file_content, :analysis_result

  def initialize(file_content)
    @file_content = file_content
    @analysis_result = {}
  end

  def analyze
    @analysis_result = {
      file_hash: generate_file_hash,
      encoding: detect_encoding,
      delimiter: detect_delimiter,
      line_count: count_lines,
      headers: detect_headers,
      sample_data: extract_sample_data,
      data_types: analyze_data_types,
      validation_errors: validate_structure,
      recommendations: generate_recommendations
    }
  end

  def valid_for_import?
    validation_errors.empty?
  end

  def validation_errors
    @analysis_result[:validation_errors] || []
  end

  private

  def generate_file_hash
    Digest::SHA256.hexdigest(@file_content)
  end

  def detect_encoding
    # Implementação básica
    @file_content.encoding.name
  rescue
    'UTF-8'
  end

  def detect_delimiter
    # Análise das primeiras linhas para detectar delimitador
    sample_lines = @file_content.split("\n").first(3)
    delimiters = [',', ';', '\t', '|']
    delimiter_scores = {}

    delimiters.each do |delimiter|
      scores = sample_lines.map do |line|
        line.count(delimiter)
      end

      # Verificar consistência (mesmo número de delimitadores por linha)
      if scores.uniq.length == 1 && scores.first > 0
        delimiter_scores[delimiter] = scores.first
      end
    end

    # Retornar delimitador com maior score
    delimiter_scores.max_by { |k, v| v }&.first || ','
  end

  def count_lines
    @file_content.split("\n").length
  end

  def detect_headers
    begin
      detected_delimiter = detect_delimiter
      first_line = @file_content.split("\n").first

      headers = CSV.parse_line(first_line, col_sep: detected_delimiter)

      # Limpar e normalizar headers
      headers&.map { |h| h&.strip&.downcase&.gsub(/\s+/, '_') } || []
    rescue
      []
    end
  end

  def extract_sample_data
    begin
      detected_delimiter = detect_delimiter
      lines = @file_content.split("\n")

      # Pegar até 5 linhas de exemplo (excluindo header)
      sample_lines = lines[1..5] || []

      sample_lines.map do |line|
        CSV.parse_line(line, col_sep: detected_delimiter)
      end.compact
    rescue
      []
    end
  end

  def analyze_data_types
    headers = detect_headers
    sample_data = extract_sample_data

    return {} if headers.empty? || sample_data.empty?

    data_types = {}

    headers.each_with_index do |header, index|
      column_values = sample_data.map { |row| row[index] }.compact
      data_types[header] = infer_column_type(column_values)
    end

    data_types
  end

  def infer_column_type(values)
    return 'unknown' if values.empty?

    # Verificar se todos são números
    if values.all? { |v| v.to_s.match?(/^\d+(\.\d+)?$/) }
      return 'numeric'
    end

    # Verificar se são emails
    if values.all? { |v| v.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i) }
      return 'email'
    end

    # Verificar se são datas
    if values.all? { |v| looks_like_date?(v) }
      return 'datetime'
    end

    'text'
  end

  def looks_like_date?(value)
    date_patterns = [
      /^\d{4}-\d{2}-\d{2}/,           # YYYY-MM-DD
      /^\d{2}\/\d{2}\/\d{4}/,         # DD/MM/YYYY
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/ # ISO datetime
    ]

    date_patterns.any? { |pattern| value.to_s.match?(pattern) }
  end

  def validate_structure
    errors = []
    headers = detect_headers

    # Verificar se tem headers necessários
    required_headers = ['patient_email', 'test_type', 'measured_value', 'unit', 'measured_at']
    missing_headers = required_headers - headers

    if missing_headers.any?
      errors << "Missing required headers: #{missing_headers.join(', ')}"
    end

    # Verificar se tem dados
    if count_lines < 2
      errors << "File must have at least one data row besides header"
    end

    # Verificar delimitador
    if detect_delimiter.nil?
      errors << "Could not detect CSV delimiter"
    end

    errors
  end

  def generate_recommendations
    recommendations = []

    # Verificar tamanho do arquivo
    if count_lines > 1000
      recommendations << "Large file detected. Consider splitting into smaller files for better performance"
    end

    # Verificar delimitador não padrão
    if detect_delimiter != ','
      recommendations << "Non-standard delimiter detected. Ensure your CSV uses standard comma separation"
    end

    recommendations
  end
end

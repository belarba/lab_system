class Api::UploadsController < ApplicationController
  include Authenticable
  before_action :set_upload, only: [:show, :download, :delete_file, :reprocess, :analysis]

  def index
    # Apenas lab technicians e admins podem ver uploads
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    @uploads = LabFileUpload.includes(:uploaded_by)
                           .recent
                           .limit(params[:limit] || 50)
                           .offset(params[:offset] || 0)

    # Filtrar por status se especificado
    @uploads = @uploads.by_status(params[:status]) if params[:status].present?

    # Admin pode ver todos, lab tech apenas os próprios
    unless current_user.admin?
      @uploads = @uploads.where(uploaded_by: current_user)
    end

    @limit = params[:limit] || 50
    @offset = params[:offset] || 0
    @total = current_user.admin? ? LabFileUpload.count : LabFileUpload.where(uploaded_by: current_user).count

    render 'api/uploads/index'
  end

  def show
    return render_forbidden unless can_view_upload?(@upload)
    render 'api/uploads/show'
  end

  def create
    # Apenas lab technicians e admins podem fazer upload
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    unless params[:file].present?
      return render json: { error: 'File is required' }, status: :bad_request
    end

    file = params[:file]

    # Validações básicas
    validation_result = validate_upload_file(file)
    return render json: validation_result, status: :bad_request if validation_result[:error]

    begin
      # Ler conteúdo do arquivo
      file.rewind if file.respond_to?(:rewind)
      file_content = file.read
      file_size = file_content.bytesize

      # Validações de conteúdo
      content_validation = validate_file_content(file_content, file_size)
      return render json: content_validation, status: :bad_request if content_validation[:error]

      # Criar registro de upload
      @upload = LabFileUpload.create!(
        filename: file.original_filename,
        file_size: file_size,
        uploaded_by: current_user,
        status: 'pending'
      )

      # Processar CSV de forma assíncrona se necessário ou síncrona para arquivos pequenos
      if file_size > 1.megabyte
        # Para arquivos grandes, processar em background
        CsvImportJob.perform_later(@upload.id, file_content)
        render 'api/uploads/create_async', status: :accepted
      else
        # Para arquivos pequenos, processar imediatamente
        CsvImportService.new(@upload, file_content).process
        render 'api/uploads/create', status: :created
      end

    rescue => e
      Rails.logger.error "Upload failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        error: 'Failed to process upload',
        message: e.message
      }, status: :unprocessable_entity
    end
  end

  def validate
    # Endpoint para validar arquivo sem processar
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    unless params[:file].present?
      return render json: { error: 'File is required' }, status: :bad_request
    end

    file = params[:file]
    validation_result = validate_upload_file(file)
    return render json: validation_result, status: :bad_request if validation_result[:error]

    begin
      file.rewind if file.respond_to?(:rewind)
      file_content = file.read

      # Analisar arquivo
      analyzer = CsvAnalyzerService.new(file_content)
      analyzer.analyze

      render json: {
        valid: analyzer.valid_for_import?,
        analysis: analyzer.analysis_result,
        filename: file.original_filename
      }

    rescue => e
      render json: {
        valid: false,
        error: e.message,
        filename: file.original_filename
      }, status: :unprocessable_entity
    end
  end

  def download
    return render_forbidden unless can_view_upload?(@upload)

    # Verificar se arquivo existe no servidor
    file_path = get_file_path(@upload)

    unless file_path && File.exist?(file_path)
      return render json: { error: 'File not found on server' }, status: :not_found
    end

    send_file file_path,
              filename: @upload.filename,
              type: 'text/csv',
              disposition: 'attachment'
  end

  def delete_file
    return render_forbidden unless can_delete_upload?(@upload)

    begin
      # Remover arquivo físico se existir
      file_path = get_file_path(@upload)
      if file_path && File.exist?(file_path)
        File.delete(file_path)
      end

      # Remover registro do banco
      @upload.destroy!

      render json: { message: 'Upload deleted successfully' }, status: :ok
    rescue => e
      Rails.logger.error "Failed to delete upload #{@upload.id}: #{e.message}"
      render json: { error: 'Failed to delete upload' }, status: :unprocessable_entity
    end
  end

  def reprocess
    return render_forbidden unless current_user.admin? || current_user == @upload.uploaded_by

    # Verificar se arquivo existe
    file_path = get_file_path(@upload)
    unless file_path && File.exist?(file_path)
      return render json: { error: 'Original file not found' }, status: :not_found
    end

    begin
      # Resetar status
      @upload.update!(
        status: 'pending',
        processed_records: 0,
        failed_records: 0,
        error_details: nil,
        processing_summary: nil,
        retry_count: (@upload.retry_count || 0) + 1
      )

      # Reprocessar
      file_content = File.read(file_path)
      CsvImportService.new(@upload, file_content).process

      render 'api/uploads/reprocess', status: :ok
    rescue => e
      render json: { error: "Reprocessing failed: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def analysis
    return render_forbidden unless can_view_upload?(@upload)

    analysis_data = {
      file_info: {
        filename: @upload.filename,
        file_size: @upload.file_size,
        file_size_human: @upload.file_size_human,
        file_hash: @upload.file_hash,
        encoding: @upload.file_encoding,
        delimiter: @upload.detected_delimiter
      },
      processing_info: {
        status: @upload.status,
        started_at: @upload.processing_started_at,
        completed_at: @upload.processing_completed_at,
        duration: @upload.processing_duration,
        retry_count: @upload.retry_count || 0
      },
      statistics: {
        total_records: @upload.total_records,
        processed_records: @upload.processed_records,
        failed_records: @upload.failed_records,
        success_rate: @upload.success_rate,
        failure_rate: @upload.failure_rate
      },
      errors: @upload.processing_errors,
      headers: @upload.detected_headers.present? ? JSON.parse(@upload.detected_headers) : []
    }

    render json: { analysis: analysis_data }
  end

  def stats
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    # Estatísticas baseadas no usuário
    base_scope = current_user.admin? ? LabFileUpload : LabFileUpload.where(uploaded_by: current_user)

    stats = {
      uploads: {
        total: base_scope.count,
        by_status: base_scope.group(:status).count,
        recent: base_scope.where('created_at > ?', 7.days.ago).count,
        today: base_scope.where('created_at > ?', 1.day.ago).count
      },
      processing: {
        total_records_processed: base_scope.sum(:processed_records),
        total_records_failed: base_scope.sum(:failed_records),
        average_success_rate: base_scope.average(:success_rate)&.round(2) || 0,
        average_processing_time: calculate_average_processing_time(base_scope)
      },
      storage: {
        total_file_size: base_scope.sum(:file_size),
        total_file_size_human: format_bytes(base_scope.sum(:file_size)),
        largest_file: base_scope.maximum(:file_size),
        average_file_size: base_scope.average(:file_size)&.round(0) || 0
      }
    }

    render json: { stats: stats }
  end

  private

  def set_upload
    @upload = LabFileUpload.find_by(id: params[:upload_id] || params[:id])
    return render_not_found('Upload not found') unless @upload
  end

  def validate_upload_file(file)
    # Verificar se é um objeto de upload válido
    unless file.respond_to?(:original_filename) && file.respond_to?(:read)
      return { error: 'Invalid file format' }
    end

    # Validar tipo de arquivo
    content_type = file.respond_to?(:content_type) ? file.content_type : nil
    filename = file.original_filename

    unless content_type == 'text/csv' || filename&.end_with?('.csv')
      return { error: 'Only CSV files are allowed' }
    end

    # Validar nome do arquivo
    if filename.blank? || filename.length > 255
      return { error: 'Invalid filename' }
    end

    # Sucesso - sem erro
    {}
  end

  def validate_file_content(file_content, file_size)
    # Validar se arquivo não está vazio
    if file_content.blank?
      return { error: 'File is empty' }
    end

    # Validar tamanho (máximo 50MB)
    if file_size > 50.megabytes
      return { error: 'File size too large (max 50MB)' }
    end

    # Validar se parece ser CSV válido
    begin
      lines = file_content.split("\n")
      if lines.length < 2
        return { error: 'CSV must have at least header and one data row' }
      end

      # Verificar se primeira linha parece header
      header = lines.first
      if header.split(',').length < 3
        return { error: 'CSV must have at least 3 columns' }
      end

    rescue => e
      return { error: 'Invalid file content' }
    end

    # Sucesso - sem erro
    {}
  end

  def get_file_path(upload)
    # Extrair caminho do arquivo do processing_summary
    begin
      summary = upload.processing_summary_data
      summary['file_path']
    rescue
      nil
    end
  end

  def can_view_upload?(upload)
    # Admin pode ver tudo, lab tech pode ver seus próprios uploads
    current_user.admin? || current_user == upload.uploaded_by
  end

  def can_delete_upload?(upload)
    # Apenas admin ou o próprio usuário pode deletar
    current_user.admin? || current_user == upload.uploaded_by
  end

  def calculate_average_processing_time(scope)
    completed_uploads = scope.where.not(processing_started_at: nil, processing_completed_at: nil)
    return 0 if completed_uploads.empty?

    total_duration = completed_uploads.sum do |upload|
      (upload.processing_completed_at - upload.processing_started_at) / 1.minute
    end

    (total_duration / completed_uploads.count).round(2)
  end

  def format_bytes(bytes)
    return '0 B' if bytes.nil? || bytes == 0

    units = ['B', 'KB', 'MB', 'GB', 'TB']
    exp = (Math.log(bytes) / Math.log(1024)).floor
    exp = [exp, units.length - 1].min

    "#{(bytes.to_f / (1024 ** exp)).round(2)} #{units[exp]}"
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end

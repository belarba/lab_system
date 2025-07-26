require 'rails_helper'

RSpec.describe CsvAnalyzerService do
  describe '#analyze' do
    context 'with valid CSV content' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          john@example.com,Glucose,95.5,mg/dL,2025-04-23T08:30:00Z
          jane@example.com,Cholesterol,185.2,mg/dL,2025-04-23T09:15:00Z
        CSV
      end

      it 'analyzes CSV structure correctly' do
        analyzer = CsvAnalyzerService.new(csv_content)
        analyzer.analyze

        result = analyzer.analysis_result

        expect(result[:file_hash]).to be_present
        expect(result[:encoding]).to eq('UTF-8')
        expect(result[:delimiter]).to eq(',')
        expect(result[:line_count]).to eq(3) # header + 2 data lines
        expect(result[:headers]).to eq(['patient_email', 'test_type', 'measured_value', 'unit', 'measured_at'])
        expect(result[:sample_data].length).to eq(2) # Usar .length ao invés de have(2).items
        expect(result[:validation_errors]).to be_empty
      end

      it 'detects data types correctly' do
        analyzer = CsvAnalyzerService.new(csv_content)
        analyzer.analyze

        data_types = analyzer.analysis_result[:data_types]

        expect(data_types['patient_email']).to eq('email')
        expect(data_types['measured_value']).to eq('numeric')
        expect(data_types['measured_at']).to eq('datetime')
      end

      it 'validates as suitable for import' do
        analyzer = CsvAnalyzerService.new(csv_content)
        analyzer.analyze

        expect(analyzer.valid_for_import?).to be_truthy
        expect(analyzer.validation_errors).to be_empty
      end
    end

    context 'with invalid CSV content' do
      let(:invalid_csv) do
        <<~CSV
          wrong_header,bad_header
          some,data,with,too,many,columns
          more,inconsistent,data
        CSV
      end

      it 'detects validation errors' do
        analyzer = CsvAnalyzerService.new(invalid_csv)
        analyzer.analyze

        expect(analyzer.valid_for_import?).to be_falsy
        expect(analyzer.validation_errors).not_to be_empty
        expect(analyzer.validation_errors.first).to include('Missing required headers')
      end
    end

    context 'with malformed CSV' do
      let(:malformed_csv) { "invalid\ncsv,with\ninconsistent,columns,everywhere" }

      it 'detects structural problems' do
        analyzer = CsvAnalyzerService.new(malformed_csv)
        analyzer.analyze

        expect(analyzer.valid_for_import?).to be_falsy
        expect(analyzer.validation_errors).to include(match(/Missing required headers/))
      end
    end

    context 'with empty file' do
      let(:empty_csv) { "" }

      it 'detects empty file' do
        analyzer = CsvAnalyzerService.new(empty_csv)
        analyzer.analyze

        expect(analyzer.valid_for_import?).to be_falsy
        expect(analyzer.validation_errors).to include(match(/at least one data row/))
      end
    end

    context 'with different delimiters' do
      let(:semicolon_csv) do
        <<~CSV
          patient_email;test_type;measured_value;unit;measured_at
          john@example.com;Glucose;95.5;mg/dL;2025-04-23T08:30:00Z
        CSV
      end

      it 'detects semicolon delimiter' do
        analyzer = CsvAnalyzerService.new(semicolon_csv)
        analyzer.analyze

        expect(analyzer.analysis_result[:delimiter]).to eq(';')
        expect(analyzer.analysis_result[:headers]).to eq(['patient_email', 'test_type', 'measured_value', 'unit', 'measured_at'])
      end
    end

    context 'with encoding issues' do
      let(:latin1_content) { "patíênt_emaíl,tést_typé\nvalüe1,valüe2".encode('ISO-8859-1') }

      it 'detects encoding correctly' do
        analyzer = CsvAnalyzerService.new(latin1_content)
        analyzer.analyze

        # Should detect non-UTF-8 encoding
        expect(analyzer.analysis_result[:encoding]).not_to eq('UTF-8')
      end
    end
  end

  describe 'data type inference' do
    let(:analyzer) { CsvAnalyzerService.new("") }

    it 'identifies numeric values' do
      values = ['123', '45.67', '0.1', '1000']
      expect(analyzer.send(:infer_column_type, values)).to eq('numeric')
    end

    it 'identifies email addresses' do
      values = ['john@example.com', 'jane@test.org', 'admin@company.co.uk']
      expect(analyzer.send(:infer_column_type, values)).to eq('email')
    end

    it 'identifies datetime values' do
      values = ['2025-04-23T08:30:00Z', '2025-04-24', '23/04/2025']
      expect(analyzer.send(:infer_column_type, values)).to eq('datetime')
    end

    it 'defaults to text for mixed values' do
      values = ['text', '123', 'mixed@email.com']
      expect(analyzer.send(:infer_column_type, values)).to eq('text')
    end
  end

  describe 'recommendations' do
    context 'with large file' do
      let(:large_csv) do
        header = "patient_email,test_type,measured_value,unit,measured_at\n"
        rows = (1..2000).map { |i| "patient#{i}@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z" }
        header + rows.join("\n")
      end

      it 'recommends splitting large files' do
        analyzer = CsvAnalyzerService.new(large_csv)
        analyzer.analyze

        recommendations = analyzer.analysis_result[:recommendations]
        expect(recommendations).to include(match(/Large file detected/))
      end
    end

    context 'with non-standard delimiter' do
      let(:tab_csv) do
        <<~CSV
          patient_email\ttest_type\tmeasured_value\tunit\tmeasured_at
          john@example.com\tGlucose\t95.5\tmg/dL\t2025-04-23T08:30:00Z
        CSV
      end

      it 'recommends standard delimiter' do
        analyzer = CsvAnalyzerService.new(tab_csv)
        analyzer.analyze

        expect(analyzer.analysis_result[:delimiter]).to eq("\t")

        recommendations = analyzer.analysis_result[:recommendations]
        expect(recommendations).to be_an(Array)
      end
    end
  end
end

module CsvTestHelpers
  def ensure_upload_directory
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
    upload_dir
  end

  def cleanup_test_files
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    return unless Dir.exist?(upload_dir)

    Dir.glob(File.join(upload_dir, '*')).each do |file|
      File.delete(file) if File.file?(file) && file.include?('test')
    end
  end

  def create_test_csv_content(rows = 2)
    header = "patient_email,test_type,measured_value,unit,measured_at\n"
    data_rows = (1..rows).map do |i|
      date = (Time.current - i.days).iso8601
      "test#{i}@example.com,Glucose,#{90 + i}.0,mg/dL,#{date}"
    end
    header + data_rows.join("\n")
  end
end

RSpec.configure do |config|
  config.include CsvTestHelpers

  # Setup antes de cada teste que usa CSV
  config.before(:each, :csv_test) do
    ensure_upload_directory
  end

  # Cleanup após cada teste que usa CSV
  config.after(:each, :csv_test) do
    cleanup_test_files
  end
end

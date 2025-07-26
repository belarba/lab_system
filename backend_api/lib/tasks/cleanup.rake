namespace :lab_system do
  namespace :cleanup do
    desc "Clean up old uploaded files and records"
    task old_files: :environment do
      puts "Starting cleanup of old uploaded files..."

      # Configurações
      days_to_keep = ENV['DAYS_TO_KEEP']&.to_i || 30
      dry_run = ENV['DRY_RUN'] == 'true'

      puts "Configuration:"
      puts "- Days to keep: #{days_to_keep}"
      puts "- Dry run: #{dry_run}"
      puts ""

      # Encontrar uploads antigos
      cutoff_date = days_to_keep.days.ago
      old_uploads = LabFileUpload.where('created_at < ?', cutoff_date)

      puts "Found #{old_uploads.count} uploads older than #{days_to_keep} days"

      deleted_files = 0
      deleted_records = 0
      freed_space = 0

      old_uploads.find_each do |upload|
        file_path = upload.file_path

        if file_path && File.exist?(file_path)
          file_size = File.size(file_path)

          unless dry_run
            File.delete(file_path)
            puts "Deleted file: #{file_path}"
          else
            puts "Would delete file: #{file_path}"
          end

          deleted_files += 1
          freed_space += file_size
        end

        unless dry_run
          upload.destroy!
          puts "Deleted record: Upload ##{upload.id}"
        else
          puts "Would delete record: Upload ##{upload.id}"
        end

        deleted_records += 1
      end

      puts ""
      puts "Cleanup summary:"
      puts "- Files #{dry_run ? 'would be' : ''} deleted: #{deleted_files}"
      puts "- Records #{dry_run ? 'would be' : ''} deleted: #{deleted_records}"
      puts "- Space #{dry_run ? 'would be' : ''} freed: #{format_bytes(freed_space)}"

      if dry_run
        puts ""
        puts "This was a dry run. To actually delete files, run:"
        puts "DRY_RUN=false rails lab_system:cleanup:old_files"
      end
    end

    desc "Clean up orphaned files (files without database records)"
    task orphaned_files: :environment do
      puts "Starting cleanup of orphaned files..."

      dry_run = ENV['DRY_RUN'] == 'true'
      upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')

      return unless Dir.exist?(upload_dir)

      # Obter todos os caminhos de arquivos do banco
      db_file_paths = LabFileUpload.all.map(&:file_path).compact.to_set

      orphaned_files = []
      freed_space = 0

      Dir.glob(File.join(upload_dir, '*')).each do |file_path|
        next unless File.file?(file_path)

        unless db_file_paths.include?(file_path)
          file_size = File.size(file_path)
          orphaned_files << { path: file_path, size: file_size }
          freed_space += file_size
        end
      end

      puts "Found #{orphaned_files.count} orphaned files"

      orphaned_files.each do |file_info|
        unless dry_run
          File.delete(file_info[:path])
          puts "Deleted orphaned file: #{file_info[:path]}"
        else
          puts "Would delete orphaned file: #{file_info[:path]}"
        end
      end

      puts ""
      puts "Orphaned files cleanup summary:"
      puts "- Files #{dry_run ? 'would be' : ''} deleted: #{orphaned_files.count}"
      puts "- Space #{dry_run ? 'would be' : ''} freed: #{format_bytes(freed_space)}"
    end

    desc "Show storage statistics"
    task stats: :environment do
      puts "Lab System Storage Statistics"
      puts "=============================="

      # Upload statistics
      total_uploads = LabFileUpload.count
      successful_uploads = LabFileUpload.successful.count
      failed_uploads = LabFileUpload.failed.count

      puts ""
      puts "Upload Records:"
      puts "- Total uploads: #{total_uploads}"
      puts "- Successful: #{successful_uploads}"
      puts "- Failed: #{failed_uploads}"
      puts "- Success rate: #{total_uploads > 0 ? (successful_uploads.to_f / total_uploads * 100).round(2) : 0}%"

      # File statistics
      upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
      if Dir.exist?(upload_dir)
        files = Dir.glob(File.join(upload_dir, '*')).select { |f| File.file?(f) }
        total_size = files.sum { |f| File.size(f) }

        puts ""
        puts "File Storage:"
        puts "- Physical files: #{files.count}"
        puts "- Total size: #{format_bytes(total_size)}"
        puts "- Average file size: #{files.count > 0 ? format_bytes(total_size / files.count) : '0 B'}"
      end

      # Database statistics
      total_records_processed = LabFileUpload.sum(:processed_records)
      total_records_failed = LabFileUpload.sum(:failed_records)

      puts ""
      puts "Processing Statistics:"
      puts "- Total records processed: #{total_records_processed}"
      puts "- Total records failed: #{total_records_failed}"
      puts "- Overall success rate: #{(total_records_processed + total_records_failed) > 0 ? (total_records_processed.to_f / (total_records_processed + total_records_failed) * 100).round(2) : 0}%"

      # Recent activity
      recent_uploads = LabFileUpload.where('created_at > ?', 7.days.ago).count
      puts ""
      puts "Recent Activity (last 7 days):"
      puts "- New uploads: #{recent_uploads}"
    end

    private

    def format_bytes(bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      return '0 B' if bytes == 0

      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min

      "#{(bytes.to_f / (1024 ** exp)).round(2)} #{units[exp]}"
    end
  end
end

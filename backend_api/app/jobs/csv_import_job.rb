class CsvImportJob < ApplicationJob
  queue_as :default

  # Configurar retry para jobs que falharam
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(upload_id, file_content)
    upload = LabFileUpload.find(upload_id)

    Rails.logger.info "Starting async CSV import for upload #{upload_id}"

    begin
      # Executar o processamento
      CsvImportService.new(upload, file_content).process

      Rails.logger.info "Completed async CSV import for upload #{upload_id}"

      # Notificar usuário se necessário (via email, websocket, etc.)
      notify_user_completion(upload)

    rescue => e
      Rails.logger.error "Async CSV import failed for upload #{upload_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Marcar como falha se ainda não foi marcado
      upload.update!(
        status: 'failed',
        error_details: "Background processing failed: #{e.message}"
      ) if upload.status == 'processing'

      # Notificar usuário sobre falha
      notify_user_failure(upload, e)

      # Re-raise para que o job seja marcado como falhado
      raise e
    end
  end

  private

  def notify_user_completion(upload)
    # Implementar notificação quando necessário
    # Exemplo: enviar email, push notification, websocket message
    Rails.logger.info "CSV import completed for user #{upload.uploaded_by.email}"
  end

  def notify_user_failure(upload, error)
    # Implementar notificação de falha quando necessário
    Rails.logger.error "CSV import failed for user #{upload.uploaded_by.email}: #{error.message}"
  end
end

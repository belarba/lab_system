class Api::UploadsController < ApplicationController
  include Authenticable
  before_action :set_upload, only: [:show]

  def index
    # Apenas lab technicians e admins podem ver uploads
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    uploads = LabFileUpload.includes(:uploaded_by)
                           .recent
                           .limit(params[:limit] || 50)
                           .offset(params[:offset] || 0)

    # Filtrar por status se especificado
    uploads = uploads.by_status(params[:status]) if params[:status].present?

    render json: {
      uploads: uploads.map { |upload| upload_response(upload) },
      pagination: {
        limit: params[:limit] || 50,
        offset: params[:offset] || 0,
        total: LabFileUpload.count
      }
    }, status: :ok
  end

  def show
    return render_forbidden unless can_view_upload?(@upload)

    render json: {
      upload: detailed_upload_response(@upload)
    }, status: :ok
  end

  def create
    # Apenas lab technicians e admins podem fazer upload
    return render_forbidden unless current_user.lab_technician? || current_user.admin?

    unless params[:file].present?
      return render json: { error: 'File is required' }, status: :bad_request
    end

    file = params[:file]

    # Verificar se é um arquivo de upload válido
    unless file.respond_to?(:original_filename) && file.respond_to?(:read)
      return render json: { error: 'Invalid file format' }, status: :bad_request
    end

    # Validar tipo de arquivo
    content_type = file.respond_to?(:content_type) ? file.content_type : nil
    filename = file.original_filename

    unless content_type == 'text/csv' || filename&.end_with?('.csv')
      return render json: { error: 'Only CSV files are allowed' }, status: :bad_request
    end

    # Validar tamanho (máximo 10MB) - usar size se disponível
    file_size = file.respond_to?(:size) ? file.size : nil
    if file_size && file_size > 10.megabytes
      return render json: { error: 'File size too large (max 10MB)' }, status: :bad_request
    end

    begin
      # Garantir que podemos ler o conteúdo
      file.rewind if file.respond_to?(:rewind)
      file_content = file.read

      # Validar se é um CSV válido
      if file_content.blank?
        return render json: { error: 'File is empty' }, status: :bad_request
      end

      # Se não conseguimos o size antes, calcular agora
      file_size ||= file_content.bytesize
      if file_size > 10.megabytes
        return render json: { error: 'File size too large (max 10MB)' }, status: :bad_request
      end

      # Criar registro de upload
      upload = LabFileUpload.create!(
        filename: filename,
        file_size: file_size,
        uploaded_by: current_user,
        status: 'pending'
      )

      # Processar CSV
      CsvImportService.new(upload, file_content).process

      render json: {
        message: 'File uploaded and processed successfully',
        upload: upload_response(upload.reload)
      }, status: :created

    rescue => e
      Rails.logger.error "Upload failed: #{e.message}"
      render json: {
        error: 'Failed to process upload',
        message: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_upload
    @upload = LabFileUpload.find_by(id: params[:upload_id] || params[:id])
    return render_not_found('Upload not found') unless @upload
  end

  def can_view_upload?(upload)
    # Admin pode ver tudo, lab tech pode ver seus próprios uploads
    current_user.admin? || current_user == upload.uploaded_by
  end

  def upload_response(upload)
    {
      id: upload.id,
      filename: upload.filename,
      file_size: upload.file_size,
      status: upload.status,
      uploaded_by: {
        id: upload.uploaded_by.id,
        name: upload.uploaded_by.name,
        email: upload.uploaded_by.email
      },
      total_records: upload.total_records,
      processed_records: upload.processed_records,
      failed_records: upload.failed_records,
      success_rate: upload.success_rate,
      processed_at: upload.processed_at,
      created_at: upload.created_at,
      updated_at: upload.updated_at
    }
  end

  def detailed_upload_response(upload)
    response = upload_response(upload)
    response.merge({
      error_details: upload.error_details,
      processing_summary: upload.processing_summary_data,
      records_summary: {
        total: upload.total_records,
        processed: upload.processed_records,
        failed: upload.failed_records,
        pending: upload.total_records - upload.processed_records - upload.failed_records,
        success_rate: upload.success_rate
      }
    })
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end
end

class AddImprovementsToLabFileUpload < ActiveRecord::Migration[8.0]
  def change
    # Adicionar novos campos para melhor tracking
    add_column :lab_file_uploads, :original_filename, :string
    add_column :lab_file_uploads, :file_hash, :string # Para detectar arquivos duplicados
    add_column :lab_file_uploads, :processing_started_at, :datetime
    add_column :lab_file_uploads, :processing_completed_at, :datetime
    add_column :lab_file_uploads, :retry_count, :integer, default: 0
    add_column :lab_file_uploads, :file_encoding, :string
    add_column :lab_file_uploads, :detected_delimiter, :string
    add_column :lab_file_uploads, :detected_headers, :text # JSON array dos headers detectados

    # Índices para melhor performance
    add_index :lab_file_uploads, :file_hash
    add_index :lab_file_uploads, :processing_started_at
    add_index :lab_file_uploads, :retry_count
    add_index :lab_file_uploads, [:uploaded_by_id, :status]
    add_index :lab_file_uploads, [:created_at, :status]
  end
end

class CreateLabFileUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :lab_file_uploads do |t|
      t.string :filename, null: false
      t.integer :file_size
      t.string :status, default: 'pending'
      t.datetime :processed_at
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.integer :total_records, default: 0
      t.integer :processed_records, default: 0
      t.integer :failed_records, default: 0
      t.text :error_details
      t.text :processing_summary # JSON com detalhes do processamento

      t.timestamps
    end

    add_index :lab_file_uploads, :status
    add_index :lab_file_uploads, :processed_at
  end
end

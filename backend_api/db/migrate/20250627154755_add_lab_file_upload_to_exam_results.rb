class AddLabFileUploadToExamResults < ActiveRecord::Migration[8.0]
  def change
    add_reference :exam_results, :lab_file_upload, null: true, foreign_key: true
  end
end

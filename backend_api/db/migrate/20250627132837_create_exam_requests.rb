class CreateExamRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_requests do |t|
      t.references :patient, null: false, foreign_key: {to_table: :users}
      t.references :doctor, null: false, foreign_key: {to_table: :users}
      t.references :exam_type, null: false, foreign_key: true
      t.datetime :scheduled_date
      t.string :status
      t.text :notes

      t.timestamps
    end

    add_index :exam_requests, [:patient_id, :doctor_id]
    add_index :exam_requests, :status
    add_index :exam_requests, :scheduled_date
  end
end

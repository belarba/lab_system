class CreateExamResults < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_results do |t|
      t.references :exam_request, null: false, foreign_key: true
      t.decimal :value
      t.string :unit
      t.references :lab_technician, null: false, foreign_key: {to_table: :users}
      t.datetime :performed_at
      t.text :notes

      t.timestamps
    end

    add_index :exam_results, :performed_at
  end
end

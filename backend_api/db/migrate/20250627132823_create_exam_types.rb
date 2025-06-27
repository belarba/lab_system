class CreateExamTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_types do |t|
      t.string :name
      t.text :description
      t.text :reference_range
      t.string :unit

      t.timestamps
    end
  end
end

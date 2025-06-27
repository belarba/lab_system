class CreateUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    # Evitar que um usuário tenha o mesmo role duplicado
    add_index :user_roles, [:user_id, :role_id], unique: true
  end
end

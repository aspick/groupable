class CreateGroupableTables < ActiveRecord::Migration[7.2]
  def change
    create_table :groupable_groups do |t|
      t.string :name, null: false
      t.string :auth_name
      t.string :password_digest
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :groupable_groups, :active

    create_table :groupable_members do |t|
      t.references :user, null: false
      t.references :group, null: false, foreign_key: { to_table: :groupable_groups }
      t.integer :role, null: false, default: 1

      t.timestamps
    end

    add_index :groupable_members, [:user_id, :group_id], unique: true

    create_table :groupable_invites do |t|
      t.references :group, null: false, foreign_key: { to_table: :groupable_groups }
      t.string :code, null: false, index: true

      t.timestamps
    end

    add_index :groupable_invites, :code
    add_index :groupable_invites, :created_at
  end
end

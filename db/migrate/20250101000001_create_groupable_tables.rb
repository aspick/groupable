class CreateGroupableTables < ActiveRecord::Migration[7.2]
  def change
    create_table :groupable_groups do |t|
      t.string :name, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :groupable_groups, :active

    # No foreign key constraints on group_id / user_id: the referenced tables
    # depend on the host configuration (group_class_name / user_class_name),
    # so they cannot be fixed to groupable_groups / users here. Add them in
    # your app if you use the engine's models exclusively.
    create_table :groupable_members do |t|
      t.references :user, null: false
      t.references :group, null: false
      t.integer :role, null: false, default: 1

      t.timestamps
    end

    add_index :groupable_members, [ :user_id, :group_id ], unique: true

    create_table :groupable_invites do |t|
      t.references :group, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :groupable_invites, :code, unique: true
    add_index :groupable_invites, :created_at
  end
end

class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	t.string :email
    	t.string :user_name
    end
    add_index :users, :user_name, :unique =>true
  end
end

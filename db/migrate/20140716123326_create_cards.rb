class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
    	t.string :user
    	t.string :boardable_id
    	t.string :name
    	t.string :list
    	t.datetime :enterDate
    	t.datetime :leaveDate
    end
  end
end

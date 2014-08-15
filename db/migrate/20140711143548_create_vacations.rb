class CreateVacations < ActiveRecord::Migration
  def change
    create_table :vacations do |t|
    	t.date :startDate
    	t.date :endDate
    	t.integer :user_id
    end
  end
end

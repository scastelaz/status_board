class CreateStatus < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
    	t.text :body
    	t.datetime :expiration
    	t.references :statusable, polymorphic: true
    end
  end
end

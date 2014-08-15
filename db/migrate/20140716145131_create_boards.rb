class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
    	t.string :name
    	t.integer :card_count
    	t.integer :bug_cards
    	t.float :in_dev
    	t.float :past_dev
    	t.string :url_id
    end
  end
end

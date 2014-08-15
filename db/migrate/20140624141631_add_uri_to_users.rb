class AddUriToUsers < ActiveRecord::Migration
  def change
  	change_table :users do |t|
  		t.string :replicon_uri
  	end
  end
end

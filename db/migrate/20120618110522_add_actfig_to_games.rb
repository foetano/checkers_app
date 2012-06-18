class AddActfigToGames < ActiveRecord::Migration
  def change
    add_column :games, :actfig, :boolean

  end
end

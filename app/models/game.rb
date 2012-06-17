class Game < ActiveRecord::Base
  attr_accessor :move
  attr_accessible :player1_id, :player2_id
  
  belongs_to :player1, :class_name => "User"
  belongs_to :player2, :class_name => "User"
    
end

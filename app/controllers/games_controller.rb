class GamesController < ApplicationController
  def new
    @title = "New game"
  end
  
  def index
    @title = "Chose game"
    @games = Game.paginate(:page => params[:page])
  end

  def show
    @game = Game.find(params[:id])
	redirect (root_path) if @game.nil?
	@player1 = User.find(@game.player1_id) unless @game.player1_id.nil?
	@player2 = User.find(@game.player2_id) unless @game.player2_id.nil?
	@cur = current_user.id
	@turn = @game.turn
	@hash = Digest::SHA2.hexdigest("#{@game.state}--#{@turn.to_s}")
	f1 = @game.gamefield.split
	@gf = [f1[0..7], f1[8..15], f1[16..23], f1[24..31], f1[32..39], f1[40..47], f1[48..55], f1[56..63]]
    @title = "Play"
  end
  
  def newwhite
    @game = Game.new
	@game.player1 = current_user
	save
  end
  
  def newblack
    @game = Game.new
	@game.player2 = current_user
	save
  end
  
  def update
	  @game = Game.find(params[:id])
	  @player1 = User.find(@game.player1_id) unless @game.player1_id.nil?
	  @player2 = User.find(@game.player2_id) unless @game.player2_id.nil?
	  @cur = current_user.id
	  f1 = @game.gamefield.split
	  @gf = [f1[0..7], f1[8..15], f1[16..23], f1[24..31], f1[32..39], f1[40..47], f1[48..55], f1[56..63]]
    if params[:game][:move] != nil
  	  @move = params[:game][:move]
	  #flash[:success] = 
	  make_move
	end
	@turn = @game.turn
	respond_to do |format|
	  format.html { redirect_to(game_path(@game)) }
	  format.js
	end
  end
  
  def joingame
    @game = Game.find(params[:id])
	if @game.player1 == current_user || @game.player2 == current_user || (! @game.player1.nil? && ! @game.player2.nil?)
	  redirect_to(root_path)
    else	  
	  if @game.player1.nil?
	    @game.player1 = current_user
	  else
	    @game.player2 = current_user
	  end
	  @game.save
	  redirect_to(game_path(params[:id]))
	end
  end

  private

    def save
	  @game.turn = 1
	  @game.gamefield = "n b n b n b n b b n b n b n b n n b n b n b n b 0 n 0 n 0 n 0 n n 0 n 0 n 0 n 0 w n w n w n w n n w n w n w n w w n w n w n w n"
      @game.save
      redirect_to(root_path)
    end
	
    def make_move
	  if (!@game.player1_id.nil? && !@game.player2_id.nil? && 
	                 ((@game.player1 == current_user && @game.turn == 1) || (@game.player2 == current_user && @game.turn == 2)))
	    #f1 = @game.gamefield.split
		#@gf = [f1[0..7], f1[8..15], f1[16..23], f1[24..31], f1[32..39], f1[40..47], f1[48..55], f1[56..63]].reverse
		@gf = @gf.reverse
		@to_kill = nil
		#@var = "Not"
	    if legal_move?
		  @gf[@i1][@j1] = @gf[@i0][@j0]
		  @gf[@i0][@j0] = '0'
		  if @to_kill != nil
		    @gf[@to_kill[0]][@to_kill[1]] = '0'
		  end
		  @game.gamefield = @gf.reverse.join(' ')
		  @game.turn = 3 - @game.turn
		  @game.save
		  @game.update_attributes(:gamefield => @gf.reverse.join(' '))
		end
		@gf = @gf.reverse
		#flash[:success] = @var
      end
    end
	
	def legal_move?
	  mv = @move.split(' ')
	  return false if mv[0].nil? || mv[0].nil? || mv[1].length < 2 || mv[0].length < 2
	  @j0 = mv [0][0].ord - 97
	  @i0 = mv [0][1].to_i - 1
	  @j1 = mv [1][0].ord - 97
	  @i1 = mv [1][1].to_i - 1
	  return false unless (0..8).include?(@i0) && (0..8).include?(@i1) && (0..8).include?(@j0) && (0..8).include?(@j1) && @gf[@i1][@j1] == '0'
	  if @game.turn == 1
	    if @gf[@i0][@j0] == 'w'
		  return true if (@i1 == @i0 + 1 && (@j1 == @j0 + 1 || @j1 == @j0 - 1))
		  if @i1 == @i0 + 2
		    if @j1 == @j0 + 2 && @gf[@i0 + 1][@j0 + 1][0] == 'b'
			  @to_kill = [@i0 + 1, @j0 + 1]
			  return true
			elsif @j1 == @j0 - 2 && @gf[@i0 + 1][@j0 - 1][0] == 'b'
			  @to_kill = [@i0 + 1, @j0 - 1]
			  return true
			end
		  end
		end
	  else
	    if @gf[@i0][@j0] == 'b'
		  return true if (@i1 == @i0 - 1 && (@j1 == @j0 + 1 || @j1 == @j0 - 1))
		  if @i1 == @i0 - 2
		    if @j1 == @j0 + 2 && @gf[@i0 - 1][@j0 + 1][0] == 'w'
			  @to_kill = [@i0 - 1, @j0 + 1]
			  return true
			elsif @j1 == @j0 - 2 && @gf[@i0 - 1][@j0 - 1][0] == 'w'
			  @to_kill = [@i0 - 1, @j0 - 1]
			  return true
			end
		  end
		end
	  end
	  return false
	end
end

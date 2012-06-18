class GamesController < ApplicationController
  before_filter :authenticate
  before_filter :deny_not_your_game, :only => [:show, :update, :destroy]
  before_filter :redir_to_your_game, :except => [:show, :update, :destroy]
  
  def new
    @title = "New game"
  end
  
  def start
    @title = "New game"
  end
  
  def index
    @title = "Chose game"
    @games = Game.paginate(:page => params[:page])
  end

  def show
    @game = Game.find(params[:id])
	redirect (root_path) if @game.nil?
	if current_user == @game.player1 || current_user == @game.player2
	  my = current_user == @game.player1 ? 'w' : 'b'
	  unless @game.gamefield.include?(my)
		flash[:error] = "You Lose"
		  @game.destroy
        redirect_to root_path
		return
      end
	end
	@player1 = User.find(@game.player1_id) unless @game.player1_id.nil?
	@player2 = User.find(@game.player2_id) unless @game.player2_id.nil?
	@cur = current_user.id unless current_user.nil?
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
	if @game.nil?
	  redirect_to(root_path)
    else
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
	  opp = current_user == @game.player2 ? 'w' : 'b'
	  unless @game.gamefield.include?(opp)
		flash[:success] = "You Win"
        #render 'start'
		  @game.destroy
		return
      end
	  #flash[:success] = @var
	  #redirect_to(game_path(@game))
	end
  end
  
  def joingame
    @game = Game.find(params[:id])
	if @game.nil? || @game.player1 == current_user || @game.player2 == current_user || (! @game.player1.nil? && ! @game.player2.nil?)
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
  
  def destroy
    g = Game.find(params[:id])
	g.destroy if (current_user == g.player1 || current_user == g.player2)
    redirect_to root_path
  end

  private

    def save
	  @game.turn = 1
	  @game.gamefield = "n b n b n b n b b n b n b n b n n b n b n b n b 0 n 0 n 0 n 0 n n 0 n 0 n 0 n 0 w n w n w n w n n w n w n w n w w n w n w n w n"
      @game.save
      redirect_to(@game)
    end
	
    def make_move
	  if (!@game.player1_id.nil? && !@game.player2_id.nil? && 
	                 ((@game.player1 == current_user && @game.turn == 1) || (@game.player2 == current_user && @game.turn == 2)))
	    #f1 = @game.gamefield.split
		#@gf = [f1[0..7], f1[8..15], f1[16..23], f1[24..31], f1[32..39], f1[40..47], f1[48..55], f1[56..63]].reverse
		if @move == 'end' && @game.actfig
			@game.gamefield = @game.gamefield.delete('a')
		    @game.turn = 3 - @game.turn
			@game.actfig = false
		    @game.save
			return
		end
		@gf = @gf.reverse
		@to_kill = nil
		@var = []
	    if legal_move?
		  fff = @gf[@i0][@j0]
		  if @to_kill != nil
		    fff << 'a' unless fff.last == 'a'
		    @gf[@to_kill[0]][@to_kill[1]] = '0'
		  end
		  if @i1 == 7 && ! fff.include?('d')
		    fff = fff.include?('a') ? fff[0].to_s + 'da' : fff[0].to_s + 'd'
		  end
		  @var.push(@j1)
		  @gf[@i1][@j1] = fff
		  @gf[@i0][@j0] = '0'
		  @gf = @gf.reverse if @game.turn == 1
		  @game.gamefield = @gf.join(' ')
		  @game.turn = 3 - @game.turn if @to_kill.nil?
	      @game.actfig = @to_kill != nil
		  @game.gamefield = @game.gamefield.delete('a') if @to_kill.nil?
		  @game.save
		  
		end
		@gf = @gf.reverse
		#flash[:success] = @var
      end
    end
	
	def legal_move?
	  mv = @move.split(' ')
	  return false if mv[0].nil? || mv[1].nil? || mv[1].length < 2 || mv[0].length < 2
	  @j0 = mv [0][0].ord - 97
	  @i0 = mv [0][1].to_i - 1
	  @j1 = mv [1][0].ord - 97
	  @i1 = mv [1][1].to_i - 1
	  return false unless (0..7).include?(@i0) && (0..7).include?(@i1) && (0..7).include?(@j0) && (0..7).include?(@j1) && @gf[@i1][@j1] == '0'
	  return false if @game.actfig && ! @gf[@i0][@j0].include?('a')
	  opp = @game.turn == 1 ? 'b' : 'w'
	  my = opp == 'w'  ? 'b' : 'w'
	  return false unless @gf[@i0][@j0].include?(my)
	  if @game.turn == 2
	    @var = @gf = @gf.reverse
	    @i0 = 7 - @i0
	    @i1 = 7 - @i1
	  end
	  if ! @gf[@i0][@j0].include?('d')
	    return true if (@i1 == @i0 + 1 && (@j1 == @j0 + 1 || @j1 == @j0 - 1))
	    if @i1 == @i0 + 2
		  if @j1 == @j0 + 2 && @gf[@i0 + 1][@j0 + 1][0] == opp
		    @to_kill = [@i0 + 1, @j0 + 1]
			return true
		  elsif @j1 == @j0 - 2 && @gf[@i0 + 1][@j0 - 1][0] == opp
		    @to_kill = [@i0 + 1, @j0 - 1]
			return true
		  end
		elsif @i1 == @i0 - 2
		  if @j1 == @j0 + 2 && @gf[@i0 - 1][@j0 + 1][0] == opp
		    @to_kill = [@i0 - 1, @j0 + 1]
			return true
		  elsif @j1 == @j0 - 2 && @gf[@i0 - 1][@j0 - 1][0] == opp
		    @to_kill = [@i0 - 1, @j0 - 1]
			return true
		  end
	    end
	  else
		return false unless (@j1 - @j0).abs == (@i1 - @i0).abs
		inc_i = @i1 > @i0 ? 1 : -1
		inc_j = @j1 > @j0 ? 1 : -1
		i = @i0
		j = @j0
		cnt = 0
		k1=(@i1 - @i0).abs-2
		for k in 0..k1 do
		  i = i + inc_i
		  j = j + inc_j
		  if @gf[i][j].include?(opp)
	        return false if ((cnt=cnt+1) > 1)
		    @to_kill = [i, j]
		  end
		  @var.push(cnt)
		  @var.push([i, j])
	      if (@gf[i][j].include?(my))
		    return false 
		  end
		end
		return true
	  end
	  return false
	end
	
    def authenticate
      deny_access unless signed_in?
    end
	
	def deny_not_your_game
      g = Game.find(params[:id])
	  redir_to_your_game if g.player1 != current_user && g.player2 != current_user
    end
	
    def redir_to_your_game
      g = Game.find_by_player1_id(current_user.id)
	  g ||= Game.find_by_player2_id(current_user.id)
	  redirect_to g unless g.nil?
    end
end

require 'gosu'

class TimeBomb
    attr_accessor :x, :y, :explotion_time, :isActivated, :bomb_images, :explotion_images, :time_left, :activation_time, :time_interval, :cur_image, :exploded, :explosion_sound
    def initialize x, y
        @x = x
        @y = y
        @bomb_images = Gosu::Image.load_tiles("images/bomb.png",25,25)
        @explotion_images = Gosu::Image.load_tiles("images/explosion.png",64,64)   
        @explotion_time = rand(3000..5000) #explotion_time # in milliseconds: The time to explode bomb
        @isActivated = 0
        @time_interval = @explotion_time / @explotion_images.length
        @cur_image = @bomb_images[0]
        @activation_time = 0
        @exploded = 0
        @explosion_sound = Gosu::Song.new("sounds/explosion_sound.mp3") #sound for bomb blast
        # puts "Total bombs: " + @bomb_images.length.to_s
    end
end

def explode_bomb_if_player_on_bomb player
    bombs = player.game_map.time_bombs

    # if(player.gameover==0)      # if the game is not over then check for the explotion condition
        bombs.each do |bomb|
            if((bomb.x - player.x).abs < 60 && (bomb.y-player.y).abs < 2 && bomb.explotion_time <=0 && bomb.isActivated==1)   
                bomb.exploded = 1
                bomb.explotion_images[1].draw(bomb.x-16,bomb.y-32,2)
                if(player.gameover==0)
                    bomb.explosion_sound.play(false)
                end
                player.gameover = 1
            end
        end
    # end 
end

def activate_bomb_if_player_on_bomb player
    bombs = player.game_map.time_bombs
    bombs.each do |bomb|
        if((bomb.y-player.y).abs < 2 && (bomb.x - player.x).abs <= 60)
            activate_bomb(bomb)
        end
    end
end

def activate_bomb bomb
    if(bomb.isActivated!=1)
        bomb.isActivated = 1
        bomb.activation_time = Gosu.milliseconds
    end   
end

# function which takes the array of bombs and draw them
def draw_bombs bombs
    bombs.each do |bomb|
        draw_bomb(bomb)
    end
end

# function which takes single object of bomb and draw in on the screen
def draw_bomb bomb
    bomb.cur_image.draw(bomb.x,bomb.y,2)
end

# function which updates all the bombs in the array
def update_bombs bombs , player
    bombs.each do |bomb|
        update_bomb(bomb,player)
    end
    # remove_bombs_if_difused(bombs)
end

# def remove_bombs_if_difused bombs
#     bombs.each do |bomb|
#         if(bomb.difused)
#             bombs.delete(bomb)
#         end
#     end
# end

# function to update the values of the bomb
def update_bomb bomb, player
    if bomb.isActivated == 1
        bomb.explotion_time -= 16.63
        cur_time = Gosu.milliseconds.to_i
        i = (cur_time - bomb.activation_time ) / bomb.time_interval
        if(i < bomb.bomb_images.length)
            bomb.cur_image = bomb.bomb_images[i]
        end
    end
end



class Cutter 
    attr_accessor :dir, :x, :y, :image, :speed, :cutter_sound
    def initialize x, y
        @x = x
        @y = y
        if(x==0)
            @dir = "ltr"
        else @dir = "rlt" end
        @speed = rand(1..7)        # randomly allocating the speed of the cutter
        @image = Gosu::Image.new("images/cutter.png")   # importing the image of the cutter
        @cutter_sound = Gosu::Song.new("sounds/cutter_sound.mp3")
    end
end

# function which takes the array of cutters and draws them on the screen
def draw_cutters cutters
    cutters.each do |cutter|
        draw_cutter(cutter)
    end 
end

# function which draws the cutter on the game window
def draw_cutter cutter
    cutter.image.draw(cutter.x,cutter.y,1)
end

# function which takes array of cutters and updates them
def update_cutters cutters
    cutters.each do |cutter|
        update_cutter(cutter)
    end
end

# function which updates the position of the cutter
def update_cutter cutter
    if(cutter.dir == "ltr")
        if(cutter.x<WIDTH)
            cutter.x+=cutter.speed
        else cutter.dir = "rtl"
        end
    else
        if(cutter.x>0)
            cutter.x-=cutter.speed
        else cutter.dir = "ltr"
        end
    end
end

def check_for_cutter_hit player
    cutters = player.game_map.cutters
    
    cutters.each do |cutter|
        if((player.x-cutter.x).abs<10)
            if(player.y>cutter.y)
                if((player.y - cutter.y)<50) then player.gameover = 1; cutter.cutter_sound.play(false) end
            else
                if((cutter.y - player.y)<=0) then player.gameover = 1; cutter.cutter_sound.play(false) end
            end
        end
    end
end


class Fire 
    attr_accessor :x, :y, :fire_img, :yellow_box_img, :speed
    def initialize difficulty
        @fire_img = Array.new()
        @fire_img << Gosu::Image.new("images/fire1.png")
        @fire_img << Gosu::Image.new("images/fire2.png") 
        @yellow_box_img = Gosu::Image.new("images/yellowbox.png")
        @x = 0
        @y = 2050
        @speed = 0.5 + (difficulty/2).to_f
    end
end

def update_fire fire
    fire.y -= fire.speed
end

def draw_fire fire
    xPos = fire.x
    yPos = fire.y
    10.times do |i|
        fire.fire_img[i%2].draw(i*20,yPos,6)      # 4 denotes zorder  
    end
    x = ((2000 - yPos)/20).to_i
    (x).times do |i|
        fire.yellow_box_img.draw(0,(yPos+60)+(i*20),6)
    end
end

def check_for_fire_hit player
    fire = player.game_map.fire
    if(fire.y-player.y<-10)
        player.gameover = 1
    end
end


class GameMap 
    attr_accessor :width, :height, :gems, :tiles, :time_bombs, :cutters, :wooden_plank, :background, :fire
    def initialize difficulty
        @height = 100 * 20
        @tiles = generateMap(difficulty)
        @height = @tiles.length        # the vertical height of the game map
        @width = @tiles[0].length      # the howriontal width of the game map
        @time_bombs = load_time_bombs(@tiles)
        @cutters = load_cutters(@tiles)
        @fire = Fire.new(difficulty)
        @wooden_plank = Gosu::Image.new("images/plank.png")
        # explosion sound effect
    end
end

# function to draw the game map Parameter: Object of GameMap
def draw_map game_map
    tiles = game_map.tiles                     # 2d array of the tiles set!
    wooden_plank_image = game_map.wooden_plank       # image of the wooden plank 
    i = 0
    j = 0
    unit_width = 20
    unit_height = 20

    # drawing the background image of the game map
    #game_map.background.draw(0,0,0)         # 0: for x position, 0: for y position, 0: for ZOrder

    height = tiles.length
    width = tiles[0].length

    while i < height
        j = 0
        while j < width
            if(tiles[i][j]==1 || tiles[i][j]==3)
                x = j * unit_width
                y = i * unit_height
                draw_plank(x, y, wooden_plank_image)
                j+=4    # increment the value of the j by 4 to skip the next 4 blocks
            end
            j+=1
        end
        i+=1
    end

end

#function which takes x, y coordinate and draws the wooden plank at that position
def draw_plank x, y, image
    image.draw(x,y,1)           # 1 denotes the ZOrder 
end

# function to generate the map
def generateMap difficulty
    width = 12
    height = 100
    map = Array.new(height)
    i = 0
    previousCutterYPos = 0
    noCuttterForFirst10Block = 0
    while i < height-1
        map[i] = Array.new(width)
        if(i%3==0)  #if the coloumn consist plank then draws the wooden plank on the random position and fills the left space with 0
            posX = rand(1..6)   #6 randomply decides the position where to draw the wooden plank
            plankWithBomb = rand(30)
            width.times do |x| 
                if(x < posX || (posX+4) < x)  # fills the coordinate with space i.e 0
                    map[i][x] = 0
                else                          # fills the coordinate with wooden plank i.e 1    
                    if(plankWithBomb % (5-difficulty)==0)      
                        map[i][x] = 3
                    else
                        map[i][x] = 1 
                    end
                end
            end
        else  #else then just draw the space i.e 0 or cutters 
            posX = -1
            if(previousCutterYPos!=(i-1) && rand(15) % (10-difficulty)==0 && i < 90)    # i > 10 denotes that there are no cutter for first 10 blocks or jumps
                posX = [0,11].sample 
                previousCutterYPos = i
            end
            
            12.times do |x|
                if(posX==x)
                    map[i][posX] = 2
                else
                    map[i][x] = 0
                end
            end
        end
        i+=1
    end

    # map[height-1] = Array.new()
    map[height-1] = [1,1,1,1,1,1,1,1,1,1,1,1]   # just making the last block as platform for player to move around

    map  # return the map to the calling function
end

# just for debuging
def display map  
    i = 0 
    width = 12
    height = 100
    while i < height
        j = 0
        while j < width
            print(map[i][j])
            j+=1
        end
        i+=1
        puts ""
    end

end


# map = generateMap()
# display(map)

def load_cutters tiles
    i = 0
    height = tiles.length
    width = tiles[i].length
    cutters = Array.new()

    while i < height
        j=0
        while j < width
            if(tiles[i][j]==2)
                tiles[i][j]=0
                cutters << Cutter.new(j*20,i*20)
            end
            j+=1
        end
        i+=1
    end

    puts "total cutters : " + cutters.length.to_s
    cutters
end

def load_time_bombs tiles
    i = 0
    height = tiles.length
    width = tiles[i].length
    bombs = Array.new()

    while i < height
        j = 0
        while j < width
            if(tiles[i][j]==3)
                # puts "bomb created"
                bombs << TimeBomb.new((j+2)*20,i*20)
                j+=4
            end
            j+=1
        end
        i+=1    
    end
    puts "total bombs: " + bombs.length.to_s
    bombs
end

# GameMap.new("easy") #debug
# require 'gosu'
# require_relative 'GameMap'

class Player
    attr_accessor :x, :y, :dir, :vy, :self, :standing, :walk1, :walk2, :jump, :cur_image, :game_map, :gameover, :gamewin
    def initialize difficulty
        @standing, @walk1, @walk2, @jump = Gosu::Image.load_tiles("images/cptn_ruby.png",30,30)
        @cur_image = @standing
        @game_map = GameMap.new(difficulty)
        initialize_player_position()
        # display(@game_map)    # for debuging
        puts "X: " + @x.to_s + " Y: " + @y.to_s
        @vy = 10
        @gameover = 0
        @gamewin = 0
    end
end

def initialize_player_position
    
    height = @game_map.tiles.length - 1     # this is the y spawning position of the player
    # @y = (height-1) * 20
    @y = 1975
    i = 0 
    j = height
    width = @game_map.tiles[0].length
    while i < width
        if(@game_map.tiles[j][i]==1||@game_map.tiles[j][i]==3)
            @x = (i+1) * 20                 # this is the x spawning position of the player
            break;
        end
        i+=1
    end

end

# Solid at a given pixel position?
def solid?(game_map, x, y)
    #  puts "X: " + x.to_s + " Y: " + y.to_s   # for debuging
    if(x < 0 || x > 240)       # dosen't allow player to go out of side walls
        return true
    end

    if(y<0 ||game_map.tiles[y / 20][x / 20]==0)
        return false
    else 
        return true
    end

end

def try_to_jump(player)
    if solid?(player.game_map, player.x, player.y + 1)
      player.vy = -12
    end
end

def would_fit(player, offs_x, offs_y)
    ans = !solid?(player.game_map, player.x + offs_x, player.y + offs_y) and 
    !solid?(player.game_map, player.x + offs_x, player.y + offs_y - 15) and 
    !solid?(player.game_map, player.x + offs_x, player.y + offs_y - 30) # puts ans   
end  

def update_player player , move_x
    # determining the current state of the player and then setting the current image accordingly
    if move_x == 0
        player.cur_image = player.standing
    else
        player.cur_image = (Gosu.milliseconds / 175 % 2 == 0) ? player.walk1 : player.walk2
    end
    # if the player is jumping then set the current image to jumping image
    if (player.vy < 0)
        player.cur_image = player.jump
    end
    # if the player is moving right
    if move_x > 0
        player.dir = :right
        move_x.times { if(would_fit(player, 1, 0)) then player.x+=1 end}
    end
    # if the player is moving left
    if move_x < 0
        player.dir = :left
        (-move_x).times {if(would_fit(player,-1,0)) then player.x-=1 end}
    end

    player.vy += 1
    # Vertical movement
    if player.vy > 0
        player.vy.times { if would_fit(player, 0, 1) then player.y += 1 else player.vy = 0 end }
    end
    if player.vy < 0
        # (-player.vy).times { if would_fit(player, 0, -1) then player.y -= 1 else player.vy = 0 end }
        (-player.vy).times { player.y -= 1 }
    end
end

def draw_player(player)
    # Flip vertically when facing to the left.
    if player.dir == :left
      offs_x = -20
      factor = 1.0
    else
      offs_x = 20
      factor = -1.0
    end
    player.cur_image.draw(player.x + offs_x, player.y - 28, 0, factor, 1.0)
end

def check_player_win player
    if(player.y < 60)
        player.gamewin = 1
        game_win_sound = Gosu::Song.new("sounds/victory.mp3")
        game_win_sound.play(false)
    end
end

#######################################
#######################################
###### GAME OVER ANIMATION ############
#######################################
#######################################

WIDTH = 240
HEIGHT = 600

class Game < Gosu::Window
     
    def initialize difficulty
        super WIDTH,HEIGHT
		self.caption = "Save The Captian"
        @player = Player.new(difficulty)
        @camera_x = 0
        @camera_y = @player.y - HEIGHT/2
        @background = Gosu::Image.new("images/background.png")
        @game_over_image = Gosu::Image.new("images/gameover.png")
        @game_win_image = Gosu::Image.new("images/gamewin.png")
        #@camera_y = [[@player.y - HEIGHT / 2, 0].max, @game_map.height * 20 - HEIGHT].min
    end

    def draw
        Gosu.translate(-@camera_x, -@camera_y) do
            @background.draw(@camera_x,@camera_y,0)
            draw_game()
        end
    end

    def update
        if @player.gameover == 0 && @player.gamewin == 0
            move_x = 0
            move_x = -5 if Gosu.button_down? Gosu::KB_LEFT
            move_x = 5 if Gosu.button_down? Gosu::KB_RIGHT
            @camera_y = [[@player.y - HEIGHT/2, 0].max,(@player.game_map.height+2)* 20 - HEIGHT].min 
            update_player(@player, move_x)
            update_cutters(@player.game_map.cutters)
            update_fire(@player.game_map.fire)
            activate_bomb_if_player_on_bomb(@player)
            update_bombs(@player.game_map.time_bombs, @player)
            check_for_cutter_hit(@player)
            check_for_fire_hit(@player)
            check_player_win(@player)
        end
    end    
    
    def button_down(id)
        case id
        when Gosu::KB_UP
          try_to_jump(@player)
        when Gosu::KB_ESCAPE
          close
        else
          super
        end
    end

    def draw_game

        draw_player(@player)
        draw_cutters(@player.game_map.cutters)
        draw_bombs(@player.game_map.time_bombs)
        draw_fire(@player.game_map.fire)
        explode_bomb_if_player_on_bomb(@player)
        draw_map(@player.game_map)
    
        if @player.gameover == 1 || @player.gamewin == 1
            game_win_over_animation()
        end

    end

    def game_win_over_animation
        if(@player.gameover==1)
            height = @game_over_image.height
            @game_over_image.draw(0,@camera_y + 50,3)
            self.close if Gosu.button_down? Gosu::MsLeft
        else
            height = @game_win_image.height
            @game_win_image.draw(0,@camera_y + 50,3)
            self.close if Gosu.button_down? Gosu::MsLeft
        end
    end

    # def game_win_animatin
    #     height = @game_win_animatin.height
    #     @game_win_animatin.draw(0,@camera_y + 50,3)
    #     self.close if Gosu.button_down? Gosu::MsLeft
    # end

    def needs_cursor?; true end
end

def add_score 
	#this function is used to display score 
	puts "Total Score: " + this.score
end


Game.new(3).show

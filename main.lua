--Constants that may be changed for small aesthetic/gameplay changes.
-- --Virtual and real window sizes (resizeable).
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
V_WIDTH = 432
V_HEIGHT = 243
-- --Paddle properties: Movement speed, dimensions, and boundaries for movement.
PADDLE_SPEED = 100
paddle_thickness = 8
paddle_width = 28
paddle_back = 60
paddle_front = V_WIDTH/2 -20
-- --Ball properties: normal speed, maximum velocities in both x&y directions, radius.
BALL_SPEED = 50
BALL_max_dx = 350
BALL_max_dy = 100
ball_radius = 4
-- --Number of points required to win the game.
PointReq = 3
-- --Goal width
Goal_w = 80

--Load push, class: both external files with sources in their respective codes
push = require 'push'
Class = require 'class'
--In-game objects, and tick, which limits the FPS to 60 to limit CPU consumption.
require 'Paddle'
require 'Ball'
require 'Goal'
local tick = require 'tick'

--LOAD
function love.load()
    --Framerate set at 60. This may be increased to improve image smoothness.
    tick.framerate = 60
    --Window title
    love.window.setTitle('Laser Hockey')
    --Audio files used
    sounds = {
    ['paddle_hit'] = love.audio.newSource('Pickup_Coin31.wav', 'static'),
    ['game_start'] = love.audio.newSource('game_start.mp3', 'static'),
    ['game_win'] = love.audio.newSource('game_win.mp3', 'static'),
    ['edge_hit'] = love.audio.newSource('Powerup14.wav', 'static'),
    ['goal'] = love.audio.newSource('Explosion19.wav', 'static')
    }
    sounds['edge_hit']:setVolume(0.25)
   
    --Custom fonts for game.
    MedFont = love.graphics.newFont('basicf.TTF', 18)
    LargeFont = love.graphics.newFont('Mario.TTF', 24)
    --Preloads the scores per game, as well as the current winning player, in order to manage wind-condition.
    P1score = 0
    P2score = 0
    WinningPlayer = 0

    --Specify objects' inital position and dimensions: for paddle and goal this is (x,y,size.x,size.y), and only (x,y,radius) for ball.
    -- --Paddles: paddle_back/front refers to the 'back/front of the court' area where it can move, paddle-thickness must be included to ensure symmetry.
    paddle1 = Paddle(paddle_back, (V_HEIGHT-paddle_width)/2,
     paddle_thickness, paddle_width,3,3)
    paddle2 = Paddle(V_WIDTH -paddle_back - paddle_thickness, (V_HEIGHT-paddle_width)/2,
      paddle_thickness, paddle_width,3,3) 
    -- --Goals: goal thickness (currently set at 5, is not set as a variable as it is of little importance)
    goal_1 = Goal(40, (V_HEIGHT-Goal_w)/2, 5, Goal_w)
    goal_2 = Goal(V_WIDTH-40-5, (V_HEIGHT-Goal_w)/2, 5, Goal_w)
    -- --Ball
    ball = Ball(V_WIDTH /2, V_HEIGHT /2, ball_radius)

    --Seed RNG for initial serve per game: based on os-time.
    math.randomseed(os.time())
    servingPlayer = math.random(2) == 1 and 1 or 2
    --Service direction, based on the value determined by math.random, will either serve to player 1 or two
    if servingPlayer == 1 then
        ball.dx = BALL_SPEED
    else
        ball.dx = -BALL_SPEED
    end
    
    --Game state: there are 4 game states: 
    -- --wait: before a new game is played, or once a game has been completed
    -- --start: a new game has started
    -- --serve: a point has been scored during a game
    -- --winner: the game has been won
    --Transitions between these game states are done so by pressing the 'enter' or 'return button' on the keyboard
    gameState = 'wait'
    --The inital sound that is played before each game begins
    sounds['game_start']:play()
    --Setting resolutions
    push:setupScreen(V_WIDTH,V_HEIGHT,WINDOW_WIDTH,WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable= true
    })
    love.graphics.setDefaultFilter("nearest", "nearest")

end

--Allows for the window to be resized but maintain in-game dimensions
function love.resize(w,h)
    push:resize(w,h)
end

--UPDATE 
function love.update(dt)
   
    --BALL 
    -- --Collisions with Goals
    -- -- --Goal 1
    if ball:collides(goal_1) then
        P2score = P2score +1
        servingPlayer = 1
        --Becaue a point has been scored, all objects that can move are reset to their original positions.
        ball:reset()
        paddle_reset()
        --Because Player 2 has scored, the ball ought to return to him, and therefore ball.dx is positive.
        ball.dx = 100
        gameState = 'serve'
        --Sounds may play over one another, or not play at all if called in quick succession, therefore audio.stop ensures the file will play when required.
        love.audio.stop()
        sounds['goal']:play()
        
        --Checks for victory condtion. 
        if P2score >= PointReq then
            gameState = 'winner'
            WinningPlayer = 2
            love.audio.stop()
            sounds['game_win']:play()
        else 
            gameState = 'serve'
        end
    end
    -- -- --The exact same logic applies to Goal 2.
    if ball:collides(goal_2) then
        P1score = P1score +1
        servingPlayer = 2
        ball:reset()
        paddle_reset()
        ball.dx = -100
        gameState = 'serve'
        love.audio.stop()
        sounds['goal']:play()
        
        if P1score >= PointReq then
            gameState = 'winner'
            WinningPlayer = 1
            love.audio.stop()
            sounds['game_win']:play()
        else 
            gameState = 'serve'
        end
    end
    -- --Collisions with Paddles: both dx and dy of the paddle will affect the ball-movement in intuitive ways.
    -- -- --Paddle 1
    if ball:collides(paddle1) then
        ball.dx = -ball.dx + paddle1.dx
        --These are limited to preset values, as collision (and enjoyability of the game) gets worse at too high a velocity.
        --Ball horizontal maximum velocity
        if ball.dx < -BALL_max_dx then
            ball.dx = -BALL_max_dx
        elseif ball.dx > BALL_max_dx then
            ball.dx = BALL_max_dx
        end
        --To avoid multiple collisions from the same paddle, the ball will 'jump' a little ahead, avoiding the paddle.
        ball.x  = ball.x +ball.dx/20
        --Ball vertical maximum velocity 
        ball.dy = ball.dy + 0.25*paddle1.dy
        if ball.dy < -BALL_max_dy then
            ball.dy = -BALL_max_dy
        elseif ball.dy > BALL_max_dy then
            ball.dy = BALL_max_dy
        end
        --Plays paddle collision sound
        love.audio.stop()
        sounds['paddle_hit']:play()
    end
    -- -- --Collisions with Paddle 2 are the same.
    if ball:collides(paddle2) then
        ball.dx = -ball.dx + paddle2.dx
        if ball.dx < -BALL_max_dx then
            ball.dx = -BALL_max_dx
        elseif ball.dx > BALL_max_dx then
            ball.dx = BALL_max_dx
        end

        ball.x = ball.x + ball.dx/20

        ball.dy = ball.dy + 0.25*paddle2.dy
        if ball.dy < -BALL_max_dy then
            ball.dy = -BALL_max_dy
        elseif ball.dy > BALL_max_dy then
            ball.dy = BALL_max_dy
        end

        love.audio.stop()
        sounds['paddle_hit']:play()
    end

    -- --Collisions with Walls
    -- -- --Top of screen
    if ball.y <= 0 then
        ball.dy = -ball.dy
        ball.y = 0
        love.audio.stop()
        sounds['edge_hit']:play()
    end
    -- -- --Bottom of screen
    if ball.y >= V_HEIGHT -5 then
        ball.dy = -ball.dy
        ball.y = V_HEIGHT -5
        love.audio.stop()
        sounds['edge_hit']:play()
    end
    -- -- --Right of screen
    if ball.x >= V_WIDTH then
        ball.dx = -ball.dx
        ball.x = V_WIDTH -5
        love.audio.stop()
        sounds['edge_hit']:play()
    end
    -- -- --Left of screen
    if ball.x <= 0 then
        ball.dx = -ball.dx
        ball.x = 0
        love.audio.stop()
        sounds['edge_hit']:play()
    end

    -- Player motion 
    -- --Player 1: uses 'WASD' for movement
    if love.keyboard.isDown('w') then
        paddle1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        paddle1.dy = PADDLE_SPEED
    else
        paddle1.dy = 0
    end
    if love.keyboard.isDown('a') then
        paddle1.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('d') then
        paddle1.dx = PADDLE_SPEED
    else
        paddle1.dx = 0
    end
    -- --Player 2: uses arrow keys for movement 
    if love.keyboard.isDown('up') then
        paddle2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        paddle2.dy = PADDLE_SPEED
    else
        paddle2.dy = 0 
    end
    if love.keyboard.isDown('left') then
        paddle2.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('right') then
        paddle2.dx = PADDLE_SPEED
    else
        paddle2.dx = 0
    end

    --Paddle boundaries: limited to aforementions 'front and back' areas, with entire vertical freedom of movement
    -- --Paddle1
    if paddle1.x <= paddle_back -1 then
        paddle1.dx = 0
        paddle1.x = paddle_back +1
    elseif paddle1.x >= paddle_front +1 -paddle_thickness then
        paddle1.dx = 0
        paddle1.x = paddle_front -1 - paddle_thickness
    end
    -- --Paddle2
    if paddle2.x <= V_WIDTH - paddle_front -1 then
        paddle2.dx = 0
        paddle2.x = V_WIDTH - paddle_front +1
    elseif paddle2.x >= V_WIDTH - paddle_back -paddle_thickness +1 then
        paddle2.dx = 0
        paddle2.x = V_WIDTH - paddle_back -paddle_thickness -1
    end
    --Update Paddles
    paddle1:update(dt)
    paddle2:update(dt)
    --Update ball during gameplay
    if gameState == 'start' then
        ball:update(dt)
    end

end

--Keypressed: Deal with gamestate transitions, as well as implementing game escape option.  
function love.keypressed(key)
    --Exit application if 'Esc' is pressed.
    if key == 'escape' then
        love.event.quit()
    --Transition between game states by pressing 'Enter'/'Return' key.
    elseif key == 'enter' or key == 'return' then
        if gameState == 'wait' then
            gameState = 'serve'
        --Resets game after a winner is decided
        elseif gameState == 'winner' then
            gameState = 'wait'
            P1score = 0
            P2score = 0
            love.audio.stop()
            sounds['game_start']:play()
        --Service must be intiated, is not automatic.
        elseif gameState == 'serve' then
            gameState = 'start'      
        end
    end
end

--Draw 
function love.draw()
    --Begin rendering
    push:apply('start')
    --Apply background colour: Black
    love.graphics.clear( 0,0,0, 255/255)

    --Render Objects
    -- --Ball
    ball:render()
    -- --Paddles
    paddle1:render()
    paddle2:render()
    -- --Goals
    goal_1:render()
    goal_2:render()

    --Render Text
    -- --Main Titles: depends on game states 
    love.graphics.setFont(LargeFont)
    love.graphics.setColor(1,1,1)
    if gameState == 'wait' then
        love.graphics.printf("LASER  HOCKEY", 0, 20, V_WIDTH, 'center')       
    elseif gameState == 'start' then
        love.graphics.printf("GO !", 0, 20, V_WIDTH, 'center')
    -- -- --Aforementioned 'servingPlayer and WinningPlayer are actively displayed in-game'
    elseif gameState == 'serve' then
        love.graphics.printf("p" .. tostring(servingPlayer) .. '    to  serve', 0, 20, V_WIDTH, 'center')
    elseif gameState == 'winner' then
        love.graphics.printf('player    ' .. tostring(WinningPlayer) .. '   wins!', 0, 20, V_WIDTH, 'center')
    end

    -- --Display Scores
    love.graphics.setFont(MedFont)
    love.graphics.setColor(1,1,1)
    -- -- --'Pxscore' is actively displayed
    love.graphics.print('P1:' .. tostring(P1score), 40, 4)
    love.graphics.print('P2:' .. tostring(P2score), V_WIDTH-80, 4)

    --Ends rendering
    push:apply('end')
end

--Paddle reset function: unlike 'ball:reset()', this is called in main as it uses objects created in main. 
function paddle_reset()
    paddle1.x = paddle_back
    paddle2.x = V_WIDTH -paddle_back - paddle_thickness
    paddle1.y = (V_HEIGHT-paddle_width)/2
    paddle2.y = (V_HEIGHT-paddle_width)/2
end

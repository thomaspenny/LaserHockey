Paddle = Class{}
--Initiates properties
function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.dx = 0
    self.dy = 0
end
--Updates paddles in position, containing them within the game window.
function Paddle:update(dt)
    -- --Upper vertical boundary 
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    -- --Lower vertical boundary
    elseif self.dy > 0 then
        self.y = math.min(V_HEIGHT -self.height, self.y + self.dy * dt)
    end
    -- --Leftmost horizontal boundary
    if self.dx < 0 then
        self.x = math.max(0, self.x + self.dx * dt)
    -- --Rightmost horizontal boundary    
    elseif self.dx > 0 then
        self.x = math.min(V_WIDTH -self.width, self.x + self.dx * dt)
    end
end
-- Paddle rendering
function Paddle:render()
    -- --Blue colour
    love.graphics.setColor(0, 0, 1)
    -- --Set paddle colouring, position, dimensions, and curved edges. 
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height, paddle_thickness/2, paddle_thickness/2)
end


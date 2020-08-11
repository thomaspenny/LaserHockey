Ball = Class{}

--Initiates properties
function Ball:init(x, y, radius)
    self.x = x
    self.y = y
    self.radius = radius
    
    self.dy = 0.5*math.random(-BALL_SPEED, BALL_SPEED)
end

--Collision detection with 'rectangle' (paddle or goal): if either if statement is true, then 'false' is returned (no collision).
function Ball:collides(box)
    -- --Detects if the ball is within the same x position as 'box', false if not.
    if self.x > box.x + box.width or self.x + 2*self.radius < box.x then
        return false
    end
    -- --Detects if the ball is within the same y position as 'box', false if not.
    if self.y > box.y + box.height or self.y + 2*self.radius < box.y then
        return false
    end

    return true
end
--Reset ball to centre, initiate .dy velocity
function Ball:reset()
    self.x = V_WIDTH /2
    self.y = V_HEIGHT /2

    self.dy = 0.5*math.random(-BALL_SPEED, BALL_SPEED)
end
--Update ball position and velocity
function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end
--Render ball
function Ball:render()
    -- --Yellow ball colour
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle('fill', self.x, self.y, ball_radius)
end
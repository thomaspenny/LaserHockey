Goal = Class{}

function Goal:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Goal:render()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end

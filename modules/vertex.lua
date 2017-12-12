-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen

local vector=require("modules.vector")

local vertex={}
vertex.__index=vertex

function vertex.new(x,y,color,pin)
  local self={
    position=vector.new(x,y),
    color=color or 1,
    pin=pin or false,
  }
  setmetatable(self,vertex)
  return self
end

function vertex:clone()
  return vertex.new(self.position.x,self.position.y,self.color,self.pin)
end

function vertex:togglePin()
  self.pin=not self.pin
  return self
end

-- Mirror this vector
-- center is vector to mirror across on x axis
function vertex:mirror(center)
  local deltaVector=self.position-center
  local mirroredPosition=vector.new(center.x-deltaVector.x,self.position.y)
  mirroredPosition=mirroredPosition:round()
  self.position=mirroredPosition
  return self
end

-- Return a new mirrored vector
-- center is vector to mirror across on x axis
function vertex:mirrored(center)
  local deltaVector=self.position-center
  local mirroredPosition=vector.new(center.x-deltaVector.x,self.position.y)
  mirroredPosition=mirroredPosition:round()
  local newVertex=self:clone()
  newVertex.position=mirroredPosition
  return newVertex
end

-- Rotate this vertex
function vertex:rotate(center,angle)
  local deltaVector=self.position-center
  deltaVector=deltaVector:rotate(angle)
  local rotatedPosition=center+deltaVector
  rotatedPosition=rotatedPosition:round()
  self.position=rotatedPosition
  return self
end

-- Return a new rotated vertex
function vertex:rotated(center,angle)
  local deltaVector=self.position-center
  deltaVector=deltaVector:rotate(angle)
  local rotatedPosition=center+deltaVector
  rotatedPosition=rotatedPosition:round()
  local newVertex=self:clone()
  newVertex.position=rotatedPosition
  return newVertex
end

-- Translate this vertex
function vertex:translate(deltaVector)
  local translatedPosition=self.position+deltaVector
  translatedPosition=translatedPosition:round()
  self.position=translatedPosition
  return self
end

-- Return a new translated vertex
function vertex:translated(deltaVector)
  local translatedPosition=self.position+deltaVector
  translatedPosition=translatedPosition:round()
  local newVertex=self:clone()
  newVertex.position=translatedPosition
  return newVertex
end

-- subdivides using Chaikin's algorithm
-- pin keeps the point in place when subdividing
function vertex.subdivided(a,b)
  a=a:clone()
  b=b:clone()
  local q=a.position*0.75+b.position*0.25
  local r=a.position*0.25+b.position*0.75
  q=q:round()
  r=r:round()
  if not a.pin then a.position=q end
  if not b.pin then b.position=r end
  return a,b
end

--[[function vertex.split(a,b)
  local split=a.position*0.5+b.position*0.5
  split=split:round()
  local newVertex=vertex.new(split.position.x,split.position.y)
  return newVertex
end]]

return vertex
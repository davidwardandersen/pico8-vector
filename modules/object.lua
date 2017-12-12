-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen

local vector=require("modules.vector")
local vertex=require("modules.vertex")
local polygon=require("modules.polygon")

local object={}
object.__index=object

function object.new(anchor)
  local self={
    polygons={},
    anchor=anchor,
  }
  setmetatable(self,object)
  return self
end

function object:clone()
  local newObject=object.new(self.anchor)
  for i=1,#self.polygons do
    newObject.polygons[i]=self.polygons[i]:clone()
  end
  return newObject
end

function object:mirror()
  for i=1,#self.polygons do
    self.polygons[i]:mirror(self.anchor)
  end
  return self
end

function object:mirrored()
  local newObject=self:clone()
  newObject:mirror()
  return newObject
end

function object:rotate(angle)
  for i=1,#self.polygons do
    self.polygons[i]:rotate(self.anchor,angle)
  end
  return self
end

function object:rotated(angle)
  local newObject=self:clone()
  newObject:rotate(angle)
  return newObject
end

function object:translate(deltaVector)
  for i=1,#self.polygons do
    self.polygons[i]:translate(deltaVector)
  end
  self.anchor=self.anchor+deltaVector
  return self
end

function object:translated(deltaVector)
  local newObject=self:clone()
  newObject:translate(deltaVector)
  return newObject
end

function object:draw()
  for i=1,#self.polygons do
    self.polygons[i]:draw()
  end
end

return object
-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen

local vector=require("modules.vector")
local vertex=require("modules.vertex")
local polygon=require("modules.polygon")
local object=require("modules.object")

local rotationAngle=math.rad(360/32)

local instance={}
instance.__index=instance

function instance.new(index)
  local self={
    position=vector.new(64,64),
    index=index,
    angle=0,
    mirrored=false,
  }
  setmetatable(self,instance)
  return self
end

function instance:clone()
  local newInstance=instance.new(self.position,self.index)
  newInstance.angle=self.angle
  newInstance.mirrored=self.mirrored
  return newInstance
end

function instance:draw(obj)
  local newObject=obj:clone()
  newObject:rotate(self.angle*rotationAngle)
  if self.mirrored then 
    newObject:mirror() 
  end
  local deltaVector=self.position-obj.anchor
  newObject:translate(deltaVector)
  newObject:draw()
end

return instance
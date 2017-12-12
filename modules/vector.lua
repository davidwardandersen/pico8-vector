-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen
-- This vector module is based on a tutorial by Michael Ebens - http://nova-fusion.com/2011/06/30/lua-metatables-tutorial/

local vector={}
vector.__index=vector

function vector.new(x,y)
  local self={
    x=x,
    y=y,
  }
  setmetatable(self,vector)
  return self
end

function vector.__eq(a,b)
  return a.x==b.x and a.y==b.y
end

function vector.__add(a,b)
  if type(a)=="number" then
    return vector.new(a+b.x,a+b.y)
  elseif type(b)=="number" then
    return vector.new(a.x+b,a.y+b)
  else
    return vector.new(a.x+b.x,a.y+b.y)
  end
end

function vector.__sub(a,b)
  if type(a)=="number" then
    return vector.new(a-b.x,a-b.y)
  elseif type(b)=="number" then
    return vector.new(a.x-b,a.y-b)
  else
    return vector.new(a.x-b.x,a.y-b.y)
  end
end

function vector.__mul(a,b)
  if type(a)=="number" then
    return vector.new(a*b.x,a*b.y)
  elseif type(b)=="number" then
    return vector.new(a.x*b,a.y*b)
  else
    return vector.new(a.x*b.x,a.y*b.y)
  end
end

function vector.__div(a,b)
  if type(a)=="number" then
    return vector.new(a/b.x,a/b.y)
  elseif type(b)=="number" then
    return vector.new(a.x/b,a.y/b)
  else
    return vector.new(a.x/b.x,a.y/b.y)
  end
end

function vector.__tostring(a)
  return "("..a.x..","..a.y..")"
end

function vector:clone()
  return vector.new(self.x,self.y)
end

function vector:abs()
  return vector.new(math.abs(self.x),math.abs(self.y))
end

function vector:floor()
  return vector.new(math.floor(self.x),math.floor(self.y))
end

function vector:round()
  return vector.new(math.floor(self.x+0.5),math.floor(self.y+0.5))
end

function vector:rotate(angle)
  local c=math.cos(angle)
  local s=math.sin(angle)
  local x=self.x*c-self.y*s
  local y=self.y*c+self.x*s
  return vector.new(x,y)
end

function vector.splitEdge(a,b)
  local split=a*0.5+b*0.5
  return split
end

return vector
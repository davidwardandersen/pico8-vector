-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen

local vector=require("modules.vector")
local vertex=require("modules.vertex")

-----------------------
-- PRIVATE FUNCTIONS --
-----------------------

local function sortInsert(t,v)
  if #t==0 then
    t[1]=v
  else
    local i=#t+1
    while i>1 and v<t[i-1] do
      t[i]=t[i-1]
      i=i-1
    end
    t[i]=v
  end
end

local function fillPolygon(p)
  local vertices=p.vertices
  -- "endpoints" is a table using y for the keys and x for the values.
  local endpoints={}
  for i=1,#vertices do
    -- Initialize lastDirection to be the last non-zero y direction (1 or -1) before the first vector
    local lastYDirection=0
    for k=2,#vertices[i] do
      local a,b=vertices[i][k-1],vertices[i][k]
      local deltaVector=b.position-a.position
      local yDirection=deltaVector.y>0 and 1 or -1
      if deltaVector.y~=0 then 
        lastYDirection=yDirection 
      end
    end
    -- Find all pixels on edges between vertices, moving in y-direction
    for k=2,#vertices[i] do
      local a,b=vertices[i][k-1],vertices[i][k]
      local deltaVector=b.position-a.position
      local xDirection=deltaVector.x>0 and 1 or -1
      local yDirection=deltaVector.y>0 and 1 or -1
      deltaVector=deltaVector:abs()
      local slope=deltaVector.x/deltaVector.y -- Slope (run/rise instead of rise/run because always incrementing pixel y by 1)
      if deltaVector.y~=0 then
        -- if the first pixel is not part of a peak, add it to the table
        if yDirection~=-lastYDirection then
          if not endpoints[a.position.y] then 
            endpoints[a.position.y]={} 
          end
          sortInsert(endpoints[a.position.y],a.position.x)
        end
        for y=1,deltaVector.y-1 do -- Skip the last pixel of the line to avoid duplicates
          local x=y*slope
          -- Get the actual x and y value based on origin and direction of vector
          x=math.floor(x*xDirection+0.5)+a.position.x -- multiply x by the vector direction before rounding to match pico-8 lines
          y=y*yDirection+a.position.y
          if not endpoints[y] then 
            endpoints[y]={} 
          end
          sortInsert(endpoints[y],x)
        end
        lastYDirection=yDirection
      end
    end
  end
  -- draw polygon fill
  for y,x in pairs(endpoints) do
    for i=2,#x,2 do
      love.graphics.setColor(colors[p.fillColor])
      love.graphics.line(x[i-1],y,x[i],y)
    end
  end
end

local function outlinePolygon(p)
  local vertices=p.vertices
  for i=1,#vertices do
    if #vertices[i]>1 then
      for k=2,#vertices[i] do
        local pixels={}
        local a,b=vertices[i][k-1],vertices[i][k]
        local deltaVector=b.position-a.position
        local xDirection=deltaVector.x>0 and 1 or -1
        local yDirection=deltaVector.y>0 and 1 or -1
        deltaVector=deltaVector:abs()
        if deltaVector.x>deltaVector.y then
          local slope=deltaVector.y/deltaVector.x
          for x=0,deltaVector.x do
            local y=x*slope
            y=math.floor(y*yDirection+0.5)+a.position.y
            x=x*xDirection+a.position.x
            table.insert(pixels,x)
            table.insert(pixels,y)
          end
        else
          local slope=deltaVector.x/deltaVector.y
          for y=0,deltaVector.y do
            local x=y*slope
            x=math.floor(x*xDirection+0.5)+a.position.x --multiply x by the vector direction before rounding to match pico-8 lines
            y=y*yDirection+a.position.y
            table.insert(pixels,x)
            table.insert(pixels,y)
          end
        end
        love.graphics.setColor(colors[a.color])
        love.graphics.points(pixels)
      end
    end
  end
end

------------
-- MODULE --
------------

local polygon={}
polygon.__index=polygon

function polygon.new()
  local self={
    vertices={},
    fillColor=8,
    closed=true,
  }
  setmetatable(self,polygon)
  return self
end

function polygon:toggleClosed()
  self.closed=not self.closed
end

-- "vertices" is a 2-dimensional table. Each set of vertices is a seperate polygon. This allows for polygons with holes.
function polygon:clone()
  local newPolygon=polygon.new()
  for i=1,#self.vertices do
    newPolygon.vertices[i]={}
    for k=1,#self.vertices[i] do
      newPolygon.vertices[i][k]=self.vertices[i][k]:clone()
    end
  end
  newPolygon.fillColor=self.fillColor
  newPolygon.closed=self.closed
  return newPolygon
end

function polygon:findVertex(groupIndex,x,y)
  local position=vector.new(x,y)
  local v=self.vertices[groupIndex]
  local vertexIndex=nil
  if v then
    for i=1,#v do
      if v[i].position==position then
        vertexIndex=i
      end
    end
  end
  return vertexIndex
end

function polygon:addVertex(groupIndex,x,y,vertexIndex)
  if not self.vertices[groupIndex] then
    self.vertices[groupIndex]={}
  end
  if vertexIndex then
    table.insert(self.vertices[groupIndex],vertexIndex,vertex.new(x,y))
  else
    table.insert(self.vertices[groupIndex],vertex.new(x,y))
  end
  return self
end

function polygon:removeVertex(groupIndex,x,y)
  local vertexIndex=self:findVertex(groupIndex,x,y)
  local v=self.vertices[groupIndex]
  if vertexIndex then
    table.remove(v,vertexIndex)
  end
  return self
end

-- Mirror this polygon
function polygon:mirror(center)
  for i=1,#self.vertices do
    for k=1,#self.vertices[i] do
      self.vertices[i][k]:mirror(center)
    end
  end
  return self
end

-- Return a new mirrored polygon
function polygon:mirrored(center)
  local newPolygon=self:clone()
  for i=1,#self.vertices do
    newPolygon.vertices[i]={}
    for k=1,#self.vertices[i] do
      newPolygon.vertices[i][k]=self.vertices[i][k]:mirrored(center)
    end
  end
  return newPolygon
end

-- Rotate this polygon
function polygon:rotate(center,angle)
  for i=1,#self.vertices do
    for k=1,#self.vertices[i] do
      self.vertices[i][k]:rotate(center,angle)
    end
  end
  return self
end

-- Return a new rotated polygon
function polygon:rotated(center,angle)
  local newPolygon=self:clone()
  for i=1,#self.vertices do
    newPolygon.vertices[i]={}
    for k=1,#self.vertices[i] do
      newPolygon.vertices[i][k]=self.vertices[i][k]:rotated(center,angle)
    end
  end
  return newPolygon
end

-- Translate this polygon
function polygon:translate(deltaVector)
  for i=1,#self.vertices do
    for k=1,#self.vertices[i] do
      self.vertices[i][k]:translate(deltaVector)
    end
  end
  return self
end

-- Return a new translated polygon
function polygon:translated(deltaVector)
  local newPolygon=self:clone()
  for i=1,#self.vertices do
    newPolygon.vertices[i]={}
    for k=1,#self.vertices[i] do
      newPolygon.vertices[i][k]=self.vertices[i][k]:translated(deltaVector)
    end
  end
  return newPolygon
end

-- Return a new subdivided polygon using Chaikin's Algorithm
function polygon:subdivided(subdivisions)
  local newPolygon=self:clone()
  for i=1,#newPolygon.vertices do
    local vertices=newPolygon.vertices[i]
    local newVertices={}
    for k=2,#vertices do
      local a,b=vertex.subdivided(vertices[k-1],vertices[k])
      table.insert(newVertices,a)
      table.insert(newVertices,b)
    end
    if self.closed then
      table.insert(newVertices,newVertices[1]:clone())
    end
    newPolygon.vertices[i]=newVertices
  end
  if subdivisions>1 then 
    newPolygon=newPolygon:subdivided(subdivisions-1) 
  end
  return newPolygon
end

function polygon:draw()
  local newPolygon=self:clone()
  for i=1,#newPolygon.vertices do
    local vertices=newPolygon.vertices[i]
    if self.closed then
      table.insert(vertices,vertices[1]:clone())
    end
  end
  newPolygon=newPolygon:subdivided(2)
  if newPolygon.closed then
    for i=1,#newPolygon.vertices do
      newPolygon.vertices[i][#newPolygon.vertices[i]+1]=newPolygon.vertices[i][1]
    end
    fillPolygon(newPolygon)
  end
  outlinePolygon(newPolygon)
end

function polygon:splitEdges(groupIndex)
  local splits={}
  local clone=self:clone()
  local vertices=clone.vertices[groupIndex]
  if vertices then
    if self.closed then table.insert(vertices,vertices[1]:clone()) end
    for i=2,#vertices do
      local split=vector.splitEdge(vertices[i-1].position,vertices[i].position)
      table.insert(splits,split)
    end
  end
  return splits
end

return polygon
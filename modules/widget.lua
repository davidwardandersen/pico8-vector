-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen

local widget={}
widget.__index=widget

-- x,y,width,height are in guiUnits
-- Example: if the screen is 32 guiUnits wide, an x value of 16 would be in the middle of the screen
function widget.new(guiX,guiY,guiWidth,guiHeight,columns,rows)
  local rectangle={
    x=guiX*guiUnit,
    y=guiY*guiUnit,
    width=guiWidth*guiUnit,
    height=guiHeight*guiUnit,
  } 
  local cell={
    width=rectangle.width/columns,
    height=rectangle.height/rows,
  }
  local self={
    rectangle=rectangle,
    columns=columns,
    rows=rows,
    cell=cell,
    selected=selected,
  }
  setmetatable(self,widget)
  return self
end

-- x,y,width,height are screen coordinates, not guiUnits
function widget.newRectangle(x,y,width,height)
  local rectangle={
    x=x,
    y=y,
    width=width,
    height=height,
  }
  return rectangle
end

function widget:contains(x,y)
  return widget.hit(self.rectangle,x,y)
end

function widget.hit(rectangle,x,y)
  return x>rectangle.x and x<rectangle.x+rectangle.width and y>rectangle.y and y<rectangle.y+rectangle.height
end

function widget:getCellPosition(screenX,screenY)
  local cellX=math.floor((screenX-self.rectangle.x)/self.cell.width)
  local cellY=math.floor((screenY-self.rectangle.y)/self.cell.height)
  cellX=math.min(self.columns-1,math.max(0,cellX))
  cellY=math.min(self.rows-1,math.max(0,cellY))
  return cellX,cellY
end

function widget:getScreenPosition(cellX,cellY)
  local screenX=cellX*self.cell.width+self.rectangle.x
  local screenY=cellY*self.cell.height+self.rectangle.y
  return screenX,screenY
end

function widget:getIndex(cellX,cellY)
  return cellY*self.columns+cellX+1
end

-- fill,line are the fill and line color tables {r,g,b,a}
-- if cellX,cellY are not passed in, rectangle is for entire widget.
-- margin value between 0 and 1 shrinks the rectangle. 0 is the full area. A negative value will expand the rectangle.
function widget:drawRectangle(fill,line,margin,cellX,cellY,cellWidth,cellHeight)
  local x=self.rectangle.x
  local y=self.rectangle.y
  local width=self.rectangle.width
  local height=self.rectangle.height
  if cellX then
    x=cellX*self.cell.width+self.rectangle.x
    width=self.cell.width
    height=self.cell.height
  end
  if cellY then
    y=cellY*self.cell.height+self.rectangle.y
    width=self.cell.width
    height=self.cell.height
  end
  if cellWidth then
    width=self.cell.width*cellWidth
  end
  if cellHeight then
    height=self.cell.height*cellHeight
  end
  if margin then
    margin=math.min(width,height)*margin
    x=x+margin
    y=y+margin
    width=width-margin*2
    height=height-margin*2
  end
  if fill then
    love.graphics.setColor(colors[fill])
    love.graphics.rectangle("fill",x,y,width,height)
  end
  if line then
    love.graphics.setColor(colors[line])
    love.graphics.rectangle("line",x,y,width,height)
  end
end

-- fill,line are the fill and line color tables {r,g,b,a}
-- if cellX,cellY are not passed in, circle is for entire widget.
-- margin value between 0 and 1 shrinks the circle. 0 is the full area. A negative value will expand the circle.
function widget:drawCircle(fill,line,margin,cellX,cellY)
  local x=self.rectangle.x
  local y=self.rectangle.y
  local width=self.rectangle.width
  local height=self.rectangle.height
  if cellX then
    x=cellX*self.cell.width+self.rectangle.x
    width=self.cell.width
    height=self.cell.height
  end
  if cellY then
    y=cellY*self.cell.height+self.rectangle.y
    width=self.cell.width
    height=self.cell.height
  end
  x=x+width/2
  y=y+height/2
  local radius=math.min(width,height)/2
  if margin then
    margin=math.min(width,height)*margin
    radius=radius-margin
  end
  if fill then
    love.graphics.setColor(colors[fill])
    love.graphics.circle("fill",x,y,radius)
  end
  if line then
    love.graphics.setColor(colors[line])
    love.graphics.circle("line",x,y,radius)
  end
end

-- fill,line are the fill and line color tables {r,g,b,a}
-- if cellX,cellY are not passed in, ring is for entire widget.
-- margin value between 0 and 1 shrinks the ring. 0 is the full area. A negative value will expand the ring.
function widget:drawRing(fill,line,lineWidth,margin,cellX,cellY)
  local defaultLineWidth=love.graphics.getLineWidth()
  local x=self.rectangle.x
  local y=self.rectangle.y
  local width=self.rectangle.width
  local height=self.rectangle.height
  if cellX then
    x=cellX*self.cell.width+self.rectangle.x
    width=self.cell.width
    height=self.cell.height
  end
  if cellY then
    y=cellY*self.cell.height+self.rectangle.y
    width=self.cell.width
    height=self.cell.height
  end
  x=x+width/2
  y=y+height/2
  local radius=math.min(width,height)/2
  if margin then
    margin=math.min(width,height)*margin
    radius=radius-margin
  end
  love.graphics.setLineWidth(lineWidth*3)
  if line then
    love.graphics.setColor(colors[line])
    love.graphics.circle("line",x,y,radius)
  end
  love.graphics.setLineWidth(lineWidth)
  if fill then
    love.graphics.setColor(colors[fill])
    love.graphics.circle("line",x,y,radius)
  end
  love.graphics.setLineWidth(defaultLineWidth)
end

-- width is the line width
-- fill,line are the fill and line color tables {r,g,b,a}
function widget:drawLine(fill,line,lineWidth,x1,y1,x2,y2)
  local defaultLineWidth=love.graphics.getLineWidth()
  width,height=self.cell.width,self.cell.height
  x1=x1*width+width/2+self.rectangle.x
  y1=y1*height+height/2+self.rectangle.y
  x2=x2*width+width/2+self.rectangle.x
  y2=y2*width+height/2+self.rectangle.y
  love.graphics.setLineWidth(lineWidth*3)
  if line then
    love.graphics.setColor(colors[line])
    love.graphics.line(x1,y1,x2,y2)
  end
  love.graphics.setLineWidth(lineWidth)
  if fill then
    love.graphics.setColor(colors[fill])
    love.graphics.line(x1,y1,x2,y2)
  end
  love.graphics.setLineWidth(defaultLineWidth)
end

function widget:label(font,label,color,cellX,cellY)
  local x,y=self:getScreenPosition(cellX,cellY)
  love.graphics.setColor(colors[color])
  love.graphics.printf(label,x,y+(self.cell.height-font:getHeight())/2,self.cell.width,"center")
end

function widget:image(image)
  local r,g,b,a=love.graphics.getColor()
  love.graphics.setColor(255,255,255,255)
  local x,y,width,height=self.rectangle.x,self.rectangle.y,self.rectangle.width,self.rectangle.height
  local imageWidth,imageHeight=image:getDimensions()
  love.graphics.draw(image,x,y,0,width/imageWidth,height/imageHeight)
  love.graphics.setColor(r,g,b,a)
end

return widget
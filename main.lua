-- Vector editor for creating PICO-8 graphics and animations
-- by David W Andersen
-- Headers made with Patrick Gillespie's "Text to ASCII Art Generator" - http://patorjk.com/software/taag/

-- Things to change

-- Use getter/setter methods instead of accessing fields directly
-- Maybe consolidate polygon and vertex modules
-- Add vertexGroup functions
-- Find a better way to check whether nested objects are nil
-- Try a table for all clickable objects with hitboxes (vertices for example)
-- Make gui module with guiUnit argument that creates different widgets (ex: createSlider)
-- Map function that converts number from one range of values to another
-- When creating new vertex, use new vector to create it so that it gets those functions

-- Features to add

-- load strings back into the editor
-- Animations
-- Animation preview
-- Background reference images from file
-- Marquee select multiple vertices
-- Split vertex groups into new polygons or combine polygons into one
-- Drag individual polygon or all visible polygons
-- Add x/y scale transform
-- Transform polygons and not just instances
-- Maybe rotate directly instead of with slider (with transform handles or something)

local widget=require("modules.widget")
local vector=require("modules.vector")
local vertex=require("modules.vertex")
local polygon=require("modules.polygon")
local object=require("modules.object")
local instance=require("modules.instance")

function love.load()
  love.window.setMode(1920,1080)
  love.graphics.setBackgroundColor(127, 127, 127)
  defaultLineWidth=3
  love.graphics.setLineWidth(defaultLineWidth)
  love.graphics.setPointSize(1)
  font=love.graphics.newFont(24)
  love.graphics.setFont(font)
  love.graphics.setDefaultFilter("nearest")
  love.graphics.setLineStyle("rough")

  packedString=""
  savedMessage="S - Copy string to clipboard"

  initLookup()
  initInput()
  initGui()
  initArt()
end

function love.update(dt)
  updateArt()
  updateInput()
  packedString=packArt()
end

function love.draw()
  drawArt()
  drawGui()
  local testString=""
  love.graphics.setColor(colors[1])
end

--[[888      .d88888b.   .d88888b.  888    d8P  888     888 8888888b.       88888888888     d8888 888888b.   888      8888888888 .d8888b.  
    888     d88P" "Y88b d88P" "Y88b 888   d8P   888     888 888   Y88b          888        d88888 888  "88b  888      888       d88P  Y88b 
    888     888     888 888     888 888  d8P    888     888 888    888          888       d88P888 888  .88P  888      888       Y88b.      
    888     888     888 888     888 888d88K     888     888 888   d88P          888      d88P 888 8888888K.  888      8888888    "Y888b.   
    888     888     888 888     888 8888888b    888     888 8888888P"           888     d88P  888 888  "Y88b 888      888           "Y88b. 
    888     888     888 888     888 888  Y88b   888     888 888                 888    d88P   888 888    888 888      888             "888 
    888     Y88b. .d88P Y88b. .d88P 888   Y88b  Y88b. .d88P 888                 888   d8888888888 888   d88P 888      888       Y88b  d88P 
    88888888 "Y88888P"   "Y88888P"  888    Y88b  "Y88888P"  888                 888  d88P     888 8888888P"  88888888 8888888888 "Y8888P"  ]]

function initLookup()
  -- int/string conversion lookup table
  charList=" 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_-@$^|`"
  s2i={} --string to int
  i2s={} --int to string
  for i=1,64 do
    s2i[string.sub(charList,i,i)]=i
    i2s[i]=string.sub(charList,i,i)
  end  
  -- 16 colors for the PICO-8 palette
  colors={{0,0,0,255},{29,43,83,255},{126,37,83,255},{0,135,81,255},{171,82,54,255},{95,87,79,255},{194,195,199,255},{255,241,232,255},{255,0,77,255},{255,163,0,255},{255,240,36,255},{0,231,86,255},{41,173,255,255},{131,118,156,255},{255,119,168,255},{255,204,170,255}}
end

--[[ .d8888b.  888     888 8888888 
    d88P  Y88b 888     888   888   
    888    888 888     888   888   
    888        888     888   888   
    888  88888 888     888   888   
    888    888 888     888   888   
    Y88b  d88P Y88b. .d88P   888   
     "Y8888P88  "Y88888P"  8888888  ]]

function initGui()
  guiUnit=love.graphics.getWidth()/32 -- Divide the screen into units to easily position gui elements
  gui={
    canvas=widget.new(1,1,16,16,64,64),
    color=widget.new(17,1,1,16,1,16),
    frame=widget.new(18,1,1,16,1,16),
    framePolygon=widget.new(19,1,1,16,1,16),
    object=widget.new(20,1,1,16,1,16),
    objectPolygon=widget.new(21,1,1,16,1,16),
    rotate=widget.new(22,1,1,16,1,32),
    preview=widget.new(23,1,8,8,1,1),
    vertexGroup=widget.new(23,9,8,1,8,1),
    mirror=widget.new(23,10,1,1,1,1),
    message=widget.new(23,11,8,5,1,1)
  }
end

function drawGui()
  --love.graphics.setColor(255,255,255,255)
  gui.canvas:image(currentGroup.canvas)
  gui.canvas:drawRectangle(nil,1)
  for i=0,15 do
    gui.color:drawRectangle(i+1,1,nil,0,i)
    gui.frame:drawRectangle(8,1,nil,0,i)
    gui.frame:label(font,i+1,1,0,i)
    local color=6
    if frames[selected.frame].polygons[i+1] then
      color=8
    end
    gui.framePolygon:drawRectangle(color,1,nil,0,i)
    local thisInstance=frames[selected.frame].instances[i+1]
    if thisInstance then
      gui.framePolygon:label(font,thisInstance.index,1,0,i)
    end
    gui.object:drawRectangle(14,1,nil,0,i)
    gui.object:label(font,i+1,1,0,i)
    color=3
    if objects[selected.object].polygons[i+1] then
      color=14
    end
    gui.objectPolygon:drawRectangle(color,1,nil,0,i)
  end
  -- frame
  gui.frame:drawRectangle(nil,1,0.2,0,selected.frame-1)
  -- object
  gui.object:drawRectangle(nil,1,0.2,0,selected.object-1)
  -- polygon
  if selected.mode=="frame" then
    gui.framePolygon:drawRectangle(nil,1,0.2,0,selected.polygon-1)
  elseif selected.mode=="object" then
    gui.objectPolygon:drawRectangle(nil,1,0.2,0,selected.polygon-1)
  end
  -- rotate
  local thisInstance=frames[selected.frame].instances[selected.polygon]
  if selected.mode=="frame" and thisInstance then
    gui.rotate:drawRectangle(2)
    gui.rotate:drawRectangle(13,nil,nil,0,0,1,thisInstance.angle)
    gui.rotate:drawRectangle(nil,1)
    gui.rotate:drawRectangle(8,1,nil,0,thisInstance.angle)
    gui.rotate:label(font,math.floor(thisInstance.angle*math.deg(rotationAngle)+0.5),1,0,thisInstance.angle)
  end
  -- object preview
  gui.preview:image(objects[selected.object].canvas)
  gui.preview:drawRectangle(nil,1)
  -- vertex group  
  local thisPolygon=currentGroup.polygons[selected.polygon]
  local lastVertexGroup=0
  if thisPolygon then
    for i=1,8 do
      if thisPolygon.vertices[i] then
        lastVertexGroup=i
      end
    end
  end
  for i=0,lastVertexGroup do
    local color=6
    if thisPolygon then
      if thisPolygon.vertices[i+1] then
        color=8
      end
    end
    gui.vertexGroup:drawRectangle(color,1,nil,i,0)
    gui.vertexGroup:label(font,i+1,1,i,0)
  end
  gui.vertexGroup:drawRectangle(nil,1,0.2,selected.vertexGroup-1,0)
  -- mirror
  if selected.mode=="frame" and thisInstance then
    gui.mirror:drawRectangle(nil,1)
    if thisInstance.mirrored then
      gui.mirror:drawCircle(1,nil,0.9)
    end
  end
  -- message
  love.graphics.print(savedMessage.."\n\nString length - "..#packedString.."\nF - Close/Open polygon\nH - Hide lines\nBackspace - Delete polygon\nShift + Backspace - Delete instance\nShift + Click vertex - pin/unpin vertex",gui.message.rectangle.x,gui.message.rectangle.y)
  -- polygons
  local splits={}
  if thisPolygon then
    local vertices=thisPolygon.vertices[selected.vertexGroup]
    if vertices then
      splits=thisPolygon:splitEdges(selected.vertexGroup)
      for i=1,#vertices do
        local a,b=vertices[i],vertices[i+1]
        if not b then
          if thisPolygon.closed then b=vertices[1] end
        end
        if b and showLines then
          gui.canvas:drawLine(8,1,3,a.position.x/2,a.position.y/2,b.position.x/2,b.position.y/2)
        end
      end
      for i=1,#splits do
        local thisSplit=splits[i]/2
        thisSplit=thisSplit:floor()
        gui.canvas:drawCircle(1,8,nil,thisSplit.x,thisSplit.y)
      end
      for i=1,#vertices do
        local a=vertices[i]
        local vertexColor=8
        if selected.vertex==i then
          vertexColor=13
        end
        gui.canvas:drawCircle(vertexColor,1,nil,a.position.x/2,a.position.y/2)
        if a.pin then
          gui.canvas:drawRectangle(vertexColor,1,nil,a.position.x/2,a.position.y/2)
        end
      end
    end
  end
  if hovering then
    if hovering.name=="canvas" then
      local thisVertex=nil
      if thisPolygon then
        thisVertex=thisPolygon:findVertex(selected.vertexGroup,hovering.x*2,hovering.y*2)
      end
      for i=1,#splits do
        local thisSplit=splits[i]/2
        thisSplit=thisSplit:floor()
        if thisSplit.x==hovering.x and thisSplit.y==hovering.y then
          thisVertex=1
        end
      end
      if selected.mode=="frame" then
        local thisInstance=frames[selected.frame].instances[selected.polygon]
        if thisInstance then
          local position=thisInstance.position
          if position.x==hovering.x*2 and position.y==hovering.y*2 then
            thisVertex=1
          end
        end
      elseif selected.mode=="object" then
        if currentGroup.anchor.x==hovering.x*2 and currentGroup.anchor.y==hovering.y*2 then
          thisVertex=1
        end
      end
      if thisVertex then
        gui.canvas:drawRing(8,1,3,-1,hovering.x,hovering.y)
      else
        gui.canvas:drawCircle(8,1,nil,hovering.x,hovering.y)
      end
    end
  end
  -- draw object anchor
  if selected.mode=="frame" then
    local thisInstance=frames[selected.frame].instances[selected.polygon]
    if thisInstance then
      local position=thisInstance.position
      gui.canvas:drawCircle(9,1,nil,position.x/2,position.y/2)
    end
  elseif selected.mode=="object" then
    local anchor=currentGroup.anchor
    gui.canvas:drawCircle(9,1,nil,anchor.x/2,anchor.y/2)
  end
end

--[[
       d8888 8888888b. 88888888888 
      d88888 888   Y88b    888     
     d88P888 888    888    888     
    d88P 888 888   d88P    888     
   d88P  888 8888888P"     888     
  d88P   888 888 T88b      888     
 d8888888888 888  T88b     888     
d88P     888 888   T88b    888     
]]

function initArt()  
  rotationAngle=math.rad(360/32)
  frames={}
  objects={}
  for i=1,16 do
    frames[i]={
      polygons={},
      instances={},
      canvas=love.graphics.newCanvas(128,128),
    }
    objects[i]={
      polygons={},
      anchor=vector.new(64,64),
      canvas=love.graphics.newCanvas(128,128),
    }
  end
end

function updateArt()

end

function drawArt()
  love.graphics.setLineWidth(1)
  love.graphics.setCanvas(currentGroup.canvas)
  love.graphics.clear()
  for i=1,16 do
    local thisPolygon=currentGroup.polygons[i]
    local thisInstance=frames[selected.frame].instances[i]
    if thisPolygon then
      thisPolygon:draw()
    end
    if selected.mode=="frame" and thisInstance then
      local thisObject=objects[thisInstance.index]
      local newObject=object.new(thisObject.anchor)
      newObject.polygons=thisObject.polygons
      thisInstance:draw(newObject)
    end
  end
  love.graphics.setCanvas()
  love.graphics.setLineWidth(3)
end

--[[8888888b.     d8888  .d8888b.  888    d8P         d88P 888     888 888b    888 8888888b.     d8888  .d8888b.  888    d8P  
    888   Y88b   d88888 d88P  Y88b 888   d8P         d88P  888     888 8888b   888 888   Y88b   d88888 d88P  Y88b 888   d8P   
    888    888  d88P888 888    888 888  d8P         d88P   888     888 88888b  888 888    888  d88P888 888    888 888  d8P    
    888   d88P d88P 888 888        888d88K         d88P    888     888 888Y88b 888 888   d88P d88P 888 888        888d88K     
    8888888P" d88P  888 888        8888888b       d88P     888     888 888 Y88b888 8888888P" d88P  888 888        8888888b    
    888      d88P   888 888    888 888  Y88b     d88P      888     888 888  Y88888 888      d88P   888 888    888 888  Y88b   
    888     d8888888888 Y88b  d88P 888   Y88b   d88P       Y88b. .d88P 888   Y8888 888     d8888888888 Y88b  d88P 888   Y88b  
    888    d88P     888  "Y8888P"  888    Y88b d88P         "Y88888P"  888    Y888 888    d88P     888  "Y8888P"  888    Y88b ]]

function packArt()
  local s=""
  for i=1,16 do
    local thisObject=objects[i]
    s=s..packObject(thisObject)
  end
  s=s..[[\]]
  for i=1,16 do
    local thisFrame=frames[i]
    s=s..packFrame(thisFrame)
  end
  return s
end

function packFrame(thisFrame)
  local s=""
  for i=1,16 do
    local thisPolygon=thisFrame.polygons[i]
    if thisPolygon and #thisPolygon.vertices[1]>0 then
      s=s..packPolygon(thisPolygon)
    end
    local thisInstance=thisFrame.instances[i]
    if thisInstance then
      s=s..packInstance(thisInstance)
    end
  end
  if #s>0 then s=s.."'" end
  return s
end

function packObject(thisObject)
  local s=""
  for i=1,16 do
    local thisPolygon=thisObject.polygons[i]
    if thisPolygon and #thisPolygon.vertices[1]>0 then
      s=s..packPolygon(thisPolygon)
    end
  end
  local anchor=thisObject.anchor
  if #s>0 then s=i2s[anchor.x/2]..i2s[anchor.y/2]..s.."'" end
  return s
end

function packPolygon(polygon)
  local s=""
  local vertices=polygon.vertices
  local fill=17
  if polygon.closed then
    fill=polygon.fillColor
  end
  s=s..i2s[fill]
  for i=1,#vertices do
    local vertexGroup=vertices[i]
    for k=1,#vertexGroup do
      local thisVertex=vertexGroup[k]
      local color=thisVertex.color
      if thisVertex.pin then color=color+32 end
      s=s..i2s[color]..i2s[thisVertex.position.x/2+1]..i2s[thisVertex.position.y/2+1]
    end
    if #vertices>1 and i<#vertices then s=s.."?" end
  end
  s=s.."&"
  return s
end

function packInstance(thisInstance)
  local s=""
  local transform=thisInstance.angle+1
  if thisInstance.mirrored then transform=transform+32 end -- if the clone is mirrored, rotate is 33-64 instead of 1-32 to combine mirrored and angle in one character
  s=s..i2s[thisInstance.position.x/2+1]..i2s[thisInstance.position.y/2+1]..i2s[thisInstance.index]..i2s[transform]..'"'
  return s
end

function unpackVectorArt(s)
  initVectorArt()
  local prefabTotal=s2i[string.sub(s,1,1)]-1
  --bgColor=s2i[string.sub(s,2,2)]
  --local split=string.sub(s,1,4)+0
  local start=2
  local allStrings={}
  for i=2,#s do
    if string.sub(s,i,i)=="'" then
      table.insert(allStrings,string.sub(s,start,i-1))
      start=i+1
    end
  end
  for i=1,prefabTotal do
    unpackPrefab(allStrings[i],i)
  end
  for i=prefabTotal+1,#allStrings do
    unpackFrame(allStrings[i],i-prefabTotal)
  end
  -- Draw everything
  for i=16,1,-1 do
    currentFrame,currentPrefab=i,i
    currentMode="prefab"
    drawVectorArt()
    currentMode="frame"
    drawVectorArt()
  end
end

--[[8888888 888b    888 8888888b.  888     888 88888888888 
      888   8888b   888 888   Y88b 888     888     888     
      888   88888b  888 888    888 888     888     888     
      888   888Y88b 888 888   d88P 888     888     888     
      888   888 Y88b888 8888888P"  888     888     888     
      888   888  Y88888 888        888     888     888     
      888   888   Y8888 888        Y88b. .d88P     888     
    8888888 888    Y888 888         "Y88888P"      888  ]]   

function initInput()
  dragging=nil
  pressed=nil
  hovering=nil
  showLines=true
  selected={
    mode="frame",
    frame=1,
    object=1,
    polygon=1,
    rotate=0,
    vertexGroup=1,
    vertex=1,
  }
  currentGroup=nil
end

function updateInput()
  currentGroup=selected.mode=="frame" and frames[selected.frame] or objects[selected.object]
  local mx,my=love.mouse.getPosition(mx,my)
  hovering=nil
  for name,widget in pairs(gui) do
    if widget:contains(mx,my) then
      local x,y=widget:getCellPosition(mx,my)
      local index=widget:getIndex(x,y)
      hovering={
        name=name,
        x=x,
        y=y,
        index=index,
      }
    end
  end
  if dragging then    
    local x,y=gui[pressed.name]:getCellPosition(mx,my)
    local index=gui[pressed.name]:getIndex(x,y)
    hovering={
      name=pressed.name,
      x=x,
      y=y,
      index=index,
    }
    if dragging.name=="canvas" then
      local x=hovering.x*2
      local y=hovering.y*2
      if dragging.instance then
        local thisInstance=currentGroup.instances[selected.polygon]
        thisInstance.position=vector.new(x,y)
      elseif dragging.anchor then
        currentGroup.anchor=vector.new(x,y)
      else
        local thisVertex=currentGroup.polygons[selected.polygon].vertices[selected.vertexGroup][selected.vertex]
        thisVertex.position=vector.new(x,y)
      end
    elseif dragging.name=="rotate" then
      local thisInstance=frames[selected.frame].instances[selected.polygon]
      if selected.mode=="frame" and thisInstance then
        thisInstance.angle=hovering.y
      end
    end
  end
end

function love.mousepressed(mx,my,button)
  savedMessage="S - Copy string to clipboard"
  pressed=nil
  for name,widget in pairs(gui) do
    if widget:contains(mx,my) then
      local x,y=widget:getCellPosition(mx,my)
      local index=widget:getIndex(x,y)
      pressed={
        name=name,
        x=x,
        y=y,
        index=index,
      }
    end
  end
  if pressed then
    if button==1 then
      if pressed.name=="canvas" then
        -- Check if object anchor was clicked
        if selected.mode=="frame" then
          local thisInstance=frames[selected.frame].instances[selected.polygon]
          if thisInstance then
            local position=thisInstance.position
            if position.x==pressed.x*2 and position.y==pressed.y*2 then
              pressed.instance=true
              dragging=pressed
            end
          end
        elseif selected.mode=="object" then
          local anchor=currentGroup.anchor
          if anchor.x==pressed.x*2 and anchor.y==pressed.y*2 then
            pressed.anchor=true
            dragging=pressed
          end
        end
        -- Check if vertex was clicked
        if not pressed.anchor then
          local thisPolygon=currentGroup.polygons[selected.polygon]
          if thisPolygon then
            local vertices=thisPolygon.vertices[selected.vertexGroup]
            if vertices then
              local splits=thisPolygon:splitEdges(selected.vertexGroup)
              for i=1,#splits do
                local thisSplit=splits[i]/2
                thisSplit=thisSplit:floor()
                if thisSplit.x==pressed.x and thisSplit.y==pressed.y then
                  currentGroup.polygons[selected.polygon]:addVertex(selected.vertexGroup,pressed.x*2,pressed.y*2,i+1)
                end
              end
              local thisVertex=nil
              for i=1,#vertices do
                thisVertex=thisPolygon:findVertex(selected.vertexGroup,pressed.x*2,pressed.y*2)
              end
              if thisVertex then
                -- If left shift is held then pin vertex
                if love.keyboard.isDown("lshift") then
                  vertices[thisVertex]:togglePin()
                  selected.vertex=thisVertex
                  dragging=pressed
                -- If hotkey is not held start dragging the vertex
                else
                  selected.vertex=thisVertex
                  dragging=pressed
                end
              end
            end
          end
        end
        -- If anchor or vertex wasn't clicked add new vertex
        if not dragging then
          if not currentGroup.polygons[selected.polygon] then
            currentGroup.polygons[selected.polygon]=polygon.new()
          end
          currentGroup.polygons[selected.polygon]:addVertex(selected.vertexGroup,pressed.x*2,pressed.y*2)
        end
      elseif pressed.name=="color" then
        local thisPolygon=currentGroup.polygons[selected.polygon]
        if thisPolygon then
          local vertices=thisPolygon.vertices[selected.vertexGroup]
          if love.keyboard.isDown("lshift") then
            local thisVertex=vertices[selected.vertex]
            if thisVertex then
              thisVertex.color=pressed.index
            end
          else
            for i=1,#vertices do
              local thisVertex=vertices[i]
              thisVertex.color=pressed.index
            end
          end
        end
      elseif pressed.name=="frame" then
        selected.frame=pressed.index
        selected.vertexGroup=1
      elseif pressed.name=="framePolygon" then
        selected.polygon=pressed.index
        selected.mode="frame"
        selected.vertexGroup=1
      elseif pressed.name=="object" then
        selected.object=pressed.index
        selected.vertexGroup=1
      elseif pressed.name=="objectPolygon" then
        selected.polygon=pressed.index
        selected.mode="object"
        selected.vertexGroup=1
      elseif pressed.name=="rotate" then
        dragging=pressed
      elseif pressed.name=="preview" then
        if selected.mode=="frame" then
          local notEmpty=false
          for i=1,16 do
            if objects[selected.object].polygons[i] then notEmpty=true end
          end
          if notEmpty then currentGroup.instances[selected.polygon]=instance.new(selected.object) end
        end
      elseif pressed.name=="vertexGroup" then
        local thisPolygon=currentGroup.polygons[selected.polygon]
        if thisPolygon then
          local lastVertexGroup=0
          for i=1,8 do
            if thisPolygon.vertices[i] then
              lastVertexGroup=i
            end
          end
          if pressed.index<=lastVertexGroup+1 then
            selected.vertexGroup=pressed.index
          end
        end
      elseif pressed.name=="mirror" then
        local thisInstance=frames[selected.frame].instances[selected.polygon]
        if selected.mode=="frame" and thisInstance then
          thisInstance.mirrored=not thisInstance.mirrored
        end
      end
    elseif button==2 then
      if pressed.name=="canvas" then
        local thisPolygon=currentGroup.polygons[selected.polygon]
        if thisPolygon then
          local vertices=thisPolygon.vertices[selected.vertexGroup]
          if vertices then
            if #vertices==1 then
              local thisVertex=thisPolygon:findVertex(selected.vertexGroup,pressed.x*2,pressed.y*2)
              if #thisPolygon.vertices==1 then
                if thisVertex then
                  currentGroup.polygons[selected.polygon]=nil
                end
              else
                if thisVertex then
                  table.remove(thisPolygon.vertices,selected.vertexGroup)
                end
              end
            else
              thisPolygon:removeVertex(selected.vertexGroup,pressed.x*2,pressed.y*2)
            end
          end
        end      
      elseif pressed.name=="color" then
        local thisPolygon=currentGroup.polygons[selected.polygon]
        if thisPolygon then
          thisPolygon.fillColor=pressed.index
        end
      elseif pressed.name=="frame" then
        frames[pressed.index],frames[selected.frame]=frames[selected.frame],frames[pressed.index]
        selected.frame=pressed.index
      elseif pressed.name=="framePolygon" then
        if love.keyboard.isDown("lshift") then
          if selected.mode=="frame" then
            currentGroup.instances[pressed.index],currentGroup.instances[selected.polygon]=currentGroup.instances[selected.polygon],currentGroup.instances[pressed.index]
            selected.polygon=pressed.index
          end
        else
          frames[selected.frame].polygons[pressed.index],currentGroup.polygons[selected.polygon]=currentGroup.polygons[selected.polygon],frames[selected.frame].polygons[pressed.index]
          selected.polygon=pressed.index
          selected.mode="frame"
        end
      elseif pressed.name=="object" then
        objects[pressed.index],objects[selected.object]=objects[selected.object],objects[pressed.index]
        selected.frame=pressed.index
      elseif pressed.name=="objectPolygon" then
        objects[selected.object].polygons[pressed.index],currentGroup.polygons[selected.polygon]=currentGroup.polygons[selected.polygon],objects[selected.object].polygons[pressed.index]
        selected.polygon=pressed.index
        selected.mode="object"
      end
    end
  end
end

function love.mousereleased(mx,my,button)
  dragging=nil
end

function love.keypressed(key)
  if key=="s" then
    love.system.setClipboardText(packedString)
    savedMessage="Copied to clipboard"
  elseif key=="f" then
    local thisPolygon=currentGroup.polygons[selected.polygon]
    if thisPolygon then
      thisPolygon:toggleClosed()
    end
  elseif key=="h" then
    showLines=not showLines
  elseif key=="backspace" then
    if love.keyboard.isDown("lshift") then
      if selected.mode=="frame" then
        currentGroup.instances[selected.polygon]=nil
      end
    else
      currentGroup.polygons[selected.polygon]=nil
      selected.vertexGroup=1
    end
  end
end
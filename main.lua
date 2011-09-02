----------------------------------------

function classcall(class, ...)
  local inst = {}
  setmetatable(inst, inst)
  inst.__index = class
  if inst.init then inst:init(...) end
  return inst
end

function class( superclass )
  local t = {}
  t.__index = superclass
  t.__call = classcall
  return setmetatable(t, t)
end

strict_mt = {}
strict_mt.__newindex = function( t, k, v ) error("attempt to update a read-only table", 2) end
strict_mt.__index = function( t, k ) error("attempt to read key "..k, 2) end

function strict( table )
  return setmetatable( table, strict_mt )
end

----------------------------------------

function randomPull( ... )
  local pull = math.random(0, 10000) / 10000
  for n = 1, select('#', ...) do
    local e = select(n, ...)
    if pull < e then return n end
    pull = pull - e
  end
  return nil
end

----------------------------------------

keypress = {}

WHITE = strict { 255, 255, 255, 255 }
GRAY = strict { 144, 144, 144, 255 }

----------------------------------------

StateMachine = {
  stack = {}
}

function StateMachine.push( state )
  print( "State Machine Push", state )
  table.insert( StateMachine.stack, state )
end

function StateMachine.pop()
  print( "State Machine", state )
  table.remove( StateMachine.stack )
end

function StateMachine.isEmpty()
  return ( #StateMachine.stack == 0 )
end

function StateMachine.draw()
  local n = #StateMachine.stack
  if n > 0 then
    StateMachine.stack[n]:draw()
  end
end

function StateMachine.update( dt )
  local n = #StateMachine.stack
  if n > 0 then
    StateMachine.stack[n]:update(dt)
  end
end

----------------------------------------

Sound = {
  bank = {};
  effectFiles = {};
  effectData = {};
}

function Sound.init()
  for name, file in pairs(Sound.effectFiles) do
    Sound.effectData[name] = love.sound.newSoundData(file)
  end
end

function Sound.playsound(name)
  local sound = love.audio.newSource(Sound.effectData[name])
  Sound.bank[sound] = sound
  love.audio.play(sound)
end

function Sound.playmod( file )
  Sound.stopmod()
  Sound.bgm = love.audio.newSource(file, "stream")
  Sound.bgm:setLooping( true )
  Sound.bgm:setVolume(0.8)
  love.audio.play(Sound.bgm)
  Sound.bgmfile = file
end

function Sound.stopmod()
  if not Sound.bgm then return end
  love.audio.stop(Sound.bgm)
  Sound.bgm = nil
  Sound.bgmfile = nil
end

function Sound.update()
  local remove = {}
  for _, src in pairs(Sound.bank) do
    if src:isStopped() then table.insert(remove, src) end
  end
  for _, src in ipairs(remove) do
    Sound.bank[src] = nil
  end
end

----------------------------------------

Graphics = {
  gameWidth = 240,
  gameHeight = 160,
  tileBounds = strict {
  },
  quads = {},
  fontset = [==[ !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~]==],
}
Graphics.xScale = math.floor(love.graphics.getWidth() / Graphics.gameWidth)
Graphics.yScale = math.floor(love.graphics.getHeight() / Graphics.gameHeight)

function Graphics.init()
  love.graphics.setColorMode("modulate")
  love.graphics.setBlendMode("alpha")
  Graphics.loadFont("cgafont.png")
  Graphics.loadTileset("tileset.png")
end

function Graphics.loadTileset(name)
  Graphics.tilesetImage = love.graphics.newImage(name)
  Graphics.tilesetImage:setFilter("nearest", "nearest")
  local sw, sh = Graphics.tilesetImage:getWidth(), Graphics.tilesetImage:getHeight()
  local i = 0
  for y = 0, sh, 8 do
    for x = 0, sw, 8 do
      Graphics.quads[i] = love.graphics.newQuad(x, y, 8, 8, sw, sh)
      i = i + 1
    end
  end
end

function Graphics.loadFont(name)
  local fontimage = love.graphics.newImage(name)
  fontimage:setFilter("nearest", "nearest")
  Graphics.font = love.graphics.newImageFont(fontimage, Graphics.fontset)
  Graphics.font:setLineHeight( fontimage:getHeight() )
  love.graphics.setFont(Graphics.font)
end

function Graphics.drawTile( tile, x, y )
  local xs, ys = Graphics.xScale, Graphics.yScale
  love.graphics.drawq( Graphics.tilesetImage, Graphics.quads[tile],
    math.floor(x*ys)/ys, math.floor(y*ys)/ys )
end

function Graphics.setColorDepth( depth )
  local x = 31 + (255-31) * depth
  love.graphics.setColor( x, x, x )
end

function Graphics.drawTiledRectangle( tile, x, y, w, h, depth )
  Graphics.setColorDepth( depth or 1.0 )
  for ys = y, y+h-1, 8 do
    for xs = x, x+w-1, 8 do
      Graphics.drawTile( tile, xs, ys )
    end
  end
end

function Graphics.drawCappedColumn( tile, top, bottom, x, y, h, depth )
  Graphics.setColorDepth( depth or 1.0 )
  Graphics.drawTile( top, x, y )
  for ys = y+8, y+h-9, 8 do
    Graphics.drawTile( tile, x, ys )
  end
  Graphics.drawTile( bottom, x, y+h-8 )
end

function Graphics.saveScreenshot()
  local screen = love.graphics.newScreenshot()
  local filedata = love.image.newEncodedImageData(screen, "bmp")
  love.filesystem.write( "screenshot.bmp", filedata)
end

function Graphics.changeScale( size )
  Graphics.xScale, Graphics.yScale = size, size
  love.graphics.setMode( Graphics.gameWidth*size, Graphics.gameHeight*size, false )
end

function Graphics.text( x, y, color, str )
  if x == "center" then x = 80-(str:len()*4) end
  love.graphics.setColor(color)
  for c in str:gmatch('.') do
    love.graphics.print(c, x, y)
    x = x + Graphics.font:getWidth(c)
  end
end

----------------------------------------

Animator = class()

function Animator:init( frames )
  self.frames = frames or {}
  self.index = 1
  self.clock = 0
end

function Animator:add( name, length )
  table.insert(self.frames, {name=name, length=length})
end

function Animator:update(dt)
  self.clock = self.clock + dt
  while self.clock >= self.frames[self.index].length do
    self.clock = self.clock - self.frames[self.index].length
    self.index = self.index + 1
    if self.index > #self.frames then
      self.index = 1
    end
  end
end

function Animator:current()
  return self.frames[self.index].name
end

----------------------------------------

TestState = class()
TestState.map = {
  { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 1, 1, 1, 1, 0, 0, 1 },
  { 1, 0, 1, 1, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
  { 1, 0, 1, 0, 1, 1, 0, 1, 0, 1 },
  { 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
  { 1, 0, 0, 1, 0, 1, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
}

--  -1, -2 G --  0, -2 D --  1, -2 H
--
--  -1, -1 E --  0, -1 A --  1, -1 F
--
--  -1,  0 B --  0,  0 * --  1,  0 C

TestState.checkBlocks = {
  { -2, -2, "I" };
  {  2, -2, "J" };
  { -1, -2, "G" };
  {  1, -2, "H" };
  { -1, -1, "E" };
  {  1, -1, "F" };
  {  0, -2, "D" };
  { -1,  0, "B" };
  {  1,  0, "C" };
  {  0, -1, "A" };
}

TestState.movement = { N={ 0, -1 }, E={ 1, 0 }, S={ 0, 1 }, W={ -1, 0 } }
TestState.left = { N="W", E="N", S="E", W="S" }
TestState.right = { N="E", E="S", S="W", W="N" }
TestState.back = { N="S", E="W", S="N", W="E" }
TestState.sinTable = { N={0,1}, E={1,0}, S={0,-1}, W={-1,0} }

function TestState:init()
  self.x = math.floor(#self.map[1]/2)
  self.y = math.floor(#self.map/2)
  self.d = "N"
  self.xOffset = 0
end

debug = function( ... )
  print( ... )
  debug = function() end
end

function TestState:get( x, y )
  if y <= 0 or y > #self.map then return 0 end
  local row = self.map[y]
  if x <= 0 or x > #row then return 0 end
  return row[x]
end

function TestState:trans( check, dir )
  local x, y, s = check[1], check[2], self.sinTable[dir]
  return self.x + (x*s[2]-y*s[1]), self.y + (x*s[1]+y*s[2])
end

function TestState:draw()
  self:draw3dView()
  love.graphics.setColor( 0, 0, 128, 255 )
  love.graphics.rectangle("fill", 160, 0, 80, 160)
  Graphics.text( 168,  8, WHITE, string.format("%i,%i", self.x, self.y) )
  Graphics.text( 168, 16, WHITE, self.d )
  self:drawMiniMap()
end

function TestState:draw3dView()
  for _, check in ipairs( self.checkBlocks ) do
    local x, y = self:trans( check, self.d )
    local id = self:get(x, y)
    if id ~= 0 then
      self:drawWall( id, check[3] )
    end
  end
end

function TestState:drawWall( id, position )
  local x = self.xOffset or 0
  if position == "A" then
    Graphics.drawTiledRectangle( 1, x+16, 16, 128, 128, 0.8 )
  elseif position == "B" then
    Graphics.drawCappedColumn( 1, 2, 4, x+0, 0, 160, 1.0 )
    Graphics.drawCappedColumn( 1, 2, 4, x+8, 8, 144, 0.9 )
  elseif position == "C" then
    Graphics.drawCappedColumn( 1, 3, 5, x+152, 0, 160, 1.0 )
    Graphics.drawCappedColumn( 1, 3, 5, x+144, 8, 144, 0.9 )
  elseif position == "D" then
    Graphics.drawTiledRectangle( 1, x+48, 48, 64, 64, 0.4 )
  elseif position == "E" then
    Graphics.drawTiledRectangle( 1, x+0, 16, 16, 128, 0.8 )
    Graphics.drawCappedColumn( 1, 2, 4, x+16, 16, 128, 0.7 )
    Graphics.drawCappedColumn( 1, 2, 4, x+24, 24, 112, 0.6 )
    Graphics.drawCappedColumn( 1, 2, 4, x+32, 32, 96, 0.5 )
    Graphics.drawCappedColumn( 1, 2, 4, x+40, 40, 80, 0.4 )
  elseif position == "F" then
    Graphics.drawTiledRectangle( 1, x+144, 16, 16, 128, 0.8 )
    Graphics.drawCappedColumn( 1, 3, 5, x+136, 16, 128, 0.7 )
    Graphics.drawCappedColumn( 1, 3, 5, x+128, 24, 112, 0.6 )
    Graphics.drawCappedColumn( 1, 3, 5, x+120, 32, 96, 0.5 )
    Graphics.drawCappedColumn( 1, 3, 5, x+112, 40, 80, 0.4 )
  elseif position == "G" then
    Graphics.drawTiledRectangle( 1, x+0, 48, 48, 64, 0.4 )
    Graphics.drawCappedColumn( 1, 2, 4, x+48, 48, 64, 0.3 )
    Graphics.drawCappedColumn( 1, 2, 4, x+56, 56, 48, 0.2 )
    Graphics.drawCappedColumn( 1, 2, 4, x+64, 64, 32, 0.1 )
    Graphics.drawCappedColumn( 1, 2, 4, x+72, 72, 16, 0.0 )
  elseif position == "H" then
    Graphics.drawTiledRectangle( 1, x+112, 48, 48, 64, 0.4 )
    Graphics.drawCappedColumn( 1, 3, 5, x+104, 48, 64, 0.3 )
    Graphics.drawCappedColumn( 1, 3, 5, x+96, 56, 48, 0.2 )
    Graphics.drawCappedColumn( 1, 3, 5, x+88, 64, 32, 0.1 )
    Graphics.drawCappedColumn( 1, 3, 5, x+80, 72, 16, 0.0 )
  elseif position == "I" then
    Graphics.drawCappedColumn( 1, 2, 4, x+0, 48, 64, 0.3 )
    Graphics.drawCappedColumn( 1, 2, 4, x+8, 56, 48, 0.2 )
    Graphics.drawCappedColumn( 1, 2, 4, x+16, 64, 32, 0.1 )
    Graphics.drawCappedColumn( 1, 2, 4, x+24, 72, 16, 0.0 )
  elseif position == "J" then
    Graphics.drawCappedColumn( 1, 3, 5, x+152, 48, 64, 0.3 )
    Graphics.drawCappedColumn( 1, 3, 5, x+144, 56, 48, 0.2 )
    Graphics.drawCappedColumn( 1, 3, 5, x+136, 64, 32, 0.1 )
    Graphics.drawCappedColumn( 1, 3, 5, x+128, 72, 16, 0.0 )
  end
end

function TestState:drawMiniMap()
  for y = -2, 2 do
    for x = -2, 2 do
      local cell = self:get( self.x + x, self.y + y )
      if cell ~= 0 then
        Graphics.drawTile( cell, 168+(x+2)*8, 80+(y+2)*8 )
      end
    end
  end
  Graphics.text( 184, 96, WHITE, self.d )
end

function TestState:update(dt)
  if keypress["escape"]==1 then StateMachine.pop()
  elseif keypress["up"]==1 then self:move( self.d )
  elseif keypress["left"]==1 then self.d = self.left[self.d]
  elseif keypress["right"]==1 then self.d = self.right[self.d]
  elseif keypress["down"]==1 then self:move( self.back[self.d] )
  end
end

function TestState:move( dir )
  local tab = self.movement[dir]
  local newx, newy = self.x + tab[1], self.y + tab[2]
  if self.map[ newy ][ newx ] == 0 then
    self.x, self.y = newx, newy
  end
end

----------------------------------------

function love.load()
  math.randomseed( os.time() )
  Graphics.init()
  Sound.init()
  StateMachine.push( TestState() )
end

function love.update(dt)
  if dt > 0.1 then dt = 0.1 end
  for i, v in pairs(keypress) do
    keypress[i] = v+1
  end
  if keypress["f2"] == 1 then Graphics.saveScreenshot()
  elseif keypress["f10"] == 1 then love.event.push('q')
  elseif keypress["1"]==1 then Graphics.changeScale(1)
  elseif keypress["2"]==1 then Graphics.changeScale(2)
  elseif keypress["3"]==1 then Graphics.changeScale(3)
  elseif keypress["4"]==1 then Graphics.changeScale(4)
  elseif keypress["5"]==1 then Graphics.changeScale(5)
  elseif keypress["6"]==1 then Graphics.changeScale(6)
  elseif keypress["7"]==1 then Graphics.changeScale(7)
  elseif keypress["8"]==1 then Graphics.changeScale(8)
  end
  StateMachine.update(dt)
  Sound.update()
  if StateMachine.isEmpty() then love.event.push('q') end
end

function love.draw()
  love.graphics.scale( Graphics.xScale, Graphics.yScale )
  StateMachine.draw(dt)
end

function love.keypressed(key, unicode)
  keypress[key] = 0
end

function love.keyreleased(key, unicode)
  keypress[key] = nil
end

--[==[
function love.focus(focused)
  if not focused then
    local n = #stateStack
    if (n > 0) and (stateStack[n].pause) then
      stateStack[n]:pause()
    end
  end
end
]==]


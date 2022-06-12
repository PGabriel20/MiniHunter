function love.load()
  anim8 = require 'libs/anim8'
  sti = require 'libs/sti'
  camera = require 'libs/camera'

  gameMap = sti('resources/maps/testMap.lua')
  cam = camera()

  love.graphics.setDefaultFilter("nearest", "nearest")

  player = {}
  player.x = 400
  player.y = 200
  player.speed = 3
  player.sprite = love.graphics.newImage('resources/sprites/parrot.png')
  player.spriteSheet = love.graphics.newImage('resources/sprites/player-sheet.png')
  player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

  player.animations = {}
  player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
  player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
  player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
  player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)

  player.anim = player.animations.left

  background = love.graphics.newImage('resources/sprites/background.png')
end

function love.update(dt)
  local isPlayerMoving = false

  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()

  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  if love.keyboard.isDown("right") then
    player.x = player.x +  player.speed
    player.anim = player.animations.right
    isPlayerMoving = true
  elseif love.keyboard.isDown("left") then
    player.x = player.x -  player.speed
    player.anim = player.animations.left
    isPlayerMoving = true
  elseif love.keyboard.isDown("up") then
    player.y = player.y -  player.speed
    player.anim = player.animations.up
    isPlayerMoving = true
  elseif love.keyboard.isDown("down") then
    player.y = player.y +  player.speed
    player.anim = player.animations.down
    isPlayerMoving = true
  end

  if isPlayerMoving == false then
    player.anim:gotoFrame(2)
  end

  player.anim:update(dt)
  cam:lookAt(player.x, player.y)

  -- Limitand visão da camera para esconder area fora do mapa
  if cam.x < width/2 then
    cam.x = width/2
  end
  
  if cam.y < height/2 then
    cam.y = height/2
  end

  if cam.x > (mapWidth - width/2) then
    cam.x = (mapWidth - width/2)
  end
  
  if cam.y > (mapHeight - height/2) then
    cam.y = (mapHeight - height/2)
  end




  
end

function love.draw()
  cam:attach()
    gameMap:drawLayer(gameMap.layers["Ground"])
    gameMap:drawLayer(gameMap.layers["Trees"])
    player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
  cam:detach()
end
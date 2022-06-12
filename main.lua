function love.load()
  anim8 = require 'libs/anim8'
  sti = require 'libs/sti'
  camera = require 'libs/camera'
  wf = require 'libs/windfield'

  gameMap = sti('resources/maps/testMap.lua')
  cam = camera()
  world = wf.newWorld(0, 0)

  love.graphics.setDefaultFilter("nearest", "nearest")

  player = {}
  player.x = 400
  player.y = 200
  player.speed = 300
  player.sprite = love.graphics.newImage('resources/sprites/parrot.png')
  player.spriteSheet = love.graphics.newImage('resources/sprites/champions/borg-sheet.png')
  player.grid = anim8.newGrid(16, 16, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

  -- Criando animações para o player de acordo com as linhas/colunas do sprite
  player.animations = {}
  player.animations.down = anim8.newAnimation(player.grid('1-6', 1), 0.2)
  player.animations.up = anim8.newAnimation(player.grid('1-4', 2), 0.2)
  player.animations.left = anim8.newAnimation(player.grid('1-4', 3), 0.2)
  player.animations.right = anim8.newAnimation(player.grid('1-4', 4), 0.2)

  -- posição incial da animação
  player.anim = player.animations.down

  -- Retangulo colisor para player
  player.collider = world:newBSGRectangleCollider(400, 250, 50, 100, 12)
  player.collider:setFixedRotation(true)


  background = love.graphics.newImage('resources/sprites/background.png')

  walls = {}

  if gameMap.layers['Walls'] then
    for i, object in pairs(gameMap.layers['Walls'].objects) do
      local wall = world:newRectangleCollider(object.x, object.y, object.width, object.height)
      wall:setType('static')

      table.insert(walls, wall)
    end
  end
  
end

function love.update(dt)
  local isPlayerMoving = false

  local velocityX = 0
  local velocityY = 0

  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()

  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  if love.keyboard.isDown("right") then
    velocityX = player.speed
    player.anim = player.animations.right
    isPlayerMoving = true
  elseif love.keyboard.isDown("left") then
    velocityX = player.speed * -1
    player.anim = player.animations.left
    isPlayerMoving = true
  elseif love.keyboard.isDown("up") then
    velocityY = player.speed * -1
    player.anim = player.animations.up
    isPlayerMoving = true
  elseif love.keyboard.isDown("down") then
    velocityY = player.speed
    player.anim = player.animations.down
    isPlayerMoving = true
  end

  if isPlayerMoving == false then
    player.anim:gotoFrame(2)
  end

  player.collider:setLinearVelocity(velocityX, velocityY)

  player.anim:update(dt)
  cam:lookAt(player.x, player.y)

  world:update(dt)
  player.x = player.collider:getX()
  player.y = player.collider:getY()

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
    -- world:draw()
  cam:detach()
end
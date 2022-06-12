function love.load()
  anim8 = require 'libs/anim8'
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
end

function love.draw()
  love.graphics.draw(background, 0, 0)
  player.anim:draw(player.spriteSheet, player.x, player.y, nil, 10)
end
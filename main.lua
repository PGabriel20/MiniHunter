local scale = 3
local enemiesKilled = 0
local distance = 0
local spawnEnemyTimerMax = 5
local spawnEnemyTimer = spawnEnemyTimerMax

function love.load()
  anim8 = require 'libs/anim8'
  sti = require 'libs/sti'
  camera = require 'libs/camera'
  wf = require 'libs/windfield'

  sounds = {}
  sounds.blip = love.audio.newSource('resources/sounds/blip.wav', 'static')
  sounds.music = love.audio.newSource('resources/sounds/music.mp3', 'stream')
  sounds.walking = love.audio.newSource('resources/sounds/walking.mp3', 'static')
  sounds.hit = love.audio.newSource('resources/sounds/metal-hit.wav', 'static')
  sounds.armorHit = love.audio.newSource('resources/sounds/armor-hit.wav', 'static')
  sounds.slash = love.audio.newSource('resources/sounds/sword-slash.mp3', 'static')
  sounds.death = love.audio.newSource('resources/sounds/death.mp3', 'static')

  -- sounds.music:play()
  window_width, window_height = love.graphics.getDimensions()
  deathScreen = love.graphics.newImage('resources/images/death.png')

  -- Criando câmera, mundo e mapa
  gameMap = sti('resources/maps/mainMap.lua')
  cam = camera()
  world = wf.newWorld(0, 0)

  love.window.setMode(1200, 700)
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Setup player
  player = {}
  player.x = 0
  player.y = 0
  player.health = 100
  player.damage = 2
  player.speed = 70
  player.hitting = false
  player.spriteSheet = love.graphics.newImage('resources/sprites/champions/borg-sheet.png')
  player.grid = anim8.newGrid(16, 16, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

  -- Criando animações para o player de acordo com as linhas/colunas do sprite
  player.animations = {}
  player.animations.down = anim8.newAnimation(player.grid('1-5', 1), 0.2)
  player.animations.up = anim8.newAnimation(player.grid('1-5', 2), 0.2)
  player.animations.left = anim8.newAnimation(player.grid('1-5', 3), 0.2)
  player.animations.right = anim8.newAnimation(player.grid('1-5', 4), 0.2)
  player.animations.hit = anim8.newAnimation(player.grid('1-6', 8), 0.2)

  -- posição incial da animação
  player.anim = player.animations.down

  -- Retangulo colisor para player
  player.collider = world:newBSGRectangleCollider(100, 100, 14, 14, 4)
  player.collider:setFixedRotation(true)

  -- Setup inimigo
  enemies = {}

  -- Inserindo barreiras nos objetos (Borders) do tiled
  walls = {}

  if gameMap.layers['Borders'] then
    for i, object in pairs(gameMap.layers['Borders'].objects) do
      local wall = world:newRectangleCollider(object.x, object.y, object.width, object.height)
      wall:setType('static')

      table.insert(walls, wall)
    end
  end
  
end

function love.keypressed(key, unicode)
  if key == "escape" then
    love.event.quit()
  elseif key == 'rctrl' then
    local title = "This is a title"
    local message = "This is some text"
    local buttons = {"OK", "No!", "Help", escapebutton = 2}

    local pressedbutton = love.window.showMessageBox(title, message, buttons)
    if pressedbutton == 1 then
        -- "OK" was pressed
    elseif pressedbutton == 2 then
        -- etc.
    end
  elseif key == 'lctrl' then
    SpawnEnemy()
  end
end

function CheckColision(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

function SpawnEnemy()
  local randomX = love.math.random(1,love.graphics.getWidth())
  local randomY = love.math.random(1,love.graphics.getHeight())

  enemy = {}
  enemy.x = randomX
  enemy.y = randomY
  enemy.speed = 5
  enemy.health = 300
  enemy.hitting = false
  enemy.distance = 0
  enemy.spriteSheet = love.graphics.newImage('resources/sprites/MiniWorldSprites/Characters/Monsters/Orcs/ClubGoblin.png')
  enemy.grid = anim8.newGrid(16, 16, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight())

  -- Criando animações para o enemy de acordo com as linhas/colunas do sprite
  enemy.animations = {}
  enemy.animations.down = anim8.newAnimation(enemy.grid('1-5', 1), 0.2)
  enemy.animations.up = anim8.newAnimation(enemy.grid('1-5', 2), 0.2)
  enemy.animations.left = anim8.newAnimation(enemy.grid('1-5', 3), 0.2)
  enemy.animations.right = anim8.newAnimation(enemy.grid('1-5', 4), 0.2)
  enemy.animations.hit = anim8.newAnimation(enemy.grid('1-3', 8), 0.2)

  enemy.anim = enemy.animations.down

  if (randomY < 240 or randomY > 436) and (randomX < 528 or randomX > 656) then
    table.insert(enemies, enemy)
  end
end

function KillEnemy(index, damage)
  enemies[index].health = enemies[index].health - damage

  if enemies[index].health <= 0 then
    table.remove(enemies, index)
    enemiesKilled = enemiesKilled + 1
    player.health = player.health + 10
  end
end

function DealDamage(damage)
  player.health = player.health - damage
end

function love.update(dt)
  local isPlayerMoving = false
  isPlayerHitting = false

  local isEnemyHitting = false

  local velocityX = 0
  local velocityY = 0

  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()

  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  -- Lidando com movimentação do player
  if love.keyboard.isDown("right", "d") then
    velocityX = player.speed
    player.anim = player.animations.right
    isPlayerMoving = true
    sounds.walking:play()
  elseif love.keyboard.isDown("left", "a") then
    velocityX = player.speed * -1
    player.anim = player.animations.left
    isPlayerMoving = true
    sounds.walking:play()
  elseif love.keyboard.isDown("up", "w") then
    velocityY = player.speed * -1
    player.anim = player.animations.up
    isPlayerMoving = true
    sounds.walking:play()
  elseif love.keyboard.isDown("down", "s") then
    velocityY = player.speed
    player.anim = player.animations.down
    isPlayerMoving = true
    sounds.walking:play()
  elseif love.keyboard.isDown("space") then
    player.anim = player.animations.hit
    isPlayerMoving = true
    isPlayerHitting = true
    sounds.hit:play()
  end
  
  player.anim:update(dt)

  player.x = player.collider:getX() - 6
  player.y = player.collider:getY()

  player.collider:setLinearVelocity(velocityX, velocityY)

  -- Parando animações de bater e andar
  if isPlayerMoving == false then
    player.anim:gotoFrame(2)
    sounds.walking:stop()
  end

  if isPlayerHitting == false and isPlayerMoving == false then
    player.anim = player.animations.down
    sounds.slash:pause()
    sounds.walking:pause()
  end

  -- Camera acompanhando player
  cam:lookAt(player.x * scale, player.y * scale)

  -- Limitand visão da camera para esconder area fora do mapa
  if cam.x < width/2 then
    cam.x = width/2
  end
  
  if cam.y < height/2 then
    cam.y = height/2
  end

  if cam.x > ((mapWidth * scale) - width/2) then
    cam.x = ((mapWidth * scale) - width/2)
  end
  
  if cam.y > ((mapHeight * scale) - height/2) then
    cam.y = ((mapHeight * scale) - height/2)
  end

  -- Executando ações para cada inimigo presente
  for i, enemy in ipairs(enemies) do
    
    -- Fazendo inimigo seguir player
    enemyDirectionX = player.x - enemy.x
    enemyDirectionY = player.y - enemy.y
    
    enemy.distance = math.sqrt(enemyDirectionX * enemyDirectionX + enemyDirectionY * enemyDirectionY)
    
    if enemy.distance < 100 then
      for i, enemy in ipairs(enemies) do
        enemy.x = enemy.x + enemyDirectionX / enemy.distance * 20 * dt
        enemy.y = enemy.y + enemyDirectionY / enemy.distance * 20 * dt
      end

      -- se distância menor que 20, bater no player
      if enemy.distance <= 20 then
        enemy.anim = enemy.animations.hit
        enemy.hitting = true
      else 
        enemy.hitting = false
        enemy.anim = enemy.animations.down
      end
    end
    
    if(isPlayerHitting == true ) then
      if CheckColision(enemy.x, enemy.y, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight(), player.x, player.y, 16, 16) and enemy.distance <= 30 then
        KillEnemy(i, player.damage)
        sounds.slash:play()
      else
        sounds.hit:play()
      end
    end
    
    if enemy.hitting == true then
      if CheckColision(enemy.x, enemy.y, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight(), player.x, player.y, 16, 16) then
        DealDamage(dt * 10)
        sounds.armorHit:play()
      end
    end
    
    enemy.anim:update(dt)
  end

  spawnEnemyTimer = spawnEnemyTimer - (1*dt)

  if spawnEnemyTimer <= 0 then
    spawnEnemyTimer = spawnEnemyTimerMax
    SpawnEnemy()
  end

  if player.health <= 0 then
    sounds.death:play()
  end
  
  world:update(dt)
end

function love.draw()
  cam:attach()
    love.graphics.scale(scale)

    gameMap:drawLayer(gameMap.layers["Ground"])
    gameMap:drawLayer(gameMap.layers["Nature"])
    
    player.anim:draw(player.spriteSheet, player.x, player.y, nil, 1, nil, 2, 8)

    for i, enemy in ipairs(enemies) do
      enemy.anim:draw(enemy.spriteSheet, enemy.x, enemy.y, nil, 1, nil, 2, 8)
      love.graphics.setColor(255,0,0)
      love.graphics.print(math.floor(enemy.health+0.5), enemy.x, enemy.y)
      love.graphics.setColor(255,255,255,255)
    end
    -- world:draw()
    cam:detach()
    
  love.graphics.setColor(255,0,0)
  love.graphics.rectangle('fill', 0, 0, 200, 70, 5, 5, 10 )
  love.graphics.setColor(255,255,255,255)
  love.graphics.print("Saúde: " ..math.floor(player.health+0.5), 0, 0)
  love.graphics.print("Inimigos eliminados: " ..enemiesKilled, 0, 12)
  love.graphics.print("dev: distance: " ..distance, 0, 24)
  love.graphics.print("dev: player hitting: " ..tostring(isPlayerHitting), 0, 36)
  love.graphics.print("dev: X: " ..player.x, 0, 48)
  love.graphics.print("dev: Y: " ..player.y, 0, 60)
  love.graphics.print("dev: Timer: " ..spawnEnemyTimer, 0, 72)

  if player.health <= 0 then
    love.graphics.draw(deathScreen, love.graphics.getWidth()/2, (love.graphics.getHeight() * 2)/2, 0, 1, 1, deathScreen:getWidth()/2, deathScreen:getWidth()/2)
  end
end
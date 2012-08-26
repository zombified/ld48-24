vector = require "libs.hump.vector"
Gamestate = require "libs.hump.gamestate"

local nosound = false

local blobs = {}
local maxblobs = 100
local blobspdmin = 40
local blobspdmax = 90
local blobradiusmin = 2
local blobradiusmax = 30

local playerradius_start = 5
local playerradius = playerradius_start
local playerhit = false
local playername = "Type Your Name"
local highscores = nil
local highscoresfilename = "highscores.txt"
local escapearrowfilename = "assets/textures/arrowup.png"
local escapearrow = nil

local playerColor = {255, 0, 0, 255}
local playerMutedColor = {100, 100, 100, 255}
local enemyColor = {0, 255, 0, 255}
local hitColor = {255, 0, 255}
local negColor = {255, 255, 0}
local hsColor = {0, 128, 255, 255}
local hsTitleColor = {255, 128, 255, 255}
local escapeColor = {77, 77, 77, 255}

local growthAmount = 1
local shrinkAmount = 1
local decayAmount = 1
local decayRate = 2
local curDecay = 0

local starttime = nil
local endtime = nil

local gameover_state = Gamestate.new()
local play_state = Gamestate.new()
local mainmenu_state = Gamestate.new()

local font = nil
local fontwidth = 16
local fontheight = 28

local curos = "windows"


function resetBlob(blob, minx, maxx)
    minx = minx or 830
    maxx = maxx or 900

    blob.x = math.random(minx, maxx)
    blob.y = math.random(1, 600)
    blob.r = math.random(blobradiusmin, blobradiusmax)
    blob.spd = math.random(blobspdmin, blobspdmax)
    blob.hit = false
    blob.isneg = math.random(1, 4)
end

function reset()
    playerradius = playerradius_start
    playerhit = false
    for i = 1, maxblobs do
        resetBlob(blobs[i], 630, 1430)
    end
    starttime = love.timer.getTime()
    endtime = nil
end

function loadHighScores()
    highscores = {}
    if not love.filesystem.exists(highscoresfilename) then
        return
    end
    local scores = love.filesystem.lines(highscoresfilename)
    for score in scores do
        for k, v in string.gmatch(score, "([a-zA-Z0-9 ]+)=([%d\.]+)") do
            table.insert(highscores, {name=k, score=tonumber(v)})
        end
    end
end

function saveHighScores()
    local scores = ""
    local cnt = 1
    for i = 1, #highscores do
        scores = scores .. highscores[i].name .. "=" .. highscores[i].score .. "\n"
    end
    love.filesystem.write(highscoresfilename, scores)
end

function addHighScore(name, score)
    if #highscores <= 0 then
        table.insert(highscores, {name=name, score=score})
        return
    end
    for i = 1, #highscores do
        if score < highscores[i].score then
            table.insert(highscores, i, {name=name, score=score})
            return
        end
    end

    table.insert(highscores, {name=name, score=score})
end

function centerX(text, scale)
    return 400 - ((#text * fontwidth * scale) / 2)
end

function findOS()
    -- very primitive (read, error prone) OS detection
    curos = "windows"
    if love.filesystem.getUserDirectory():sub(1, 6) == "/Users" then
        curos = "mac"
    elseif love.filesystem.exists("/etc/") then
        if love.filesystem.exists("/etc/lsb-release") then
            local lsb = love.filesystem.read("/etc/lsb-release")
            if string.find(lsb, 'Ubuntu') then
                curos = "ubuntu"
            end
        else
            curos = "nix"
        end
    end
end

function drawHighScores(hoffset)
    hoffset = hoffset or 0

    if highscores == nil or #highscores <= 0 then
        return
    end

    love.graphics.setColor(hsTitleColor)
    local text = "DEATHS"
    love.graphics.print(text, centerX(text, .5) + hoffset, 160, 0, .5)

    love.graphics.setColor(hsColor)
    local cnt = 1
    local namestr = ""
    local vpos = nil
    for i = #highscores, 1, -1 do
        if cnt > 10 then
            break
        end
        vpos = 160+(cnt*24)
        namestr = "at "..string.format("%.3f", highscores[i].score).."s old"
        love.graphics.print(highscores[i].name, (400 - ((#highscores[i].name+1)*fontwidth*.5)) + hoffset, vpos, 0, .5)
        love.graphics.print(namestr, 400 + hoffset, vpos, 0, .5)
        cnt = cnt + 1
    end
end

function drawInstructions(hoffset)
    hoffset = hoffset or 0

    --[[
        And thus She spake:
        "EAT! For you shall starve without food."
        "GROW! For the big eat the small."
        "BEWARE! For the golden children are death."
        "LIVE! For life is precious."
        "KITTEN! For cuteness."
           -- excerpt from the book of prophecy
    ]]
    local leftalign = 400 + hoffset
    local spacing = fontheight
    local vstart = 210
    local scale = .5
    love.graphics.setColor({128, 190, 128, 255})
    love.graphics.print("And thus She spake:", leftalign, vstart, 0, scale)
    love.graphics.setColor({255, 255, 128, 255})
    love.graphics.print("\"EAT! For you shall starve without food.\"", leftalign, vstart+(spacing*1), 0, scale)
    love.graphics.print("\"GROW! For the big eat the small.\"", leftalign, vstart+(spacing*2), 0, scale)
    love.graphics.print("\"BEWARE! For the golden children are death.\"", leftalign, vstart+(spacing*3), 0, scale)
    love.graphics.print("\"LIVE! For life is precious.\"", leftalign, vstart+(spacing*4), 0, scale)
    love.graphics.print("\"KITTEN! For cuteness.\"", leftalign, vstart+(spacing*5), 0, scale)
    love.graphics.setColor({128, 190, 128, 255})
    love.graphics.print("  -- excerpt from the book of prophecy", leftalign, vstart+(spacing*6), 0, scale)
end

function drawEscape()
    local text = "To Quit, or press ESC"
    local arrowx = 6
    local textx = 30
    if curos ~= "ubuntu" and curos ~= "mac" then
        arrowx = 778
        textx = 770 - (#text * fontwidth * .25)
    end

    love.graphics.setColorMode("replace")
    love.graphics.draw(escapearrow, arrowx, 3)
    love.graphics.setColorMode("modulate")
    love.graphics.setColor(escapeColor)
    love.graphics.print(text, textx, 8, 0, .25)
end

function loadMusic(filename)
    if nosound then
        return
    end

    song = love.audio.newSource(filename, "stream")
    song:setLooping(true)
    love.audio.play(song)
    return song
end

function playMusic(song)
    if nosound then
        return
    end

    if song ~= nil and (song:isPaused() or song:isStopped()) then
        love.audio.play(song)
    end
end

function stopMusic(song)
    if nosound then
        return
    end

    if song ~= nil and not song:isPaused() and not song:isStopped() then
        love.audio.stop(song)
    end
end

function loadSound(filename)
    if nosound then
        return
    end

    sound = love.audio.newSource(filename, "static")
    song:setLooping(false)
    return sound
end

function playSound(sound)
    if nosound then
        return
    end

    if sound ~= nil and (sound:isPaused() or sound:isStopped()) then
        love.audio.play(sound)
    end
end

function stopSound(sound)
    if nosound then
        return
    end

    if sound ~= nil and not sound:isPaused() and not sound:isStopped() then
        love.audio.stop(sound)
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- menu state
--

local mmalphaincamnt = 5
local mmalphadecamnt = -5
local mmalphainc = mmalphadecamnt
local mmalpharate = .01
local mmalphatotal = 0
local mmtextcolor = {0, 255, 255, 255}
local mmhastypedsomething = false
local mmshowneedname = false
local mmmusicfilename = "assets/music/bu-the-poor-puppies.ogg"
local mmmusic = nil

function mainmenu_state:enter(previous)
    loadHighScores()
    playMusic(mmmusic)
end

function mainmenu_state:leave()
    stopMusic(mmmusic)
end

function mainmenu_state:init()
    mmmusic = loadMusic(mmmusicfilename)
end

function mainmenu_state:update(dt)
    mmalphatotal = mmalphatotal + dt
    if mmalphatotal > mmalpharate then
        mmalphatotal = 0

        mmtextcolor[4] = mmtextcolor[4] + mmalphainc
        if mmtextcolor[4] < 50 then
            mmalphainc = mmalphaincamnt
            mmtextcolor[4] = 50
        elseif mmtextcolor[4] > 255 then
            mmalphainc = mmalphadecamnt
            mmtextcolor[4] = 255
        end
    end
end

function mainmenu_state:draw()
    -- draw a 'muted' player blob
    love.graphics.setColor(playerMutedColor)
    mousex = love.mouse.getX()
    mousey = love.mouse.getY()
    love.graphics.circle("fill", mousex, mousey, playerradius_start)

    -- the escape instruction
    drawEscape()

    -- draw the players name, or ask them to enter a name
    if not mmhastypedsomething then
        love.graphics.setColor({128, 128, 128, 255})
    else
        love.graphics.setColor({255, 255, 255, 255})
    end
    love.graphics.print(playername, centerX(playername, 2), 22, 0, 2)

    -- tell the player how to start the game
    love.graphics.setColor(mmtextcolor)
    local text = "To be born, type your name then click your mouse!"
    love.graphics.print(text, centerX(text, .5), 550, 0, .5)

    -- error message -> a name needs to be entered
    if mmshowneedname then
        love.graphics.setColor({255, 0, 0, 128})
        text = "You need to type something for a name!"
        love.graphics.print(text, centerX(text, 1), 100)
    end

    -- draw the highscores table
    drawHighScores(-200)

    -- draw the instructions
    if highscores == nil or #highscores <= 0 then
        drawInstructions((-43*fontwidth*.5)/2)
    else
        drawInstructions()
    end
end

function mainmenu_state:mousereleased(x, y, button)
    if not mmhastypedsomething then
        mmshowneedname = true
    else
        Gamestate.switch(play_state)
    end
end

function mainmenu_state:keyreleased(key)
    if key == "backspace" or key == "delete" then
        if not mmhastypedsomething then
            playername = ""
        elseif #playername <= 0 then
            playername = ""
        else
            playername = playername:sub(1, (#playername-1))
        end
    end

    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") or love.keyboard.isDown("capslock") then
        key = key:upper()
    end
    if #key == 1 and string.find(key, '[a-zA-Z0-9 ]') then
        if not mmhastypedsomething then
            playername = key
            mmhastypedsomething = true
        elseif #playername <= 10 then
            playername = playername .. key
        end
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Gameover state
--

local goalphaincamnt = 5
local goalphadecamnt = -5
local goalphainc = goalphadecamnt
local goalpharate = .01
local goalphatotal = 0
local gotextcolor = {0, 255, 255, 255}
local reborntextcolor = {255, 255, 255, 255}
local gomusicfilename = "assets/music/bu-feet-and-bears.ogg"
local gomusic = nil

function gameover_state:enter(previous)
    loadHighScores()
    addHighScore(playername, (endtime-starttime))
    saveHighScores()
    playMusic(gomusic)
end

function gameover_state:leave()
    stopMusic(gomusic)
end

function gameover_state:init()
    gomusic = loadMusic(gomusicfilename)
end

function gameover_state:update(dt)
    goalphatotal = goalphatotal + dt
    if goalphatotal > goalpharate then
        goalphatotal = 0

        reborntextcolor[4] = reborntextcolor[4] + goalphainc
        if reborntextcolor[4] < 50 then
            goalphainc = goalphaincamnt
            reborntextcolor[4] = 50
        elseif reborntextcolor[4] > 255 then
            goalphainc = goalphadecamnt
            reborntextcolor[4] = 255
        end
    end
end

function gameover_state:draw()
    local text = ""

    love.graphics.setColor(playerMutedColor)
    mousex = love.mouse.getX()
    mousey = love.mouse.getY()
    love.graphics.circle("fill", mousex, mousey, playerradius_start)

    love.graphics.setColor(gotextcolor)
    text = "Shit, you died!"
    love.graphics.print(text, centerX(text, 1), 22)
    text = "But you did manage to live for " .. string.format("%.3f", (endtime-starttime)) .. "s!"
    love.graphics.print(text, centerX(text, 1), 54)

    love.graphics.setColor(reborntextcolor)
    text = "Click your mouse to get reborn!"
    love.graphics.print(text, centerX(text, .5), 550, 0, .5)

    drawHighScores(-200)
    drawInstructions()
    drawEscape()
end

function gameover_state:mousereleased(x, y, button)
    Gamestate.switch(play_state)
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Play state
--

local kittenimg = nil
local pmusicfilename = "assets/music/bu-the-tense-foot.ogg"
local pmusic = nil
local psuck2filename = "assets/sound/sucking2.ogg"
local psuck2ref = nil
local pdeathfilename = "assets/sound/death.ogg"
local pdeathref = nil

function play_state:enter(previous)
    reset()
    playMusic(pmusic)
end

function play_state:leave()
    stopMusic(pmusic)
end

function play_state:init()
    for i = 1, maxblobs do
        blob = {x=nil, y=nil, r=nil, spd=nil, hit=false, isneg=nil}
        table.insert(blobs, blob)
    end

    starttime = love.timer.getTime()

    if playername == "KITTEN" then
        kittenimg = love.graphics.newImage("assets/textures/kitty.png")
    end

    pmusic = loadMusic(pmusicfilename)
    psuck2 = loadSound(psuck2filename)
    pdeath = loadSound(pdeathfilename)
end

function play_state:update(dt)
    playerhit = false

    local blobv
    local playerv = vector(love.mouse.getX(), love.mouse.getY())
    for i = 1, maxblobs do
        blobs[i].hit = false

        -- update blob position
        blobs[i].x = blobs[i].x - blobs[i].spd * dt

        -- move blob to beginning of flow if off screen or effectively dead
        if blobs[i].x < -35 or blobs[i].r < 1 then
            resetBlob(blobs[i])
        end

        -- check for collision
        blobv = vector(blobs[i].x, blobs[i].y)
        if playerv:dist(blobv) <= blobs[i].r + playerradius then
            blobs[i].hit = true

            if blobs[i].r > playerradius or blobs[i].isneg == 1 then
                -- shrink player
                blobs[i].r = blobs[i].r + growthAmount
                playerradius = playerradius - shrinkAmount
            else
                -- grow player
                blobs[i].r = blobs[i].r - shrinkAmount
                playerradius = playerradius + growthAmount
            end
            playSound(psuck2)
        end
    end

    curDecay = curDecay + dt
    if curDecay > decayRate then
        curDecay = 0
        playerradius = playerradius - decayAmount
    end

    if playerradius < 1 and endtime == nil then
        playSound(pdeath)
        endtime = love.timer.getTime()
        Gamestate.switch(gameover_state)
    end
end

function play_state:draw()
    if kittenimg ~= nil then
        love.graphics.setColorMode("replace")
        love.graphics.draw(kittenimg, 1, 580)
        love.graphics.setColorMode("modulate")
    end

    drawEscape()

    mousex = love.mouse.getX()
    mousey = love.mouse.getY()
    if not playerhit then
        love.graphics.setColor(playerColor)
    else
        love.graphics.setColor(hitColor)
    end
    love.graphics.circle("fill", mousex, mousey, playerradius)

    for i = 1, maxblobs do
        if blobs[i].r >= 1 then
            if blobs[i].hit then
                love.graphics.setColor(hitColor)
            elseif blobs[i].isneg == 1 then
                love.graphics.setColor(negColor)
            else
                love.graphics.setColor(enemyColor)
            end
            love.graphics.circle("fill", blobs[i].x, blobs[i].y, blobs[i].r)
        end
    end
end

function play_state:keyreleased(key)
    if key == "r" then
        Gamestate.switch(play_state)
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- LOVE functions
--

function love.load()
    for i = 1, #arg do
        if arg[i]:lower() == "nosound" then
            nosound = true
        end
    end

    love.mouse.setVisible(false)

    font = love.graphics.newImageFont("assets/fonts/herkld-28.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.!:;,/\\%?'\"[] +-")
    love.graphics.setFont(font)

    findOS()

    escapearrow = love.graphics.newImage(escapearrowfilename)

    Gamestate.registerEvents()
    Gamestate.switch(mainmenu_state)
end


function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    end
end
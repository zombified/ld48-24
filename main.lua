vector = require "libs.hump.vector";

local blobs = {};
local maxblobs = 100;
local blobspdmin = 40;
local blobspdmax = 90;
local blobradiusmin = 2;
local blobradiusmax = 30;

local playerradius_start = 5
local playerradius = playerradius_start;
local playerhit = false;

local playerColor = {255, 0, 0, 255};
local enemyColor = {0, 255, 0, 255};
local hitColor = {255, 0, 255};
local negColor = {255, 255, 0};

local growthAmount = 1;
local shrinkAmount = 1;
local decayAmount = 1;
local decayRate = 2;
local curDecay = 0;

local starttime = nil;
local endtime = nil;



function resetBlob(blob, minx, maxx)
    minx = minx or 830;
    maxx = maxx or 900;

    blob.x = math.random(minx, maxx);
    blob.y = math.random(1, 600);
    blob.r = math.random(blobradiusmin, blobradiusmax);
    blob.spd = math.random(blobspdmin, blobspdmax);
    blob.hit = false
    blob.isneg = math.random(1, 4);
end

function reset()
    playerradius = playerradius_start;
    playerhit = false;
    for i = 1, maxblobs do
        resetBlob(blobs[i], 630, 1430);
    end
    starttime = love.timer.getTime();
    endtime = nil;
end




function love.load()
    love.mouse.setVisible(false);

    for i = 1, maxblobs do
        blob = {x=nil, y=nil, r=nil, spd=nil, hit=false, isneg=nil};
        resetBlob(blob, 630, 1430);
        table.insert(blobs, blob);
    end

    starttime = love.timer.getTime()
end


function love.update(dt)
    if playerradius < 1 then
        return;
    end

    playerhit = false;

    local blobv;
    local playerv = vector(love.mouse.getX(), love.mouse.getY());
    for i = 1, maxblobs do
        blobs[i].hit = false;

        -- update blob position
        blobs[i].x = blobs[i].x - blobs[i].spd * dt;

        -- move blob to beginning of flow if off screen or effectively dead
        if blobs[i].x < -35 or blobs[i].r < 1 then
            resetBlob(blobs[i]);
        end

        -- check for collision
        blobv = vector(blobs[i].x, blobs[i].y);
        if playerv:dist(blobv) <= blobs[i].r + playerradius then
            blobs[i].hit = true;

            if blobs[i].r > playerradius or blobs[i].isneg == 1 then
                -- shrink player
                blobs[i].r = blobs[i].r + growthAmount;
                playerradius = playerradius - shrinkAmount;
            else
                -- grow player
                blobs[i].r = blobs[i].r - shrinkAmount;
                playerradius = playerradius + growthAmount;
            end
        end
    end

    curDecay = curDecay + dt;
    if curDecay > decayRate then
        curDecay = 0;
        playerradius = playerradius - decayAmount;
    end

    if playerradius < 1 and endtime == nil then
        endtime = love.timer.getTime();
    end
end


function love.draw()
    if playerradius < 1 then
        love.graphics.print("Shit, you died!", 350, 92);
        love.graphics.print("But you did manage to live for " .. (endtime-starttime) .. "s!", 280, 124);
        return;
    end


    mousex = love.mouse.getX();
    mousey = love.mouse.getY();
    if not playerhit then
        love.graphics.setColor(playerColor);
    else
        love.graphics.setColor(hitColor);
    end
    love.graphics.circle("fill", mousex, mousey, playerradius);

    for i = 1, maxblobs do
        if blobs[i].r >= 1 then
            if blobs[i].hit then
                love.graphics.setColor(hitColor);
            elseif blobs[i].isneg == 1 then
                love.graphics.setColor(negColor);
            else
                love.graphics.setColor(enemyColor);
            end
            love.graphics.circle("fill", blobs[i].x, blobs[i].y, blobs[i].r);
        end
    end
end


function love.keyreleased(key)
    if key == "escape" then
        love.event.quit();
    elseif key == "r" then
        reset()
    end
end
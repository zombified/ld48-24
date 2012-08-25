vector = require "libs.hump.vector";

local blobs = {};
local maxblobs = 100;
local blobspdmin = 40;
local blobspdmax = 90;
local blobradiusmin = 2;
local blobradiusmax = 15;

local playerradius = 10;
local playerhit = false;

local playerColor = {255, 0, 0, 255};
local enemyColor = {0, 255, 0, 255};
local hitColor = {255, 0, 255};


function love.load()
    love.mouse.setVisible(false);

    for i = 1, maxblobs do
        table.insert(blobs, {x=math.random(1, 800),
                             y=math.random(1, 600),
                             r=math.random(blobradiusmin, blobradiusmax),
                             spd=math.random(blobspdmin, blobspdmax),
                             hit=false});
    end
end


function love.update(dt)
    playerhit = false;

    local blobv;
    local playerv = vector(love.mouse.getX(), love.mouse.getY());
    for i = 1, maxblobs do
        blobs[i].hit = false;

        -- update blob position
        blobs[i].x = blobs[i].x - blobs[i].spd * dt;
        if blobs[i].x < -35 then
            blobs[i].x = math.random(830, 900);
            blobs[i].y = math.random(1, 600);
            blobs[i].r = math.random(blobradiusmin, blobradiusmax);
            blobs[i].spd = math.random(blobspdmin, blobspdmax);
        end

        -- check for collision
        blobv = vector(blobs[i].x, blobs[i].y);
        if playerv:dist(blobv) <= blobs[i].r + playerradius then
            blobs[i].hit = true;
        end
    end
end


function love.draw()
    mousex = love.mouse.getX();
    mousey = love.mouse.getY();
    if not playerhit then
        love.graphics.setColor(playerColor);
    else
        love.graphics.setColor(hitColor);
    end
    love.graphics.circle("fill", mousex, mousey, playerradius);

    for i = 1, maxblobs do
        if not blobs[i].hit then
            love.graphics.setColor(enemyColor);
        else
            love.graphics.setColor(hitColor);
        end
        love.graphics.circle("fill", blobs[i].x, blobs[i].y, blobs[i].r);
    end
end


function love.keyreleased(key)
    if key == "escape" then
        love.event.quit();
    end
end
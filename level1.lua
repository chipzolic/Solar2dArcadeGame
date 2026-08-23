local composer = require("composer")
local scene = composer.newScene()

local spawnTimer
local hazardTimer

----------------------------------------------------
-- SCENE CREATE
----------------------------------------------------
function scene:create(event)
    local sceneGroup = self.view

    local centerX = display.contentCenterX
    local centerY = display.contentCenterY
    local screenW = display.contentWidth
    local screenH = display.contentHeight

    local bg = display.newImage( sceneGroup, "assets/background.png", display.contentCenterX, display.contentCenterY )

end

----------------------------------------------------
-- SCENE SHOW
----------------------------------------------------
function scene:show(event)

    local sceneGroup = self.view

    if event.phase == "did" then

        gameActive = true

        -- Forward declaring these here, otherwise some errors on game restart.
        local collectibles = {}
        local hazards = {}

        local screenW = display.contentWidth
        local screenH = display.contentHeight
        local collectible_speed = 5
        local score = 0
        local scoreTextLbl = display.newText(sceneGroup, "Score: ", 55, 30, native.systemFontBold, 18)
        local scoreTextValue = display.newText(sceneGroup, score, 95, 30, native.systemFontBold, 18)



        local function hitFlash(isHazard) --- Passing in a boolean check to this, to control the flash colour, red or green.
            local flash = display.newRect(sceneGroup,
                display.contentCenterX,
                display.contentCenterY,
                display.contentWidth,
                display.contentHeight)

                --local function flashScreen(isHazard)
                if isHazard then
                    flash:setFillColor(1, 0, 0) -- Red
                else
                    flash:setFillColor(0, 1, 0) -- Green
                end

                flash.alpha = 0.5

                transition.to(flash, {
                    alpha = 0,
                    time = 200
                })
                

            local function screenShake(sceneGroup)
                local originalX = sceneGroup.x
                transition.to(sceneGroup, { x = originalX + 8, time = 50 })
                transition.to(sceneGroup, { x = originalX - 8, time = 50, delay = 50 })
                transition.to(sceneGroup, { x = originalX, time = 50, delay = 100 })
            end

            screenShake(sceneGroup)
        end
        



        ------------------------------------------------
        -- PLAYER
        ------------------------------------------------
        local player = display.newImage( sceneGroup, "assets/player_ship.png", display.contentCenterX, display.contentCenterY + 100 )
        player:scale(0.15, 0.15)

        local moveDirection = 0
        local speed = 6

        -------------------------------------------------------------------------------------------------------------------------------------
        -- Simple left and right movement on touching either side of the screen. The function below stores the movement direction and moves every frame, to keep movement smooth.
        -------------------------------------------------------------------------------------------------------------------------------------
        local function touchListener(event)

            -- 'IS VALID' Check for the Game Active Boolean Variable.
            if not gameActive then return end

            if event.phase == "began" or event.phase == "moved" then

                if event.x < display.contentCenterX then
                    moveDirection = -1
                else
                    moveDirection = 1
                end

            elseif event.phase == "ended" or event.phase == "cancelled" then
                moveDirection = 0
            end
            return true
        end
        Runtime:addEventListener("touch", touchListener)

        ------------------------------------------------
        -- Main Game Loop.
        ------------------------------------------------
        local function gameLoop()

            -- 'IS VALID' Check for the Game Active Boolean Variable.
            if not gameActive then return end

            player.x = player.x + (moveDirection * speed)
            ----------------------------------
            -- Prevent leaving sides of playable area screen, simple.
            ----------------------------------
            if player.x >= 460 then 
                player.x = 458
            elseif player.x <= 19 then
                player.x = 20
            end
        end
        Runtime:addEventListener("enterFrame", gameLoop)
  
        ---------------------------------------------------------------------------------
        -- SPAWN COLLECTIBLE.
        ---------------------------------------------------------------------------------
        local function spawn_collectible()

            -- 'IS VALID' Check for the Game Active Boolean Variable.
            if not gameActive then return end

            local collectible = display.newImage(sceneGroup, "assets/star_collectible.png", display.contentCenterX + math.random(-125, 175), display.contentCenterY - 125)
            collectible:scale(0.1,0.1)
            table.insert(collectibles, collectible)

        end
        spawn_collectible()


        function move_collectible()

            if not gameActive then return end

            -- Loop backwards because we may remove objects.
            for i = #collectibles, 1, -1 do

                local collectible = collectibles[i]
                collectible.y = collectible.y + 2
                ------------------------------------------------
                -- REMOVE IF OFF SCREEN
                ------------------------------------------------
                if collectible.y > display.contentHeight + 50 then
                    display.remove(collectible)
                    table.remove(collectibles, i)
                end
            end
        end
        Runtime:addEventListener("enterFrame", move_collectible)


        
        --------------------------------
        -- SCORE INCREASE.
        --------------------------------
        function score_increase(event)
            score = score + 1
            scoreTextValue.text = score
            --media.playSound( soundfile [, baseDir] [, loop] )
        end

        --------------------------------
        -- EAT COLLECTIBLE
        --------------------------------
        function eat_collectible()

            if not gameActive then return end

            for i = #collectibles, 1, -1 do

                local collectible = collectibles[i]

                local dx = collectible.x - player.x
                local dy = collectible.y - player.y

                local distance = math.sqrt(dx*dx + dy*dy)

                if distance <= 30 then

                    score_increase()

                    display.remove(collectible)
                    table.remove(collectibles, i)

                    hitFlash(false) --- Beacuse passing false here means the isHazard boolean sets to False, and thereby the flash is Not red, instead it's green!

                end
            end
        end
        Runtime:addEventListener("enterFrame", eat_collectible)


        ---------------------------------------------------------------------------------
        -- RESTART GAME FUNCTION.
        ---------------------------------------------------------------------------------
        function restart_game(event)

            --- All of this cleanup, removing event listeners, canceling timers, is necessary in this restart function because...
            --- If I don't add it here, it gives me an error on fresh restart...
            --- Just adding it on scene destroy is not enough.
            gameActive = false

            Runtime:removeEventListener("enterFrame", gameLoop)
            Runtime:removeEventListener("touch", touchListener)

            Runtime:removeEventListener("enterFrame", move_collectible)
            Runtime:removeEventListener("enterFrame", eat_collectible)

            Runtime:removeEventListener("enterFrame", move_hazard)
            Runtime:removeEventListener("enterFrame", eat_hazard)

            if spawnTimer then
                timer.cancel(spawnTimer)
            end

            if hazardTimer then
                timer.cancel(hazardTimer)
            end

            composer.removeScene("level1")

                ------------------------------------------------
                -- REMOVE ALL COLLECTIBLES
                ------------------------------------------------
                for i = #collectibles, 1, -1 do
                    display.remove(collectibles[i])
                    collectibles[i] = nil
                end

                ------------------------------------------------
                -- REMOVE ALL HAZARDS
                ------------------------------------------------
                for i = #hazards, 1, -1 do
                    display.remove(hazards[i])
                    hazards[i] = nil
                end

            composer.gotoScene("level1", {effect="fade", time=200})
        end

        ---------------------------------------------------------------------------------
        -- GAME OVER FUCTION.
        ---------------------------------------------------------------------------------
        function game_over(event)
            gameActive = false

            local overlay = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, screenW, display.contentHeight)
            overlay:setFillColor(1, 0, 0)

            display.newText(sceneGroup, "GAME OVER!", display.contentCenterX, display.contentCenterY - 30,
                native.systemFontBold, 36)

            --- Shows your score on the game over screen.
            display.newText(sceneGroup, "Your Total Score: " .. score, display.contentCenterX, display.contentCenterY + 80,
                native.systemFontBold, 26)

            local tap = display.newText(sceneGroup, "Tap to restart",
                display.contentCenterX, display.contentCenterY + 30,
                native.systemFontBold, 26)

            overlay:addEventListener("tap", restart_game)

        end

        ---------------------------------------------------------------------------------
        -- SPAWN HAZARDS.
        ---------------------------------------------------------------------------------
        local function spawn_hazard()

            -- 'IS VALID' Check for the Game Active Boolean Variable.
            if not gameActive then return end

            local hazard = display.newImage(sceneGroup, "assets/hazard_alien.png", display.contentCenterX + math.random(-125,175), display.contentCenterY - 125)
            hazard:scale(0.2,0.2)
            table.insert(hazards, hazard)

        end

        --------------------------------
        -- MOVE HAZARD.
        --------------------------------
        function move_hazard()

            if not gameActive then return end

            for i = #hazards, 1, -1 do

                local hazard = hazards[i]
                hazard.y = hazard.y + 5
                ------------------------------------------------
                -- REMOVE IF OFF SCREEN
                ------------------------------------------------
                if hazard.y > display.contentHeight + 50 then
                    display.remove(hazard)
                    table.remove(hazards, i)
                end
            end
        end
        Runtime:addEventListener("enterFrame", move_hazard)

        --------------------------------
        -- EAT HAZARD
        --------------------------------
        function eat_hazard()
            if not gameActive then return end

            for i = #hazards, 1, -1 do

                local hazard = hazards[i]

                local dx = hazard.x - player.x
                local dy = hazard.y - player.y

                local distance = math.sqrt(dx*dx + dy*dy)

                if distance <= 30 then
                    display.remove(hazard)
                    table.remove(hazards, i)
                    hitFlash(true) ----- Passing a true boolean here, this means that the isHazard boolean in Hitflash function is passed as true, which means it shows the RED flash, not the green flash!
                    game_over()
                    return
                end
            end
        end
        Runtime:addEventListener("enterFrame", eat_hazard)

        ------------------------------------------------
        -- Timers.
        ------------------------------------------------
        spawnTimer = timer.performWithDelay(2500, spawn_collectible, 0)
        hazardTimer = timer.performWithDelay(2200, spawn_hazard, 0)

    end
end


----------------------------------------------------
-- CLEANUP
----------------------------------------------------
function scene:hide(event)
    if event.phase == "did" then

        if spawnTimer then timer.cancel(spawnTimer) end
        if hazardTimer then timer.cancel(hazardTimer) end

        Runtime:removeEventListener("enterFrame", gameLoop)
        Runtime:removeEventListener("touch", onTouch)

        Runtime:removeEventListener("enterFrame", move_collectible)
        Runtime:removeEventListener("enterFrame", eat_collectible)
        Runtime:removeEventListener("enterFrame", move_hazard)
        Runtime:removeEventListener("enterFrame", eat_hazard)

    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene

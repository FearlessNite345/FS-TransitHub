local isServiceActive = false
local isRushed = false

local function spawnVehicleLogic(playerCoords, vehicleModel, driverPed, plate)
    -- Define the distance at which the vehicle should spawn away from the player
    local minSpawnDistance = 0
    local maxSpawnDistance = 250.0

    -- Get a random offset from the player's position
    local offsetX = RandomLimited(minSpawnDistance, maxSpawnDistance, 100)
    local offsetY = RandomLimited(minSpawnDistance, maxSpawnDistance, 100)
    local offsetZ = 0.0 -- You can adjust this if you need the vehicle to spawn at different heights

    -- Calculate the spawn position
    local spawnPos = vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z + offsetZ)

    -- Get closest road node to the spawn position
    local _, roadPos, heading = GetClosestVehicleNodeWithHeading(spawnPos.x, spawnPos.y, spawnPos.z, 0, 3.0, 0) -- GetClosestVehicleNode(spawnPos.x, spawnPos.y, spawnPos.z, 0, 100.0, 2.5)

    local vehicleModelHash = GetHashKey(vehicleModel)
    local pedModelHash = GetHashKey(driverPed)
    SetupModel(vehicleModelHash)
    SetupModel(pedModelHash)

    -- Spawn the car
    local vehicle = CreateVehicle(vehicleModelHash, roadPos.x, roadPos.y, roadPos.z, heading, true, false)
    local vehicleBlip = AddBlipForEntity(vehicle)
    SetBlipSprite(vehicleBlip, 198)
    SetBlipDisplay(vehicleBlip, 2)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipColour(vehicleBlip, 5)
    SetVehicleNumberPlateText(vehicle, plate)

    -- Create NPC driver
    local driver = CreatePedInsideVehicle(vehicle, 26, pedModelHash, -1, true, true)

    if not DoesEntityExist(vehicle) then
        return nil, nil, nil
    end

    return vehicle, vehicleBlip, driver
end

local function cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, isTrueCancel)
    if isTrueCancel then
        StopCurrentPlayingSpeech(driver)
        PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_GET_OUT_EARLY", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)
    end

    TaskVehicleTempAction(driver, vehicle, 1, 30)
    TaskLeaveVehicle(playerPed, vehicle, 0)

    while GetVehiclePedIsIn(playerPed, false) == vehicle do
        Citizen.Wait(500)
    end

    -- Remove the blip from the vehicle
    RemoveBlip(vehicleBlip)
    RemoveBlip(radiusBlip)
    SetEntityAsNoLongerNeeded(vehicle)
    SetEntityAsNoLongerNeeded(driver)
    SetBlockingOfNonTemporaryEvents(driver, false)
    ClearVehicleTasks(vehicle)

    isServiceActive = false
    isRushed = false

    if isTrueCancel then
        DrawNotification2D("Ride canceled", 2, "r")
    else
        DrawNotification2D("You have arrived", 2, "g")
    end

    Citizen.Wait(5000)

    DeleteEntity(driver)
    DeleteEntity(vehicle)
end

local function getSeatPosition(playerCoords, vehicle, seat)
    local seatCoords = GetWorldPositionOfEntityBone(vehicle,
        GetEntityBoneIndexByName(vehicle, seat))
    return #(playerCoords - seatCoords)
end

local function startAI(vehicleModel, driverModel, plate, rideType)
    if isServiceActive then
        DrawNotification2D("Service already active", 5, "r")
        return
    end

    local playerPed = PlayerPedId()

    local destinationCoords = GetEntityCoords(playerPed, false)

    local vehicle, vehicleBlip, driver = spawnVehicleLogic(destinationCoords, vehicleModel, driverModel, plate)

    if vehicle ~= nil and vehicleBlip ~= nil and driver ~= nil then
        isServiceActive = true

        SetBlockingOfNonTemporaryEvents(driver, true)
        SetEntityInvincible(driver, true)

        local driverStopRange = 2.0 -- this is only to tell the driver to get as close as possible the stopRange is the real one
        local stopRange = 10.0
        local drivingStyle = 786603
        local rushedDrivingStyle = 1074528805
        local speedToPlayer = 15.0
        local speedToDestination = 28.0
        local rushedSpeed = 37.0

        local radiusBlip = AddBlipForRadius(destinationCoords.x, destinationCoords.y, destinationCoords.z,
            Config.cancelRadius)
        SetBlipColour(radiusBlip, 5)
        SetBlipAlpha(radiusBlip, 128)

        SetDriverAbility(driver, 1.0)
        SetDriverAggressiveness(driver, 0.0)
        TaskVehicleDriveToCoord(driver, vehicle, destinationCoords.x, destinationCoords.y, destinationCoords.z,
            speedToPlayer,
            0.0, GetEntityModel(vehicle), rushedDrivingStyle, driverStopRange, 1.0)

        while #(GetEntityCoords(vehicle, false) - GetEntityCoords(playerPed, false)) > stopRange do
            Citizen.Wait(0)

            local distance = #(GetEntityCoords(vehicle, false) - GetEntityCoords(playerPed, false))
            DrawText2D(0.5, 0.8, 'Distance: ' .. tonumber(string.format("%.2f", distance)), 0.6, true)
            DrawText2D(0.5, 0.85, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6, true)

            local cancelDistance = #(GetEntityCoords(playerPed, false) - destinationCoords)
            if cancelDistance > Config.cancelRadius then
                DrawNotification2D("Walked outside radius. Cancelling...", 2, "r")
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end
        end

        ClearVehicleTasks(vehicle)
        TaskVehicleTempAction(driver, vehicle, 1, 30)

        while true do
            Citizen.Wait(0)
            DrawText2D(0.5, 0.8, '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~] Enter vehicle', 0.6, true)
            DrawText2D(0.5, 0.85, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end

            if IsControlJustPressed(0, Config.getInKey) then
                local seats = {
                    [1] = { name = "seat_dside_r", index = 1 }, -- Left back seat
                    [2] = { name = "seat_pside_r", index = 2 }, -- Right back seat
                }

                local closestSeat = nil
                local closestDistance = 9999.0

                for _, seatInfo in pairs(seats) do
                    local seatName = seatInfo.name
                    local seatIndex = seatInfo.index
                    if IsVehicleSeatFree(vehicle, seatIndex) then
                        local distance = getSeatPosition(GetEntityCoords(playerPed, false), vehicle, seatName)
                        if distance < closestDistance then
                            closestSeat = seatIndex
                            closestDistance = distance
                        end
                    end
                end

                -- If any seat is available, ask the player to enter the closest one
                if closestSeat ~= nil then
                    SetTaxiLights(vehicle, false)
                    SetVehicleFixed(vehicle)
                    TaskEnterVehicle(playerPed, vehicle, 10000, closestSeat, 2.0, 1, 0)
                    RemoveBlip(radiusBlip)
                else
                    DrawNotification2D("No seats available. Cancelling...", 2, "r")
                    cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                end

                break
            end
        end

        while not IsPedInAnyVehicle(playerPed, false) and GetVehiclePedIsIn(playerPed, false) ~= vehicle do
            Citizen.Wait(0)
        end

        StopCurrentPlayingSpeech(driver)
        PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_WHERE_TO", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)

        local waypoint = nil
        while true do
            Citizen.Wait(0)
            if IsWaypointActive() then
                waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                break
            end

            DrawText2D(0.5, 0.85, '~w~Set a waypoint', 0.6, true)
            DrawText2D(0.5, 0.9, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end

            if not IsPedInAnyVehicle(playerPed, false) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end
        end

        if waypoint == nil then
            return
        end

        local z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)

        while true do
            Citizen.Wait(0)

            DrawText2D(0.5, 0.85, '~w~[~g~' .. GetKeyStringFromKeyID(Config.startRide) .. '~w~] Start Ride', 0.6, true)
            DrawText2D(0.5, 0.9, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6, true)

            if IsControlJustPressed(0, Config.startRide) then
                StopCurrentPlayingSpeech(driver)
                PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_BEGIN_JOURNEY", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)
                break
            end

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end
        end

        TaskVehicleDriveToCoord(driver, vehicle, waypoint.x, waypoint.y, z, speedToDestination, 30.0,
            GetEntityModel(vehicle),
            drivingStyle, driverStopRange, 1.0)

        local timerMax = 2250
        local timer = timerMax

        while IsWaypointActive() and GetVehiclePedIsIn(playerPed, false) == vehicle do
            Citizen.Wait(0)

            if Config.rideBanter then
                timer -= 1

                if timer <= 0 then
                    StopCurrentPlayingSpeech(driver)
                    PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_BANTER", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)
                    timer = timerMax
                end
            end

            local distance = #(GetEntityCoords(vehicle, false) - waypoint)
            if not isRushed then
                DrawText2D(0.5, 0.75, 'Distance: ' .. tonumber(string.format("%.2f", distance)), 0.6, true)
                DrawText2D(0.5, 0.8, '~w~[~g~' .. GetKeyStringFromKeyID(Config.rushKey) .. '~w~] Hurry Up', 0.6, true)
                DrawText2D(0.5, 0.85,
                    '~w~[~g~' .. GetKeyStringFromKeyID(Config.changeDestKey) .. '~w~] Change Destination', 0.6, true)
                DrawText2D(0.5, 0.9, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6,
                    true)
            else
                DrawText2D(0.5, 0.8, 'Distance: ' .. tonumber(string.format("%.2f", distance)), 0.6, true)
                DrawText2D(0.5, 0.85,
                    '~w~[~g~' .. GetKeyStringFromKeyID(Config.changeDestKey) .. '~w~] Change Destination', 0.6, true)
                DrawText2D(0.5, 0.9, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6,
                    true)
            end

            if IsControlJustPressed(0, Config.rushKey) and not isRushed then
                StopCurrentPlayingSpeech(driver)
                PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_SPEED_UP", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)
                isRushed = true

                SetDriveTaskDrivingStyle(driver, rushedDrivingStyle)
                SetDriveTaskCruiseSpeed(driver, rushedSpeed)
                SetDriverAggressiveness(driver, 1.0)
            end

            if IsControlJustPressed(0, Config.changeDestKey) then
                StopCurrentPlayingSpeech(driver)
                PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_CHANGE_DEST", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)

                ClearVehicleTasks(vehicle)
                TaskVehicleTempAction(driver, vehicle, 1, 30)
                DeleteWaypoint()

                while not IsWaypointActive() do
                    Citizen.Wait(0)
                    DrawText2D(0.5, 0.85, '~w~Set a new waypoint', 0.6, true)
                    DrawText2D(0.5, 0.9, '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] Cancel Ride', 0.6,
                        true)

                    if IsControlJustPressed(0, Config.cancelKey) then
                        cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                        return
                    end
                end

                isRushed = false
                waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)

                TaskVehicleDriveToCoord(driver, vehicle, waypoint.x, waypoint.y, z, speedToDestination, 30.0,
                    GetEntityModel(vehicle),
                    drivingStyle, driverStopRange, 1.0)
            end

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, true)
                return
            end
        end

        StopCurrentPlayingSpeech(driver)
        PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_ARRIVE_AT_DEST", "A_M_M_EASTSA_02_LATINO_FULL_01", "SPEECH_PARAMS_FORCE_NORMAL", false)

        cancelRide(driver, vehicle, playerPed, vehicleBlip, radiusBlip, false)
    else
        print("Error creating vehicle")
        DrawNotification2D("Error creating vehicle", 3, "r")
    end
end

RegisterCommand("callride", function(source, args, rawCommand)
    if args[1] == 'taxi' then
        startAI(Config.taxiVehicles[math.random(1, #Config.taxiVehicles)], "a_m_y_stlat_01", "TAXI", "taxi")
    elseif args[1] == 'swift' then
        startAI(Config.swiftVehicles[math.random(1, #Config.swiftVehicles)], "a_m_y_stlat_01", "SWIFT", "swift")
    elseif args[1] == 'swiftluxury' then
        startAI(Config.SwiftLuxuryVehicles[math.random(1, #Config.SwiftLuxuryVehicles)], "a_m_m_business_01", "SWIFT",
            "swiftluxury")
    else
        print("Invalid type given")
    end
end, false)

TriggerEvent('chat:addSuggestion', '/callride', 'Will call a ride vehicle to your location', {
    { name = "TYPE", help = "taxi, swift, swiftluxury" },
})

local radiusBlip
local waypoint
local pilot
local heli
local heliBlip
local noMoney = false
local realCost = 0
local estimatedCost = 0
local heliSpeedToPlayer = 30.0
local heliSpeedToWaypoint = 50.0

local function calculateRideCost(yourCoords, destCoords)
    estimatedCost = (Config.costPerMileHeli * math.floor(#(yourCoords - destCoords) / 1609)) * 5
end

local function endRide(playerPed)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(heli))

    if Config.useMoney then
        TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), realCost)
    end

    TaskLeaveVehicle(playerPed, heli, 0)
    TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

    while GetVehiclePedIsIn(playerPed, false) == heli do
        Citizen.Wait(500)
    end

    -- Remove the blip from the vehicle
    RemoveBlip(heliBlip)
    RemoveBlip(radiusBlip)
    SetEntityAsNoLongerNeeded(pilot)
    SetEntityAsNoLongerNeeded(heli)
    SetBlockingOfNonTemporaryEvents(pilot, false)
    ClearVehicleTasks(heli)

    IsServiceActive = false
    IsCooldownActive = true

    if Config.useMoney then
        DrawNotification2D(Config.Locales["chargedRideCost"] .. realCost, 2, "g")
    end
    DrawNotification2D(Config.Locales["arrivedDestination"], 2, "g")

    Citizen.Wait(3000)

    DeleteEntity(pilot)
    DeleteEntity(heli)

    heli = nil
    heliBlip = nil
    radiusBlip = nil
    pilot = nil
    IsCooldownActive = false
    noMoney = false
end

local function cancelRide(playerPed, isCancelRadiusTrigger)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(heli))

    if Config.useMoney then
        if not noMoney then
            TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), realCost)
        end
    end

    if not isCancelRadiusTrigger then
        TaskLeaveVehicle(playerPed, heli, 0)
        TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

        while GetVehiclePedIsIn(playerPed, false) == heli do
            Citizen.Wait(500)
        end
    end

    -- Remove the blip from the vehicle
    RemoveBlip(heliBlip)
    RemoveBlip(radiusBlip)
    SetEntityAsNoLongerNeeded(pilot)
    SetEntityAsNoLongerNeeded(heli)
    SetBlockingOfNonTemporaryEvents(pilot, false)
    ClearVehicleTasks(heli)

    IsServiceActive = false
    IsCooldownActive = true

    if noMoney and Config.useMoney then
        DrawNotification2D(Config.Locales["noMoney"], 2, "r")
    else
        if Config.useMoney then
            DrawNotification2D(Config.Locales["chargedRideCost"] .. realCost, 2, "g")
        end
        DrawNotification2D(Config.Locales["rideCancel"], 2, "r")
    end

    Citizen.Wait(3000)

    DeleteEntity(pilot)
    DeleteEntity(heli)

    heli = nil
    heliBlip = nil
    radiusBlip = nil
    pilot = nil
    IsCooldownActive = false
    noMoney = false
end

local function spawnHeliLogic(playerCoords, heliModel, pilotPed)
    -- Get a random offset from the player's position
    local maxSpawnDistance = 1000.0

    local offsetX = math.random(250, maxSpawnDistance)
    local offsetY = math.random(250, maxSpawnDistance)
    local offsetZ = 0.0 -- You can adjust this if you need the vehicle to spawn at different heights

    -- Calculate the spawn position
    local spawnPos = vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z + offsetZ)

    local heliModelHash = GetHashKey(heliModel)
    local pedModelHash = GetHashKey(pilotPed)
    SetupModel(heliModelHash)
    SetupModel(pedModelHash)

    -- Spawn the heli
    heli = CreateVehicle(heliModelHash, spawnPos.x, spawnPos.y, spawnPos.z + 300.0, 0.0, true, false)
    heliBlip = AddBlipForEntity(heli)
    SetVehicleLights(heli, 2)

    SetBlipSprite(heliBlip, 64)
    SetBlipDisplay(heliBlip, 2)
    SetBlipScale(heliBlip, 0.8)
    SetBlipColour(heliBlip, 3)

    -- Create NPC pilot
    pilot = CreatePedInsideVehicle(heli, 26, pedModelHash, -1, true, true)

    if not DoesEntityExist(heli) then
        heli, heliBlip, pilot = nil, nil, nil
    end
end

local function continueAirService()
    local playerPed = PlayerPedId()

    while true do
        Citizen.Wait(0)

        if Config.useMoney then
            ShowInfo("Estimated Cost: " .. estimatedCost, 0.75, 0.5)
        end

        if not IsPedInAnyHeli(playerPed) then
            cancelRide(playerPed, false)
            break
        end

        DrawText2D(0.5, 0.85,
            '~w~[~g~' .. GetKeyStringFromKeyID(Config.startRide) .. '~w~]' .. Config.Locales["startRide"], 0.6, true)
        DrawText2D(0.5, 0.9,
            '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)

        if IsControlJustPressed(0, Config.startRide) then
            TriggerServerEvent(
                "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(heli))
            break
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end
    end

    local z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)

    TaskHeliMission(pilot, heli, 0, 0, waypoint.x, waypoint.y, z + 50.0, 4, heliSpeedToWaypoint, -1.0,
        -1.0, 10, 10,
        5.0, 32)

    local previousPosition = GetEntityCoords(heli, false).xy -- Store the initial position

    local totalDistanceMeters = 0.0

    while IsVehicleOnAllWheels(heli) do
        Citizen.Wait(500)
    end

    while not IsVehicleOnAllWheels(heli) do
        Citizen.Wait(0)

        if not IsPedInAnyHeli(playerPed) then
            cancelRide(playerPed, false)
            break
        end

        local heliCoords = GetEntityCoords(heli, false)
        local distanceToHeli = #(heliCoords - waypoint)

        local ranges = { 100, 200, 400 }
        local speeds = { 5.0, 10.0, heliSpeedToWaypoint / 2 }

        -- Iterate over ranges
        for i, range in ipairs(ranges) do
            if distanceToHeli < range then
                SetDriveTaskCruiseSpeed(pilot, speeds[i])
                break -- Exit the loop once the appropriate speed is set
            end
        end

        local currentPosition = GetEntityCoords(heli, false).xy -- Get current position
        local dist = #(previousPosition - currentPosition)      -- Calculate distance from previous position
        totalDistanceMeters += dist
        previousPosition = currentPosition                      -- Update previous position

        local drivenDistText = GetFormatedDistanceText(totalDistanceMeters)

        if Config.useMoney then
            ShowInfo("Current Cost: $" .. realCost, 0.72, 0.5)
        end

        ShowInfo("Distance Flown: " .. drivenDistText, 0.75, 0.5)
    end

    endRide(playerPed)
end

local function startAirService()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed, false)

    spawnHeliLogic(playerCoords, Config.heliVehicles[math.random(1, #Config.heliVehicles)], "s_m_m_pilot_01")

    if heli ~= nil and heliBlip ~= nil and pilot ~= nil then
        IsServiceActive = true

        SetBlockingOfNonTemporaryEvents(pilot, true)
        SetEntityInvincible(pilot, true)
        SetHeliBladesFullSpeed(heli)
        SetHeliTurbulenceScalar(heli, 0.0)

        radiusBlip = AddBlipForRadius(playerCoords.x, playerCoords.y, playerCoords.z,
            Config.cancelRadius)
        SetBlipColour(radiusBlip, 5)
        SetBlipAlpha(radiusBlip, 128)

        SetDriverAbility(pilot, 1.0)
        SetDriverAggressiveness(pilot, 0.0)
        TaskHeliMission(pilot, heli, 0, 0, playerCoords.x, playerCoords.y, playerCoords.z + 50.0, 4, heliSpeedToPlayer,
            -1.0,
            -1.0, 10, 10,
            5.0, 32)

        while not IsVehicleOnAllWheels(heli) do
            Citizen.Wait(0)

            if IsPedInAnyVehicle(playerPed, true) then
                DrawNotification2D(Config.Locales["enteredVehicleCancel"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            local heliCoords = GetEntityCoords(heli, false)
            local distanceToHeli = #(heliCoords - playerCoords)

            local ranges = { 100, 200, 400 }
            local speeds = { 5.0, 10.0, heliSpeedToPlayer / 2 }

            -- Iterate over ranges
            for i, range in ipairs(ranges) do
                if distanceToHeli < range then
                    SetDriveTaskCruiseSpeed(pilot, speeds[i])
                    break -- Exit the loop once the appropriate speed is set
                end
            end

            DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)
            DrawMarker(34, playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0,
                255, 0, 0, 100, false, true, 2, false, "", "", false)
            DrawMarker(25, playerCoords.x, playerCoords.y, playerCoords.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0,
                2.0, 255, 0, 0, 100, false, true, 2, false, "", "", false)

            local cancelDistance = #(GetEntityCoords(playerPed, false) - playerCoords)
            if cancelDistance > Config.cancelRadius then
                DrawNotification2D(Config.Locales["leftServiceArea"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end
        end

        while true do
            Citizen.Wait(0)
            DrawText2D(0.5, 0.8,
                '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~]' .. Config.Locales["enterVehicle"], 0.6,
                true)
            DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end

            local closestDoor = GetClosestVehicleDoor(playerPed, heli)

            if IsControlJustPressed(0, Config.getInKey) then
                -- If any seat is available, ask the player to enter the closest one
                if closestDoor ~= nil then
                    SetVehicleFixed(heli)
                    TaskEnterVehicle(playerPed, heli, 10000, closestDoor.index, 2.0, 1, 0)
                    RemoveBlip(radiusBlip)
                else
                    DrawNotification2D(Config.Locales["noSeatsAvailable"], 2, "r")
                    cancelRide(playerPed, false)
                end

                break
            end
        end

        while not IsPedInAnyVehicle(playerPed, false) and GetVehiclePedIsIn(playerPed, false) ~= heli do
            Citizen.Wait(0)
        end

        TriggerServerEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", VehToNet(heli), PlayerPedId())

        while true do
            Citizen.Wait(0)
            if IsWaypointActive() then
                waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                break
            end

            DrawText2D(0.5, 0.85, '~w~' .. Config.Locales["setWaypoint"], 0.6, true)
            DrawText2D(0.5, 0.9,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end

            if not IsPedInAnyVehicle(playerPed, false) then
                cancelRide(playerPed, false)
                return
            end
        end

        if waypoint == nil then
            return
        end

        if Config.useMoney then
            calculateRideCost(GetEntityCoords(heli, false), waypoint)

            TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), estimatedCost)
        else
            continueAirService()
        end
    else
        print("Error creating vehicle! Please try again")
        DrawNotification2D(Config.Locales["errorCreateVehicle"], 3, "r")
    end
end

RegisterCommand("callheli", function(source, args, rawCommand)
    if IsRidingInOtherVehicle then
        DrawNotification2D(Config.Locales["inRideServiceVehicle"], 2, "r")
        return
    end

    if IsCooldownActive then
        DrawNotification2D(Config.Locales["cooldownActive"], 1, "r")
        return
    end

    if IsServiceActive then
        DrawNotification2D(Config.Locales["serviceAlreadyActive"], 5, "r")
        return
    end

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        DrawNotification2D(Config.Locales["inVehicle"], 5, "r")
        return
    end

    startAirService()
end, false)



TriggerEvent('chat:addSuggestion', '/callheli', 'Will call a heli to your location')

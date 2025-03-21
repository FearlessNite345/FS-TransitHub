local HeliPadLocations = {}

local function calculateRideCost(yourCoords, destCoords)
    local distance = #(yourCoords - destCoords) / 1609  -- Convert to miles
    Services.estimatedCost = Config.costPerMileHeli * math.floor(distance) * 5
end

local function cleanupRide()
    RemoveBlip(HeliService.heliBlip)
    RemoveBlip(HeliService.radiusBlip)
    SetEntityAsNoLongerNeeded(HeliService.pilot)
    SetEntityAsNoLongerNeeded(HeliService.heli)
    SetBlockingOfNonTemporaryEvents(HeliService.pilot, false)
    ClearVehicleTasks(HeliService.heli)

    Wait(3000)

    DeleteEntity(HeliService.pilot)
    DeleteEntity(HeliService.heli)
    if DoesEntityExist(HeliService.flareObject) then
        DeleteEntity(HeliService.flareObject)
    end

    HeliService.heli = nil
    HeliService.heliBlip = nil
    HeliService.radiusBlip = nil
    HeliService.pilot = nil
    Services.isCooldownActive = false
    HeliService.noMoney = false
end

local function endRide(playerPed)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(HeliService.heli))

    if Config.useMoney then
        TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), Services.realCost)
    end

    TaskLeaveVehicle(playerPed, HeliService.heli, 0)
    TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

    while GetVehiclePedIsIn(playerPed, false) == HeliService.heli do
        Wait(500)
    end

    Services.isCooldownActive = false
    Services.isHeliService = false
    Services.isCooldownActive = true

    if Config.useMoney then
        DrawNotification2D(Config.Locales["chargedRideCost"] .. Services.realCost, 2, "g")
    end
    DrawNotification2D(Config.Locales["arrivedDestination"], 2, "g")

    cleanupRide()
end

local function cancelRide(playerPed, isCancelRadiusTrigger)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(HeliService.heli))

    if Config.useMoney then
        if not HeliService.noMoney then
            TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), Services.realCost)
        end
    end

    if not isCancelRadiusTrigger then
        TaskLeaveVehicle(playerPed, HeliService.heli, 0)
        TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

        while GetVehiclePedIsIn(playerPed, false) == HeliService.heli do
            Wait(500)
        end
    end

    IsServiceActive = false
    Services.isHeliService = false
    Services.isCooldownActive = true

    if HeliService.noMoney and Config.useMoney then
        DrawNotification2D(Config.Locales["noMoney"], 2, "r")
    else
        if Config.useMoney then
            DrawNotification2D(Config.Locales["chargedRideCost"] .. Services.realCost, 2, "g")
        end
        DrawNotification2D(Config.Locales["rideCancel"], 2, "r")
    end

    cleanupRide()
end

local function spawnHeliLogic(playerCoords, heliModel, pilotPed)
    -- Get a random offset from the player's position
    local maxSpawnDistance = 275.0

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
    HeliService.heli = CreateVehicle(heliModelHash, spawnPos.x, spawnPos.y, spawnPos.z + 300.0, 0.0, true, false)
    HeliService.heliBlip = AddBlipForEntity(HeliService.heli)
    SetVehicleLights(HeliService.heli, 2)

    SetBlipSprite(HeliService.heliBlip, 422)
    SetBlipDisplay(HeliService.heliBlip, 2)
    SetBlipScale(HeliService.heliBlip, 0.8)
    SetBlipColour(HeliService.heliBlip, 3)

    -- Create NPC pilot
    HeliService.pilot = CreatePedInsideVehicle(HeliService.heli, 26, pedModelHash, -1, true, true)

    if not DoesEntityExist(HeliService.heli) then
        HeliService.heli, HeliService.heliBlip, HeliService.pilot = nil, nil, nil
    end
end

local function continueAirService(flyToDestinationCoords)
    local playerPed = PlayerPedId()

    while true do
        Wait(0)

        if Config.useMoney then
            ShowInfo("Estimated Cost: " .. Services.estimatedCost, 0.75, 0.5)
        end

        if not IsPedInAnyHeli(playerPed) then
            cancelRide(playerPed, false)
            break
        end

        FS_Lib:DrawText2D(0.5, 0.85,
            '~w~[~g~' .. GetKeyStringFromKeyID(Config.startRide) .. '~w~] ' .. Config.Locales["startRide"], 0.6, true)
        FS_Lib:DrawText2D(0.5, 0.9,
            '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6, true)

        if IsControlJustPressed(0, Config.startRide) then
            TriggerServerEvent(
                "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(HeliService.heli))
            break
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end
    end


    TaskHeliMission(HeliService.pilot, HeliService.heli, 0, 0, flyToDestinationCoords.x, flyToDestinationCoords.y,
        flyToDestinationCoords.z, 4, HeliService.heliSpeedToWaypoint, -1.0,
        -1.0, 10, 10,
        5.0, 32)

    local previousPosition = GetEntityCoords(HeliService.heli, false).xy -- Store the initial position

    local totalDistanceMeters = 0.0
    local totalDistanceMiles = 0.0

    while IsVehicleOnAllWheels(HeliService.heli) do
        Wait(500)
    end

    while not IsVehicleOnAllWheels(HeliService.heli) do
        Wait(0)

        if not IsPedInAnyHeli(playerPed) then
            cancelRide(playerPed, false)
            break
        end

        local ranges = { 100, 200, 400 }
        local speeds = { 5.0, 10.0, HeliService.heliSpeedToWaypoint / 2 }

        AdjustCruiseSpeed(HeliService.pilot, HeliService.heli, flyToDestinationCoords, ranges, speeds)

        local currentPosition = GetEntityCoords(HeliService.heli, false).xy -- Get current position
        local dist = #(previousPosition - currentPosition)      -- Calculate distance from previous position
        totalDistanceMeters = totalDistanceMeters + dist
        totalDistanceMiles = totalDistanceMiles + dist / 1609                       -- Update total distance
        previousPosition = currentPosition                      -- Update previous position

        local drivenDistText = GetFormatedDistanceText(totalDistanceMeters)

        Services.realCost = math.floor(Config.costPerMileHeli * totalDistanceMiles * 100 + 0.5) / 100

        if Config.useMoney then
            ShowInfo("Current Cost: $" .. Services.realCost, 0.72, 0.5)
        end

        ShowInfo("Distance Flown: " .. drivenDistText, 0.75, 0.5)
    end

    endRide(playerPed)
end

local function startAirService(flyToPickupCoords, flyToDestinationCoords)
    local playerPed = PlayerPedId()

    spawnHeliLogic(flyToPickupCoords, Config.heliVehicles[math.random(1, #Config.heliVehicles)], "s_m_m_pilot_01")

    if HeliService.heli ~= nil and HeliService.heliBlip ~= nil and HeliService.pilot ~= nil then
        IsServiceActive = true
        Services.isHeliService = true

        SetBlockingOfNonTemporaryEvents(HeliService.pilot, true)
        --SetEntityInvincible(pilot, true)
        SetHeliBladesFullSpeed(HeliService.heli)
        SetHeliTurbulenceScalar(HeliService.heli, 0.0)
        SetHelicopterRollPitchYawMult(HeliService.heli, 0.0)

        HeliService.radiusBlip = AddBlipForRadius(flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z,
            Config.cancelRadius)
        SetBlipColour(HeliService.radiusBlip, 5)
        SetBlipAlpha(HeliService.radiusBlip, 128)

        SetDriverAbility(HeliService.pilot, 1.0)
        SetDriverAggressiveness(HeliService.pilot, 0.0)

        TaskHeliMission(HeliService.pilot, HeliService.heli, 0, 0, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z, 4,
        HeliService.heliSpeedToPlayer,
            -1.0,
            -1.0, 10, 10,
            5.0, 32)

        local flareHash = GetHashKey("weapon_flare");
        RequestModel(`w_am_flare`);
        RequestWeaponAsset(flareHash, 31, 0);

        HeliService.flareObject = CreateWeaponObject(flareHash, 1, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z,
            true, 0.0, 0)
        PlaceObjectOnGroundProperly(HeliService.flareObject);
        SetEntityRotation(HeliService.flareObject, 90.0, 0.0, 0.0, 2, false)

        while not IsVehicleOnAllWheels(HeliService.heli) do
            Wait(0)

            if IsPedInAnyVehicle(playerPed, true) then
                DrawNotification2D(Config.Locales["enteredVehicleCancel"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            local ranges = { 100, 200, 400 }
            local speeds = { 5.0, 10.0, HeliService.heliSpeedToPlayer / 2 }

            AdjustCruiseSpeed(HeliService.pilot, HeliService.heli, flyToPickupCoords, ranges, speeds)

            FS_Lib:DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6, true)
            --[[             DrawMarker(34, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                2.0, 2.0, 2.0,
                255, 0, 0, 100, false, true, 2, false, "", "", false)
            DrawMarker(25, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 2.0,
                2.0,
                2.0, 255, 0, 0, 100, false, true, 2, false, "", "", false) ]]

            local cancelDistance = #(GetEntityCoords(playerPed, false) - flyToPickupCoords)
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

        DeleteEntity(HeliService.flareObject)

        while true do
            Wait(0)
            FS_Lib:DrawText2D(0.5, 0.8,
                '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~] ' .. Config.Locales["enterVehicle"], 0.6,
                true)
            FS_Lib:DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end

            local closestDoor = GetClosestVehicleDoor(playerPed, HeliService.heli)

            if IsControlJustPressed(0, Config.getInKey) then
                -- If any seat is available, ask the player to enter the closest one
                if closestDoor ~= nil then
                    SetVehicleFixed(HeliService.heli)
                    TaskEnterVehicle(playerPed, HeliService.heli, 10000, closestDoor.index, 2.0, 1, 0)
                    RemoveBlip(HeliService.radiusBlip)
                else
                    DrawNotification2D(Config.Locales["noSeatsAvailable"], 2, "r")
                    cancelRide(playerPed, false)
                end

                break
            end
        end

        while not IsPedInAnyVehicle(playerPed, false) and GetVehiclePedIsIn(playerPed, false) ~= HeliService.heli do
            Wait(0)
        end

        TriggerServerEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", VehToNet(HeliService.heli), PlayerPedId(), true)

        if flyToDestinationCoords == nil then
            while true do
                Wait(0)
                if IsWaypointActive() then
                    HeliService.waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                    break
                end

                FS_Lib:DrawText2D(0.5, 0.85, '~w~' .. Config.Locales["setWaypoint"], 0.6, true)
                FS_Lib:DrawText2D(0.5, 0.9,
                    '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6,
                    true)

                if IsControlJustPressed(0, Config.cancelKey) then
                    cancelRide(playerPed, false)
                    return
                end

                if not IsPedInAnyVehicle(playerPed, false) then
                    cancelRide(playerPed, false)
                    return
                end
            end

            if HeliService.waypoint == nil then
                return
            end
        end

        if Config.useMoney then
            if flyToDestinationCoords then
                calculateRideCost(GetEntityCoords(HeliService.heli, false), flyToDestinationCoords)
                TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), Services.estimatedCost,
                    flyToDestinationCoords)
            else
                calculateRideCost(GetEntityCoords(HeliService.heli, false), HeliService.waypoint)

                local z = GetHeightmapTopZForPosition(HeliService.waypoint.x, HeliService.waypoint.y)
                local flyToCoords = vector3(HeliService.waypoint.x, HeliService.waypoint.y, z)

                TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), Services.estimatedCost,
                    flyToCoords)
            end
        else
            if flyToDestinationCoords then
                continueAirService(flyToDestinationCoords)
            else
                local z = GetHeightmapTopZForPosition(HeliService.waypoint.x, HeliService.waypoint.y)
                local flyToCoords = vector3(HeliService.waypoint.x, HeliService.waypoint.y, z)

                continueAirService(flyToCoords)
            end
        end
    else
        print("Error creating vehicle! Please try again")
        DrawNotification2D(Config.Locales["errorCreateVehicle"], 3, "r")
    end
end

RegisterCommand("callheli", function(source, args, rawCommand)
    Services.realCost = 0
    Services.estimatedCost = 0

    if IsRidingInOtherVehicle then
        DrawNotification2D(Config.Locales["inRideServiceVehicle"], 2, "r")
        return
    end

    if Services.isCooldownActive then
        DrawNotification2D(Config.Locales["cooldownActive"], 2, "r")
        return
    end

    if IsServiceActive then
        DrawNotification2D(Config.Locales["serviceAlreadyActive"], 2, "r")
        return
    end

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        DrawNotification2D(Config.Locales["inVehicle"], 2, "r")
        return
    end

    if Config.requireNearHeliPad then
        if args[1] == nil or args[2] == nil then
            DrawNotification2D("You must provide a pickup and destination location.", 2, "r")
            return
        end
    end

    if args[1] ~= nil and args[2] ~= nil then
        if args[1] == args[2] then
            DrawNotification2D("Unable to have same pickup and destination.", 2, "r")
            return
        elseif args[1] == nil or args[2] == nil then
            DrawNotification2D("You must provide a pickup and destination location.", 2, "r")
            return
        end

        local heliPadPickupCoords = HeliPadLocations[args[1]].coords
        local vectorPickupLocation = vector3(heliPadPickupCoords.x, heliPadPickupCoords.y, heliPadPickupCoords.z)
        local heliPadDestCoords = HeliPadLocations[args[2]].coords
        local vectorDestLocation = vector3(heliPadDestCoords.x, heliPadDestCoords.y, heliPadDestCoords.z)

        local cancelDistance = #(GetEntityCoords(PlayerPedId(), false) - vectorPickupLocation)
        if cancelDistance > Config.cancelRadius then
            DrawNotification2D(Config.Locales["notNearPickupZone"], 2, "r")
            return
        end

        startAirService(vectorPickupLocation, vectorDestLocation)
    else
        local playerPed = PlayerPedId()

        local forwardVector = GetEntityForwardVector(playerPed)
        local pickupCoords = GetEntityCoords(playerPed, false) + forwardVector * 4.0

        startAirService(pickupCoords)
    end
end, false)

CreateThread(function()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "config/HeliPads.json")
    local extract = {}
    extract = json.decode(loadFile)

    for _, helipad in ipairs(extract) do
        HeliPadLocations[helipad.name] = helipad
    end

    local resultString = table.concat(table.keys(HeliPadLocations), ', ')

    if Config.requireNearHeliPad then
        TriggerEvent('chat:addSuggestion', '/callheli',
            "Specify pickup and destination for direct heli pad-to-pad transport.",
            {
                { name = "PICKUP",      help = resultString },
                { name = "DESTINATION", help = resultString },
            })
    else
        TriggerEvent('chat:addSuggestion', '/callheli',
            "Specify pickup and destination for direct heli pad-to-pad transport. Otherwise, we'll come to you, and you can set a waypoint for the destination.",
            {
                { name = "PICKUP",      help = resultString },
                { name = "DESTINATION", help = resultString },
            })
    end
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:MoneyCheckResult", function(hasMoney, destination)
    print(Services.isHeliService)
    if not Services.isHeliService then
        return
    end

    if hasMoney then
        continueAirService(destination)
    else
        HeliService.noMoney = true
        cancelRide(PlayerPedId(), false)
    end
end)

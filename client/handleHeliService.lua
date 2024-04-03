local radiusBlip
local waypoint
local pilot
local heli
local heliBlip
local flareObject
local noMoney = false
local realCost = 0
local estimatedCost = 0
local heliSpeedToPlayer = 30.0
local heliSpeedToWaypoint = 35.0

local HeliPadLocations = {}

IsHeliService = false

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
    IsHeliService = false
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
    IsHeliService = false
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
    if DoesEntityExist(flareObject) then
        DeleteEntity(flareObject)
    end

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

    SetBlipSprite(heliBlip, 422)
    SetBlipDisplay(heliBlip, 2)
    SetBlipScale(heliBlip, 0.8)
    SetBlipColour(heliBlip, 3)

    -- Create NPC pilot
    pilot = CreatePedInsideVehicle(heli, 26, pedModelHash, -1, true, true)

    if not DoesEntityExist(heli) then
        heli, heliBlip, pilot = nil, nil, nil
    end
end

local function continueAirService(flyToDestinationCoords)
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


    TaskHeliMission(pilot, heli, 0, 0, flyToDestinationCoords.x, flyToDestinationCoords.y,
        flyToDestinationCoords.z, 4, heliSpeedToWaypoint, -1.0,
        -1.0, 10, 10,
        5.0, 32)


    local previousPosition = GetEntityCoords(heli, false).xy -- Store the initial position

    local totalDistanceMeters = 0.0
    local totalDistanceMiles = 0.0

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
        local distanceToHeli

        distanceToHeli = #(heliCoords - flyToDestinationCoords)

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
        totalDistanceMiles += dist / 1609                       -- Update total distance
        previousPosition = currentPosition                      -- Update previous position

        local drivenDistText = GetFormatedDistanceText(totalDistanceMeters)

        realCost = math.floor(Config.costPerMileHeli * totalDistanceMiles * 100 + 0.5) / 100

        if Config.useMoney then
            ShowInfo("Current Cost: $" .. realCost, 0.72, 0.5)
        end

        ShowInfo("Distance Flown: " .. drivenDistText, 0.75, 0.5)
    end

    endRide(playerPed)
end

local function startAirService(flyToPickupCoords, flyToDestinationCoords)
    local playerPed = PlayerPedId()

    spawnHeliLogic(flyToPickupCoords, Config.heliVehicles[math.random(1, #Config.heliVehicles)], "s_m_m_pilot_01")

    if heli ~= nil and heliBlip ~= nil and pilot ~= nil then
        IsServiceActive = true
        IsHeliService = true

        SetBlockingOfNonTemporaryEvents(pilot, true)
        SetEntityInvincible(pilot, true)
        SetHeliBladesFullSpeed(heli)
        SetHeliTurbulenceScalar(heli, 0.0)
        SetHelicopterRollPitchYawMult(heli, 0.0)

        radiusBlip = AddBlipForRadius(flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z,
            Config.cancelRadius)
        SetBlipColour(radiusBlip, 5)
        SetBlipAlpha(radiusBlip, 128)

        SetDriverAbility(pilot, 1.0)
        SetDriverAggressiveness(pilot, 0.0)

        TaskHeliMission(pilot, heli, 0, 0, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z, 4,
            heliSpeedToPlayer,
            -1.0,
            -1.0, 10, 10,
            5.0, 32)

        local flareHash = GetHashKey("weapon_flare");
        RequestModel(`w_am_flare`);
        RequestWeaponAsset(flareHash, 31, 0);

        flareObject = CreateWeaponObject(flareHash, 1, flyToPickupCoords.x, flyToPickupCoords.y, flyToPickupCoords.z,
            true, 0.0, 0)
        PlaceObjectOnGroundProperly(flareObject);
        SetEntityRotation(flareObject, 90.0, 0.0, 0.0, 2, false)

        while not IsVehicleOnAllWheels(heli) do
            Citizen.Wait(0)

            if IsPedInAnyVehicle(playerPed, true) then
                DrawNotification2D(Config.Locales["enteredVehicleCancel"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            local heliCoords = GetEntityCoords(heli, false)
            local distanceToHeli = #(heliCoords - flyToPickupCoords)

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

        DeleteEntity(flareObject)

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

        if flyToDestinationCoords == nil then
            while true do
                Citizen.Wait(0)
                if IsWaypointActive() then
                    waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                    break
                end

                DrawText2D(0.5, 0.85, '~w~' .. Config.Locales["setWaypoint"], 0.6, true)
                DrawText2D(0.5, 0.9,
                    '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6,
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

            if waypoint == nil then
                return
            end
        end

        if Config.useMoney then

            if flyToDestinationCoords then
                calculateRideCost(GetEntityCoords(heli, false), flyToDestinationCoords)
                TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), estimatedCost,
                    flyToDestinationCoords)
            else
                calculateRideCost(GetEntityCoords(heli, false), waypoint)

                local z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)
                local flyToCoords = vector3(waypoint.x, waypoint.y, z)

                TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), estimatedCost,
                    flyToCoords)
            end
        else
            if flyToDestinationCoords then
                continueAirService(flyToDestinationCoords)
            else
                local z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)
                local flyToCoords = vector3(waypoint.x, waypoint.y, z)

                continueAirService(flyToCoords)
            end
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
        local playerCoords = GetEntityCoords(playerPed, false)

        startAirService(playerCoords)
    end
end, false)

Citizen.CreateThread(function()
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
    print(IsHeliService)
    if not IsHeliService then
        return
    end

    if hasMoney then
        continueAirService(destination)
    else
        noMoney = true
        cancelRide(PlayerPedId(), false)
    end
end)

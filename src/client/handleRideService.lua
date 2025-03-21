local function calculateRideCost(yourCoords, destCoords)
    local costPerMileMap = {
        taxi = Config.costPerMileTaxi,
        swift = Config.costPerMileSwift,
        swiftluxury = Config.costPerMileSwiftLuxury
    }

    local costPerMile = costPerMileMap[RideService.rideType]
    if costPerMile then
        Services.estimatedCost = (costPerMile * math.floor(#(yourCoords - destCoords) / 1609)) * 5
    else
        print("Invalid ride type: " .. tostring(RideService.rideType))
    end
end

local function spawnVehicleLogic(playerCoords, vehicleModel, driverPed, plate, type)
    -- Get a random offset from the player's position
    local offsetX = RandomLimited(RideService.minSpawnDistance, RideService.maxSpawnDistance, 100)
    local offsetY = RandomLimited(RideService.minSpawnDistance, RideService.maxSpawnDistance, 100)
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

    if type == 'taxi' then
        SetBlipSprite(vehicleBlip, RideService.taxiBlip)
    elseif type == 'swift' then
        SetBlipSprite(vehicleBlip, RideService.swiftBlip)
    elseif type == 'swiftluxury' then
        SetBlipSprite(vehicleBlip, RideService.limoBlip)
    else
        print("Invalid type given")
    end

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

local function cleanupRide()
    RemoveBlip(RideService.vehicleBlip)
    RemoveBlip(RideService.radiusBlip)
    SetEntityAsNoLongerNeeded(RideService.driver)
    SetEntityAsNoLongerNeeded(RideService.vehicle)
    SetBlockingOfNonTemporaryEvents(RideService.driver, false)
    ClearVehicleTasks(RideService.vehicle)

    Wait(5000)

    DeleteEntity(RideService.driver)
    DeleteEntity(RideService.vehicle)

    RideService.vehicle = nil
    RideService.vehicleBlip = nil
    RideService.radiusBlip = nil
    RideService.driver = nil
    Services.isCooldownActive = false
    RideService.noMoney = false
end

local function endRide(playerPed)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(RideService.vehicle))

    if Config.useMoney then
        TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), Services.realCost)
    end

    StopCurrentPlayingSpeech(RideService.driver)
    PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_ARRIVE_AT_DEST", "A_M_M_EASTSA_02_LATINO_FULL_01",
        "SPEECH_PARAMS_FORCE_NORMAL", false)

    SetTaxiLights(RideService.vehicle, true)

    TaskVehicleTempAction(RideService.driver, RideService.vehicle, 1, 10000)
    TaskLeaveVehicle(playerPed, RideService.vehicle, 0)
    TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

    while GetVehiclePedIsIn(playerPed, false) == RideService.vehicle do
        Wait(0)
    end

    Services.isServiceActive = false
    RideService.isRushed = false
    Services.isCooldownActive = true

    if Config.useMoney then
        DrawNotification2D(Config.Locales["chargedRideCost"] .. Services.realCost, 2, "g")
    end
    DrawNotification2D(Config.Locales["arrivedDestination"], 2, "g")

    cleanupRide()
end

local function cancelRide(playerPed, isCancelRadiusTrigger)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(RideService.vehicle))

    if Config.useMoney then
        if RideService.noMoney then
            StopCurrentPlayingSpeech(RideService.driver)
            PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_NO_MONEY", "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)
        else
            TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), Services.realCost)
        end
    end

    SetTaxiLights(RideService.vehicle, true)

    if GetVehiclePedIsIn(playerPed, false) == RideService.vehicle and not RideService.noMoney then
        StopCurrentPlayingSpeech(RideService.driver)
        PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_GET_OUT_EARLY", "A_M_M_EASTSA_02_LATINO_FULL_01",
            "SPEECH_PARAMS_FORCE_NORMAL", false)
    end

    if not isCancelRadiusTrigger then
        TaskVehicleTempAction(RideService.driver, RideService.vehicle, 1, 10000)
        TaskLeaveVehicle(playerPed, RideService.vehicle, 0)
        TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

        while GetVehiclePedIsIn(playerPed, false) == RideService.vehicle do
            Wait(500)
        end
    end

    Services.isServiceActive = false
    RideService.isRushed = false

    Services.isCooldownActive = true

    if RideService.noMoney and Config.useMoney then
        DrawNotification2D(Config.Locales["noMoney"], 2, "r")
    else
        if Config.useMoney then
            DrawNotification2D(Config.Locales["chargedRideCost"] .. Services.realCost, 2, "g")
        end
        DrawNotification2D(Config.Locales["rideCancel"], 2, "r")
    end

    cleanupRide()
end

local function continueRideService()
    local playerPed = PlayerPedId()

    while true do
        Wait(0)

        if Config.useMoney then
            ShowInfo("Estimated Cost: " .. Services.estimatedCost, 0.75, 0.5)
        end

        FS_Lib:DrawText2D(0.5, 0.85,
            '~w~[~g~' .. GetKeyStringFromKeyID(Config.startRide) .. '~w~] ' .. Config.Locales["startRide"], 0.6, true)
        FS_Lib:DrawText2D(0.5, 0.9,
            '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6, true)

        if IsControlJustPressed(0, Config.startRide) then
            StopCurrentPlayingSpeech(RideService.driver)
            PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_BEGIN_JOURNEY",
                "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)

            TriggerServerEvent(
                "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(RideService.vehicle))
            break
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end
    end

    local z = GetHeightmapTopZForPosition(RideService.waypoint.x, RideService.waypoint.y)

    TaskVehicleDriveToCoord(RideService.driver, RideService.vehicle, RideService.waypoint.x, RideService.waypoint.y, z,
        RideService.speedToDestination, 30.0,
        GetEntityModel(RideService.vehicle),
        RideService.drivingStyle, RideService.driverStopRange, 1.0)

    local timerMax = 2250
    local timer = timerMax

    local previousPosition = GetEntityCoords(RideService.vehicle, false) -- Store the initial position

    local totalDistanceMeters = 0.0
    local totalDistanceMiles = 0.0 -- Initialize total distance

    while IsWaypointActive() and GetVehiclePedIsIn(playerPed, false) == RideService.vehicle do
        Wait(0)

        TriggerServerEvent('FearlessStudios-SwiftRideService:DebugPedTask', NetworkGetNetworkIdFromEntity(RideService.driver))

        local currentPosition = GetEntityCoords(RideService.vehicle, false) -- Get current position
        local dist = #(previousPosition - currentPosition)                  -- Calculate distance from previous position
        totalDistanceMeters = totalDistanceMeters + dist
        totalDistanceMiles = totalDistanceMiles + dist / 1609               -- Update total distance
        previousPosition = currentPosition                                  -- Update previous position

        local additionalMultiplier = 0.25 * (RideService.numPeopleInRide - 1)
        local totalMultiplier = RideService.baseRideMultiplier + additionalMultiplier

        if RideService.rideType == "taxi" then
            Services.realCost = math.floor(Config.costPerMileTaxi * totalDistanceMiles * 100 + 0.5) / 100
        elseif RideService.rideType == "swift" then
            Services.realCost = math.floor(Config.costPerMileSwift * totalDistanceMiles * 100 + 0.5) / 100
        elseif RideService.rideType == "swiftluxury" then
            Services.realCost = math.floor(Config.costPerMileSwiftLuxury * totalDistanceMiles * 100 + 0.5) / 100 *
                totalMultiplier
        end

        local drivenDistText = GetFormatedDistanceText(totalDistanceMeters)

        if Config.useMoney then
            ShowInfo("Current Cost: $" .. Services.realCost, 0.72, 0.5)
        end

        ShowInfo("Distance Driven: " .. drivenDistText, 0.75, 0.5)

        if Config.rideBanter then
            timer = timer - 1

            if timer <= 0 then
                StopCurrentPlayingSpeech(RideService.driver)
                PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_BANTER", "A_M_M_EASTSA_02_LATINO_FULL_01",
                    "SPEECH_PARAMS_FORCE_NORMAL", false)
                timer = timerMax
            end
        end

        if not RideService.isRushed then
            FS_Lib:DrawText2D(0.5, 0.85,
                '~w~[~g~' .. GetKeyStringFromKeyID(Config.rushKey) .. '~w~] ' .. Config.Locales["hurryUp"], 0.6, true)
            FS_Lib:DrawText2D(0.5, 0.9,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6,
                true)
        else
            FS_Lib:DrawText2D(0.5, 0.9,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6,
                true)
        end

        if IsControlJustPressed(0, Config.rushKey) and not RideService.isRushed then
            StopCurrentPlayingSpeech(RideService.driver)
            PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_SPEED_UP", "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)
            RideService.isRushed = true

            SetDriveTaskDrivingStyle(RideService.driver, RideService.rushedDrivingStyle)
            SetDriveTaskCruiseSpeed(RideService.driver, RideService.rushedSpeed)
            SetDriverAggressiveness(RideService.driver, 1.0)
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end

        if Config.slowApproachDestination then
            local ranges = { 25, 50 }
            local speeds = { 5.0, 10.0 }

            AdjustCruiseSpeed(RideService.driver, RideService.vehicle, RideService.waypoint, ranges, speeds)
        end
    end

    endRide(playerPed)
end

local function startRideService(vehicleModel, driverModel, plate)
    RideService.numPeopleInRide = 1

    local playerPed = PlayerPedId()

    local forwardVector = GetEntityForwardVector(playerPed)
    RideService.destinationCoords = GetEntityCoords(playerPed, false) + forwardVector * 4.0

    RideService.vehicle, RideService.vehicleBlip, RideService.driver = spawnVehicleLogic(RideService.destinationCoords,
        vehicleModel, driverModel, plate, RideService.rideType)

    if RideService.vehicle ~= nil and RideService.vehicleBlip ~= nil and RideService.driver ~= nil then
        Services.isServiceActive = true

        SetBlockingOfNonTemporaryEvents(RideService.driver, true)
        --SetEntityInvincible(RideService.driver, true)

        RideService.radiusBlip = AddBlipForRadius(RideService.destinationCoords.x, RideService.destinationCoords.y,
            RideService.destinationCoords.z,
            Config.cancelRadius)
        SetBlipColour(RideService.radiusBlip, 5)
        SetBlipAlpha(RideService.radiusBlip, 128)

        SetDriverAbility(RideService.driver, 1.0)
        SetDriverAggressiveness(RideService.driver, 0.0)
        TaskVehicleDriveToCoord(RideService.driver, RideService.vehicle, RideService.destinationCoords.x,
            RideService.destinationCoords.y, RideService.destinationCoords.z,
            RideService.speedToPlayer,
            0.0, GetEntityModel(RideService.vehicle), RideService.rushedDrivingStyle, RideService.driverStopRange, 1.0)

        while #(GetEntityCoords(RideService.vehicle, false) - RideService.destinationCoords) > RideService.stopRange do
            Wait(0)

            print(#(GetEntityCoords(RideService.vehicle, false) - RideService.destinationCoords))

            if IsPedInAnyVehicle(playerPed, true) then
                DrawNotification2D(Config.Locales["enteredVehicleCancel"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            FS_Lib:DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6,
                true)

            local cancelDistance = #(GetEntityCoords(playerPed, false) - RideService.destinationCoords)
            if cancelDistance > Config.cancelRadius then
                DrawNotification2D(Config.Locales["leftServiceArea"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end

            if Config.slowApproachPlayer then
                local ranges = { 25, 50 }
                local speeds = { 5.0, 10.0 }

                AdjustCruiseSpeed(RideService.driver, RideService.vehicle, RideService.destinationCoords, ranges, speeds)
            end
        end

        ClearVehicleTasks(RideService.vehicle)
        TaskVehicleTempAction(RideService.driver, RideService.vehicle, 1, 10000)

        while true do
            Wait(0)
            FS_Lib:DrawText2D(0.5, 0.8,
                '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~] ' .. Config.Locales["enterVehicle"], 0.6,
                true)
            FS_Lib:DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~] ' .. Config.Locales["cancelRide"], 0.6,
                true)

            if IsControlJustPressed(0, Config.cancelKey) then
                cancelRide(playerPed, false)
                return
            end

            local closestDoor = GetClosestVehicleDoor(playerPed, RideService.vehicle)

            if IsControlJustPressed(0, Config.getInKey) then
                -- If any seat is available, ask the player to enter the closest one
                if closestDoor ~= nil then
                    SetVehicleFixed(RideService.vehicle)
                    TaskEnterVehicle(playerPed, RideService.vehicle, 10000, closestDoor.index, 2.0, 1, 0)
                    RemoveBlip(RideService.radiusBlip)
                else
                    DrawNotification2D(Config.Locales["noSeatsAvailable"], 2, "r")
                    cancelRide(playerPed, false)
                end

                break
            end
        end

        while not IsPedInAnyVehicle(playerPed, false) and GetVehiclePedIsIn(playerPed, false) ~= RideService.vehicle do
            Wait(0)
        end

        -- Notify that your able to also pickup others now
        TriggerServerEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", VehToNet(RideService.vehicle),
            PlayerPedId(), false)
        SetTaxiLights(RideService.vehicle, false)
        StopCurrentPlayingSpeech(RideService.driver)
        PlayPedAmbientSpeechWithVoiceNative(RideService.driver, "TAXID_WHERE_TO", "A_M_M_EASTSA_02_LATINO_FULL_01",
            "SPEECH_PARAMS_FORCE_NORMAL", false)

        while true do
            Wait(0)
            if IsWaypointActive() then
                RideService.waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
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

        if RideService.waypoint == nil then
            return
        end

        if Config.useMoney then
            calculateRideCost(GetEntityCoords(RideService.vehicle, false), RideService.waypoint)

            TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), Services.estimatedCost)
        else
            continueRideService()
        end
    else
        print("Error creating vehicle! Please try again")
        DrawNotification2D(Config.Locales["errorCreateVehicle"], 3, "r")
    end
end

RegisterCommand("callride", function(source, args, rawCommand)
    Services.realCost = 0
    Services.estimatedCost = 0

    if IsRidingInOtherVehicle then
        DrawNotification2D(Config.Locales["inRideServiceVehicle"], 2, "r")
        return
    end

    if Services.isCooldownActive == true then
        DrawNotification2D(Config.Locales["cooldownActive"], 1, "r")
        return
    end

    if Services.isCooldownActive then
        DrawNotification2D(Config.Locales["serviceAlreadyActive"], 5, "r")
        return
    end

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        DrawNotification2D(Config.Locales["inVehicle"], 5, "r")
        return
    end

    if args[1] == 'taxi' then
        RideService.rideType = "taxi"
        startRideService(Config.taxiVehicles[math.random(1, #Config.taxiVehicles)], "a_m_y_stlat_01", "FS TAXI")
    elseif args[1] == 'swift' then
        RideService.rideType = "swift"
        startRideService(Config.swiftVehicles[math.random(1, #Config.swiftVehicles)], "a_m_y_stlat_01", "FS SWIFT")
    elseif args[1] == 'swiftluxury' then
        RideService.rideType = "swiftluxury"
        startRideService(Config.swiftLuxuryVehicles[math.random(1, #Config.swiftLuxuryVehicles)], "a_m_m_business_01",
            "FS SWIFT")
    else
        print("Invalid type given")
    end
end, false)

TriggerEvent('chat:addSuggestion', '/callride', 'Will call a ride vehicle to your location', {
    { name = "TYPE", help = "taxi, swift, swiftluxury" },
})

RegisterNetEvent("FearlessStudios-SwiftRideService:MoneyCheckResult", function(hasMoney)
    print(Services.IsHeliService)
    if Services.isHeliService then
        return
    end

    if hasMoney then
        continueRideService()
    else
        RideService.noMoney = true
        cancelRide(PlayerPedId(), false)
    end
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:IncreasePlayersInRide", function(hasMoney)
    RideService.numPeopleInRide = RideService.numPeopleInRide + 1
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:DecreasePlayersInRide", function(hasMoney)
    RideService.numPeopleInRide = RideService.numPeopleInRide - 1
end)

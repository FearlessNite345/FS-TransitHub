IsServiceActive = false
IsCooldownActive = false
local isRushed = false
local noMoney = false

local limoBlip = 724
local taxiBlip = 198
local swiftBlip = 326

local driver
local vehicle
local vehicleBlip
local radiusBlip
local destinationCoords
local waypoint
local rideType
local realCost = 0
local estimatedCost = 0
local baseRideMultiplier = 1
local numPeopleInRide = 1

local driverStopRange = 2.0 -- this is only to tell the driver to get as close as possible the stopRange is the real one
local stopRange = 10.0
local drivingStyle = 786603
local rushedDrivingStyle = 1074528805
local speedToPlayer = 18.0
local speedToDestination = 25.0
local rushedSpeed = 37.0
local minSpawnDistance = 0
local maxSpawnDistance = 250.0

local function calculateRideCost(yourCoords, destCoords)
    if rideType == "taxi" then
        estimatedCost = (Config.costPerMileTaxi * math.floor(#(yourCoords - destCoords) / 1609)) * 5
    elseif rideType == "swift" then
        estimatedCost = (Config.costPerMileSwift * math.floor(#(yourCoords - destCoords) / 1609)) * 5
    elseif rideType == "swiftluxury" then
        estimatedCost = (Config.costPerMileSwiftLuxury * math.floor(#(yourCoords - destCoords) / 1609)) * 5
    end
end

local function spawnVehicleLogic(playerCoords, vehicleModel, driverPed, plate, type)
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

    if type == 'taxi' then
        SetBlipSprite(vehicleBlip, taxiBlip)
    elseif type == 'swift' then
        SetBlipSprite(vehicleBlip, swiftBlip)
    elseif type == 'swiftluxury' then
        SetBlipSprite(vehicleBlip, limoBlip)
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

local function endRide(playerPed)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(vehicle))

    if Config.useMoney then
        TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), realCost)
    end

    StopCurrentPlayingSpeech(driver)
    PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_ARRIVE_AT_DEST", "A_M_M_EASTSA_02_LATINO_FULL_01",
        "SPEECH_PARAMS_FORCE_NORMAL", false)

    SetTaxiLights(vehicle, true)

    TaskVehicleTempAction(driver, vehicle, 1, 30)
    TaskLeaveVehicle(playerPed, vehicle, 0)
    TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

    while GetVehiclePedIsIn(playerPed, false) == vehicle do
        Citizen.Wait(500)
    end

    -- Remove the blip from the vehicle
    RemoveBlip(vehicleBlip)
    RemoveBlip(radiusBlip)
    SetEntityAsNoLongerNeeded(driver)
    SetEntityAsNoLongerNeeded(vehicle)
    SetBlockingOfNonTemporaryEvents(driver, false)
    ClearVehicleTasks(vehicle)

    IsServiceActive = false
    isRushed = false
    IsCooldownActive = true

    if Config.useMoney then
        DrawNotification2D(Config.Locales["chargedRideCost"] .. realCost, 2, "g")
    end
    DrawNotification2D(Config.Locales["arrivedDestination"], 2, "g")

    Citizen.Wait(3000)

    DeleteEntity(driver)
    DeleteEntity(vehicle)

    vehicle = nil
    vehicleBlip = nil
    radiusBlip = nil
    driver = nil
    IsCooldownActive = false
    noMoney = false
end

local function cancelRide(playerPed, isCancelRadiusTrigger)
    TriggerServerEvent(
        "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(vehicle))

    if Config.useMoney then
        if noMoney then
            StopCurrentPlayingSpeech(driver)
            PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_NO_MONEY", "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)
        else
            TriggerServerEvent("FearlessStudios-SwiftRideService:Pay", PlayerPedId(), realCost)
        end
    end

    SetTaxiLights(vehicle, true)

    if GetVehiclePedIsIn(playerPed, false) == vehicle and not noMoney then
        StopCurrentPlayingSpeech(driver)
        PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_GET_OUT_EARLY", "A_M_M_EASTSA_02_LATINO_FULL_01",
            "SPEECH_PARAMS_FORCE_NORMAL", false)
    end

    if not isCancelRadiusTrigger then
        TaskVehicleTempAction(driver, vehicle, 1, 30)
        TaskLeaveVehicle(playerPed, vehicle, 0)
        TriggerServerEvent("FearlessStudios-SwiftRideService:AllExitRide")

        while GetVehiclePedIsIn(playerPed, false) == vehicle do
            Citizen.Wait(500)
        end
    end

    -- Remove the blip from the vehicle
    RemoveBlip(vehicleBlip)
    RemoveBlip(radiusBlip)
    SetEntityAsNoLongerNeeded(driver)
    SetEntityAsNoLongerNeeded(vehicle)
    SetBlockingOfNonTemporaryEvents(driver, false)
    ClearVehicleTasks(vehicle)

    IsServiceActive = false
    isRushed = false

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

    DeleteEntity(driver)
    DeleteEntity(vehicle)

    vehicle = nil
    vehicleBlip = nil
    radiusBlip = nil
    driver = nil
    IsCooldownActive = false
    noMoney = false
end

local function continueRideService()
    local playerPed = PlayerPedId()

    while true do
        Citizen.Wait(0)

        if Config.useMoney then
            ShowInfo("Estimated Cost: " .. estimatedCost, 0.75, 0.5)
        end

        DrawText2D(0.5, 0.85,
            '~w~[~g~' .. GetKeyStringFromKeyID(Config.startRide) .. '~w~]' .. Config.Locales["startRide"], 0.6, true)
        DrawText2D(0.5, 0.9,
            '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)

        if IsControlJustPressed(0, Config.startRide) then
            StopCurrentPlayingSpeech(driver)
            PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_BEGIN_JOURNEY", "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)

            TriggerServerEvent(
                "FearlessStudios-SwiftRideService:RemoveActiveRideForClients", VehToNet(vehicle))
            break
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end
    end

    local z = GetHeightmapTopZForPosition(waypoint.x, waypoint.y)

    TaskVehicleDriveToCoord(driver, vehicle, waypoint.x, waypoint.y, z, speedToDestination, 30.0,
        GetEntityModel(vehicle),
        drivingStyle, driverStopRange, 1.0)

    local timerMax = 2250
    local timer = timerMax

    local previousPosition = GetEntityCoords(vehicle, false) -- Store the initial position

    local totalDistanceMeters = 0.0
    local totalDistanceMiles = 0.0 -- Initialize total distance

    while IsWaypointActive() and GetVehiclePedIsIn(playerPed, false) == vehicle do
        Citizen.Wait(0)

        local currentPosition = GetEntityCoords(vehicle, false) -- Get current position
        local dist = #(previousPosition - currentPosition)      -- Calculate distance from previous position
        totalDistanceMeters += dist
        totalDistanceMiles += dist / 1609                       -- Update total distance
        previousPosition = currentPosition                      -- Update previous position

        local additionalMultiplier = 0.25 * (numPeopleInRide - 1)
        local totalMultiplier = baseRideMultiplier + additionalMultiplier

        if rideType == "taxi" then
            realCost = math.floor(Config.costPerMileTaxi * totalDistanceMiles * 100 + 0.5) / 100
        elseif rideType == "swift" then
            realCost = math.floor(Config.costPerMileSwift * totalDistanceMiles * 100 + 0.5) / 100
        elseif rideType == "swiftluxury" then
            realCost = math.floor(Config.costPerMileSwiftLuxury * totalDistanceMiles * 100 + 0.5) / 100 * totalMultiplier
        end

        local distText = GetDistanceToDestText(GetEntityCoords(vehicle, false), waypoint)
        local drivenDistText = GetFormatedDistanceText(totalDistanceMeters)

        if Config.useMoney then
            ShowInfo("Current Cost: $" .. realCost, 0.72, 0.5)
        end

        ShowInfo("Distance Driven: " .. drivenDistText, 0.75, 0.5)

        if Config.rideBanter then
            timer -= 1

            if timer <= 0 then
                StopCurrentPlayingSpeech(driver)
                PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_BANTER", "A_M_M_EASTSA_02_LATINO_FULL_01",
                    "SPEECH_PARAMS_FORCE_NORMAL", false)
                timer = timerMax
            end
        end

        if not isRushed then
            DrawText2D(0.5, 0.85,
                '~w~[~g~' .. GetKeyStringFromKeyID(Config.rushKey) .. '~w~]' .. Config.Locales["hurryUp"], 0.6, true)
            DrawText2D(0.5, 0.9,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6,
                true)
        else
            DrawText2D(0.5, 0.9,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6,
                true)
        end

        if IsControlJustPressed(0, Config.rushKey) and not isRushed then
            StopCurrentPlayingSpeech(driver)
            PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_SPEED_UP", "A_M_M_EASTSA_02_LATINO_FULL_01",
                "SPEECH_PARAMS_FORCE_NORMAL", false)
            isRushed = true

            SetDriveTaskDrivingStyle(driver, rushedDrivingStyle)
            SetDriveTaskCruiseSpeed(driver, rushedSpeed)
            SetDriverAggressiveness(driver, 1.0)
        end

        if IsControlJustPressed(0, Config.cancelKey) then
            cancelRide(playerPed, false)
            return
        end
    end

    endRide(playerPed)
end

local function startRideService(vehicleModel, driverModel, plate)
    numPeopleInRide = 1

    local playerPed = PlayerPedId()

    destinationCoords = GetEntityCoords(playerPed, false)

    vehicle, vehicleBlip, driver = spawnVehicleLogic(destinationCoords, vehicleModel, driverModel, plate, rideType)

    if vehicle ~= nil and vehicleBlip ~= nil and driver ~= nil then
        IsServiceActive = true

        SetBlockingOfNonTemporaryEvents(driver, true)
        SetEntityInvincible(driver, true)

        radiusBlip = AddBlipForRadius(destinationCoords.x, destinationCoords.y, destinationCoords.z,
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

            if IsPedInAnyVehicle(playerPed, true) then
                DrawNotification2D(Config.Locales["enteredVehicleCancel"], 2, "r")
                cancelRide(playerPed, true)
                return
            end

            DrawText2D(0.5, 0.85,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["cancelRide"], 0.6, true)

            local cancelDistance = #(GetEntityCoords(playerPed, false) - destinationCoords)
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

        ClearVehicleTasks(vehicle)
        TaskVehicleTempAction(driver, vehicle, 1, 30)

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

            local closestDoor = GetClosestVehicleDoor(playerPed, vehicle)

            if IsControlJustPressed(0, Config.getInKey) then
                -- If any seat is available, ask the player to enter the closest one
                if closestDoor ~= nil then
                    SetVehicleFixed(vehicle)
                    TaskEnterVehicle(playerPed, vehicle, 10000, closestDoor.index, 2.0, 1, 0)
                    RemoveBlip(radiusBlip)
                else
                    DrawNotification2D(Config.Locales["noSeatsAvailable"], 2, "r")
                    cancelRide(playerPed, false)
                end

                break
            end
        end

        while not IsPedInAnyVehicle(playerPed, false) and GetVehiclePedIsIn(playerPed, false) ~= vehicle do
            Citizen.Wait(0)
        end

        -- Notify that your able to also pickup others now
        TriggerServerEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", VehToNet(vehicle), PlayerPedId())
        SetTaxiLights(vehicle, false)
        StopCurrentPlayingSpeech(driver)
        PlayPedAmbientSpeechWithVoiceNative(driver, "TAXID_WHERE_TO", "A_M_M_EASTSA_02_LATINO_FULL_01",
            "SPEECH_PARAMS_FORCE_NORMAL", false)

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
            calculateRideCost(GetEntityCoords(vehicle, false), waypoint)

            TriggerServerEvent("FearlessStudios-SwiftRideService:MoneyCheck", PlayerPedId(), estimatedCost)
        else
            continueRideService()
        end
    else
        print("Error creating vehicle! Please try again")
        DrawNotification2D(Config.Locales["errorCreateVehicle"], 3, "r")
    end
end

RegisterCommand("callride", function(source, args, rawCommand)
    if IsRidingInOtherVehicle then
        DrawNotification2D(Config.Locales["inRideServiceVehicle"], 2, "r")
        return
    end

    if IsCooldownActive == true then
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

    if args[1] == 'taxi' then
        rideType = "taxi"
        startRideService(Config.taxiVehicles[math.random(1, #Config.taxiVehicles)], "a_m_y_stlat_01", "FS TAXI")
    elseif args[1] == 'swift' then
        rideType = "swift"
        startRideService(Config.swiftVehicles[math.random(1, #Config.swiftVehicles)], "a_m_y_stlat_01", "FS SWIFT")
    elseif args[1] == 'swiftluxury' then
        rideType = "swiftluxury"
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
    print(IsHeliService)
    if IsHeliService then
        return
    end

    if hasMoney then
        continueRideService()
    else
        noMoney = true
        cancelRide(PlayerPedId(), false)
    end
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:IncreasePlayersInRide", function(hasMoney)
    numPeopleInRide += 1
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:DecreasePlayersInRide", function(hasMoney)
    numPeopleInRide -= 1
end)

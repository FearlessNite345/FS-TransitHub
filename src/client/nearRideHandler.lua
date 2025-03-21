IsRidingInOtherVehicle = false
FS_Lib = exports['FS-Lib']

local activeRides = {}
local closestRideVehicle, closestRideDistance
local currentRideOwner = nil
local isHeliService = false

RegisterNetEvent("FearlessStudios-SwiftRideService:RegisterActiveRide", function(vehNetID, rideOwner, isHeli)
    print("Trying to add ride")
    currentRideOwner = rideOwner
    isHeliService = isHeli

    if PlayerPedId() == currentRideOwner then
        return
    end

    table.insert(activeRides, vehNetID)
    print("Ride Added")
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:RemoveActiveRide", function(vehNetIDToRemove)
    print("Trying to remove ride")
    for i, netID in ipairs(activeRides) do
        if netID == vehNetIDToRemove then
            table.remove(activeRides, i)
            print("Ride Removed")
            return -- Exiting loop once the element is removed
        end
    end
    print("Ride with netID " .. vehNetIDToRemove .. " not found")
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:ExitRide", function(vehNetID)
    local playerPed = PlayerPedId()

    if GetVehiclePedIsIn(playerPed, false) == NetworkGetEntityFromNetworkId(vehNetID) then
        TaskLeaveVehicle(playerPed, GetVehiclePedIsIn(playerPed, false), 0)
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if #activeRides > 0 and not IsServiceActive and not IsPedInAnyVehicle(PlayerPedId(), true) and not IsRidingInOtherVehicle then
            local playerCoords = GetEntityCoords(PlayerPedId(), false)

            closestRideVehicle, closestRideDistance = GetClosestVehicleInRangeWithCheck(playerCoords, 10.0)

            if closestRideVehicle ~= nil then
                FS_Lib:DrawText2D(0.5, 0.8,
                    '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~]' .. Config.Locales["enterVehicle"], 0.6,
                    true)

                local playerPed = PlayerPedId()
                local closestDoor = GetClosestVehicleDoor(playerPed, closestRideVehicle)

                if IsControlJustPressed(0, Config.getInKey) and closestDoor ~= nil then
                    TaskEnterVehicle(playerPed, closestRideVehicle, 10000, closestDoor.index, 2.0, 1, 0)

                    local startTime = GetGameTimer()
                    local timeout = 5000 -- 10 seconds

                    while not IsPedInAnyVehicle(playerPed, false) do
                        Wait(0)
                        if (GetGameTimer() - startTime) > timeout then
                            print("Timeout: failed to enter vehicle.")
                            break
                        end
                    end

                    if IsPedInAnyVehicle(playerPed, false) then
                        IsRidingInOtherVehicle = true
                        TriggerServerEvent("FearlessStudios-SwiftRideService:AddPlayerToRide", currentRideOwner)
                    else
                        -- Handle timeout/cleanup if needed
                    end
                end
            end
        end

        if IsRidingInOtherVehicle and IsPedInAnyVehicle(PlayerPedId(), false) and not isHeliService then

            FS_Lib:DrawText2D(0.5, 0.8,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["exitEarlyPassenger"],
                0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) and closestRideVehicle ~= nil then
                SetDriveTaskCruiseSpeed(GetPedInVehicleSeat(closestRideVehicle, -1), 0.00001)

                local playerPed = PlayerPedId()

                TaskLeaveVehicle(playerPed, closestRideVehicle, 0)

                local exitStart = GetGameTimer()
                local exitTimeout = 5000 -- 5 seconds

                while IsPedInAnyVehicle(playerPed, false) do
                    Wait(0)
                    if (GetGameTimer() - exitStart) > exitTimeout then
                        print("Timeout: failed to exit vehicle.")
                        break
                    end
                end

                TriggerServerEvent("FearlessStudios-SwiftRideService:RemovePlayerFromRide", currentRideOwner)

                Wait(5000)

                SetDriveTaskCruiseSpeed(GetPedInVehicleSeat(closestRideVehicle, -1), RideService.speedToDestination)

            end
        end

        if IsRidingInOtherVehicle and not IsPedInAnyVehicle(PlayerPedId(), false) then
            IsRidingInOtherVehicle = false
            TriggerServerEvent("FearlessStudios-SwiftRideService:RemovePlayerFromRide", currentRideOwner)
        end
    end
end)

function GetClosestVehicleInRangeWithCheck(coords, range)
    local closestVehicle = nil
    local closestDistance = range
    local vehicles = GetGamePool("CVehicle")

    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle, false)
        local distance = #(coords - vehCoords)

        if distance < closestDistance and IsVehicleNetIdInTable(NetworkGetNetworkIdFromEntity(vehicle), activeRides) then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    return closestVehicle, closestDistance
end

function IsVehicleNetIdInTable(netId, table)
    for _, id in ipairs(table) do
        if id == netId then
            return true
        end
    end
    return false
end

RegisterNetEvent("FearlessStudios-SwiftRideService:ExitRideVehicle", function()
    if IsRidingInOtherVehicle then
        IsRidingInOtherVehicle = false
        TaskLeaveVehicle(PlayerPedId(), closestRideVehicle, 0)
    end
end)

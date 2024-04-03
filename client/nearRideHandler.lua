IsRidingInOtherVehicle = false

local activeRides = {}
local closestRideVehicle, closestRideDistance
local currentRideOwner

RegisterNetEvent("FearlessStudios-SwiftRideService:RegisterActiveRide", function(vehNetID, rideOwner)
    print("Trying to add ride")
    currentRideOwner = rideOwner

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

RegisterNetEvent("FearlessStudios-SwiftRideService:ExitRide", function()
    local playerPed = PlayerPedId()

    TaskLeaveVehicle(playerPed, GetVehiclePedIsIn(playerPed, false), 0)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        --print(#activeRides)

        if #activeRides > 0 and not IsServiceActive and not IsPedInAnyVehicle(PlayerPedId(), true) and not IsRidingInOtherVehicle then
            local playerCoords = GetEntityCoords(PlayerPedId(), false)

            closestRideVehicle, closestRideDistance = GetClosestVehicleInRangeWithCheck(playerCoords, 10.0)

            print(closestRideVehicle, closestRideDistance)

            if closestRideVehicle ~= nil then
                DrawText2D(0.5, 0.8,
                    '~w~[~g~' .. GetKeyStringFromKeyID(Config.getInKey) .. '~w~]' .. Config.Locales["enterVehicle"], 0.6,
                    true)

                local playerPed = PlayerPedId()
                local closestDoor = GetClosestVehicleDoor(playerPed, closestRideVehicle)

                if IsControlJustPressed(0, Config.getInKey) and closestDoor ~= nil then
                    TaskEnterVehicle(playerPed, closestRideVehicle, 10000, closestDoor.index, 2.0, 1, 0)

                    while not IsPedInAnyVehicle(playerPed, false) do
                        Citizen.Wait(0)
                    end

                    IsRidingInOtherVehicle = true
                    TriggerServerEvent("FearlessStudios-SwiftRideService:AddPlayerToRide", currentRideOwner)
                end
            end
        end

        if IsRidingInOtherVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
            DrawText2D(0.5, 0.8,
                '~w~[~r~' .. GetKeyStringFromKeyID(Config.cancelKey) .. '~w~]' .. Config.Locales["exitEarlyPassenger"],
                0.6, true)

            if IsControlJustPressed(0, Config.cancelKey) and closestRideVehicle ~= nil then
                TaskVehicleTempAction(GetPedInVehicleSeat(closestRideVehicle, -1), closestRideVehicle, 1, 30)
                TaskLeaveVehicle(PlayerPedId(), closestRideVehicle, 0)
                TriggerServerEvent("FearlessStudios-SwiftRideService:RemovePlayerFromRide", currentRideOwner)
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

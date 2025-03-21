FS_Lib = exports['FS-Lib']

function table.keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

local lastSpeed = {} -- Store last applied speed per driver

function AdjustCruiseSpeed(driver, vehicle, destinationCoords, ranges, speeds)
    local rideCoords = GetEntityCoords(vehicle, false)
    local dist = #(rideCoords - destinationCoords)

    for i, range in ipairs(ranges) do
        if dist < range then
            local newSpeed = speeds[i]

            -- Check if the speed is different from the last applied speed
            if lastSpeed[driver] ~= newSpeed then
                print(range)
                SetDriveTaskCruiseSpeed(driver, newSpeed)
                lastSpeed[driver] = newSpeed
            end
            
            break
        end
    end
end

function ShowInfo(infoText, yPos, scale)
    FS_Lib:DrawText2D(0.015, yPos, infoText, scale, false)
end

function GetNumSeats(veh)
    local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    if not numSeats then
        numSeats = 0
    end
    return numSeats
end

function GetClosestVehicleDoor(ped, veh)
    local pos = GetEntityCoords(ped, false)
    local distance = 1000
    local dist = 0
    local closestDoor = nil

    for i = 0, GetNumSeats(veh) do
        local doorCoords = GetEntryPositionOfDoor(veh, i)
        dist = #(pos - doorCoords)
        if dist < distance then
            local seatIndex = i - 1
            if seatIndex == 0 or seatIndex == -1 then
                goto continue
            end

            local leftSideDoor = seatIndex == -1 or seatIndex == 1

            if IsVehicleSeatFree(veh, seatIndex) then
                closestDoor = {
                    index = seatIndex,
                    coords = doorCoords,
                    leftSide = leftSideDoor
                }
                distance = dist
            end
        end
        ::continue::
    end

    return closestDoor
end

-- New helper to format distance values.
function FormatDistance(dist)
    if ShouldUseMetricMeasurements() then
        if dist <= 1000 then
            return string.format("%dm", dist)
        else
            return string.format("%.2fkm", dist / 1000)
        end
    else
        local feet = math.floor((dist * 1.094) * 3) -- converting to feet
        if feet <= 500 then
            return string.format("%dft", feet)
        else
            return string.format("%.2fmi", feet / 5280)
        end
    end
end

function GetDistanceToDestText(yourCoords, destCoords)
    local dist = math.floor(#(yourCoords - destCoords)) -- Round down the distance value
    return FormatDistance(dist)
end

function GetFormatedDistanceText(distanceInMeters)
    return FormatDistance(distanceInMeters)
end

function SetupModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    SetModelAsNoLongerNeeded(model)
end

function RandomLimited(min, max, limit)
    local result
    repeat
        result = math.random(min, max)
    until math.abs(result) >= limit
    -- Remove print if not needed in production
    return result
end

function DrawNotification3D(coords, text, seconds, color)
    local startTime = GetGameTimer()
    local duration = seconds * 1000

    while GetGameTimer() - startTime < duration do
        FS_Lib:DrawText3D(coords.x, coords.y, coords.z, 0.6, '~' .. color .. '~' .. text)
        Citizen.Wait(0)
    end
end

function DrawNotification2D(text, seconds, color)
    local startTime = GetGameTimer()
    local duration = seconds * 1000

    while GetGameTimer() - startTime < duration do
        FS_Lib:DrawText2D(0.5, 0.8, '~' .. color .. '~' .. text, 0.6, true)
        Citizen.Wait(0)
    end
end

function ShowInfo(infoText, yPos, scale)
    DrawText2D(0.015, yPos, infoText, scale, false)
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

function GetDistanceToDestText(yourCoords, destCoords)
    local dist = math.floor(#(yourCoords - destCoords)) -- Round down the distance value
    local distText = ""
    if ShouldUseMetricMeasurements() then
        if dist <= 1000 then
            distText = dist .. "m"
        else
            distText = tonumber(string.format("%.2f", dist / 1000)) .. "km"
        end
    else
        dist = math.floor((dist * 1.094) * 3) -- Distance in feet
        if dist <= 500 then
            distText = dist .. "ft"
        else
            distText = tonumber(string.format("%.2f", dist / 5280)) .. "mi"
        end
    end

    return distText
end

function GetFormatedDistanceText(distanceInMeters)
    local distText = ""
    if ShouldUseMetricMeasurements() then
        if distanceInMeters <= 1000 then
            distText = distanceInMeters .. "m"
        else
            distText = tonumber(string.format("%.2f", distanceInMeters / 1000)) .. "km"
        end
    else
        distanceInMeters = math.floor((distanceInMeters * 1.094) * 3) -- Distance in feet
        if distanceInMeters <= 500 then
            distText = distanceInMeters .. "ft"
        else
            distText = tonumber(string.format("%.2f", distanceInMeters / 5280)) .. "mi"
        end
    end

    return distText
end

function SetupModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
    SetModelAsNoLongerNeeded(model)
end

function RandomLimited(min, max, limit)
    local result
    repeat
        result = math.random(min, max)
    until math.abs(result) >= limit
    print(result)
    return result
end

function DrawNotification3D(coords, text, seconds, color)
    local startTime = GetGameTimer()
    local duration = seconds * 1000

    while GetGameTimer() - startTime < duration do
        DrawText3D(coords.x, coords.y, coords.z, 0.6, '~' .. color .. '~' .. text)
        Citizen.Wait(0)
    end
end

function DrawNotification2D(text, seconds, color)
    local startTime = GetGameTimer()
    local duration = seconds * 1000

    while GetGameTimer() - startTime < duration do
        DrawText2D(0.5, 0.8, '~' .. color .. '~' .. text, 0.6, true)
        Citizen.Wait(0)
    end
end

function DrawText3D(x, y, z, scale, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextEntry("STRING")
        SetTextCentre(true)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function DrawText2D(x, y, text, scale, center)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    if center then SetTextJustification(0) end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

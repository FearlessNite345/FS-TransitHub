function GetClosestModelWithinDistance(maxDistance, items)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local closestModelCoords, closestModelHandle, closestTextOffset
    local closestDistance = maxDistance + 1

    local function checkAndUpdateClosest(modelHash, textOffset)
        local modelHandle = GetClosestObjectOfType(playerCoords.x,
                                                   playerCoords.y,
                                                   playerCoords.z, 10.0,
                                                   modelHash, false, false,
                                                   false)

        if DoesEntityExist(modelHandle) then
            local modelCoords = GetEntityCoords(modelHandle)
            local distance = #(playerCoords - modelCoords)

            if distance <= maxDistance and distance < closestDistance then
                closestModelCoords = modelCoords
                closestModelHandle = modelHandle
                closestTextOffset = textOffset
                closestDistance = distance
            end
        end
    end

    for _, modelPropData in ipairs(items) do
        checkAndUpdateClosest(modelPropData.model,
                              modelPropData.textHeightOffset)
    end

    return closestModelCoords, closestModelHandle, closestTextOffset
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

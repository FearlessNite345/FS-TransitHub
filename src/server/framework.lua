RegisterNetEvent("FearlessStudios-SwiftRideService:MoneyCheck", function(playerId, cost, destination)
    local src = source

    if Config.framework == "bigdaddy" then
        local account = exports["BigDaddy-Money"]:GetAccounts(src, playerId, -1)
        local data = json.decode(account)
        if (tonumber(data.bank) <= cost) then
            TriggerClientEvent("FearlessStudios-SwiftRideService:MoneyCheckResult", src, false, destination)
        else
            TriggerClientEvent("FearlessStudios-SwiftRideService:MoneyCheckResult", src, true, destination)
        end
    elseif Config.framework == "custom" then
        -- Put your framework stuff here
        TriggerClientEvent("FearlessStudios-SwiftRideService:MoneyCheckResult", src, true, destination)
    end
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:Pay", function(playerId, cost)
    local src = source

    if Config.framework == "bigdaddy" then
        local account = exports["BigDaddy-Money"]:GetAccounts(src, playerId, -1)
        local data = json.decode(account)
        if (tonumber(data.bank) >= tonumber(cost)) then
            local newbalance = tonumber(data.bank) - tonumber(cost)
            exports["BigDaddy-Money"]:UpdateTotals(src, newbalance, data.cash, data.dirty, -1)
        end
    elseif Config.framework == "custom" then
        -- Put your framework stuff here
    end
end)
RegisterNetEvent("FearlessStudios-SwiftRideService:AllExitRide", function()
    TriggerClientEvent("FearlessStudios-SwiftRideService:ExitRideVehicle", -1)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", function(vehNetID, rideOwner, isHeli)
    TriggerClientEvent("FearlessStudios-SwiftRideService:RegisterActiveRide", -1, vehNetID, rideOwner, isHeli)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:RemoveActiveRideForClients", function(vehNetID)
    TriggerClientEvent("FearlessStudios-SwiftRideService:RemoveActiveRide", -1, vehNetID)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:AllExitRide", function(vehNetID)
    TriggerClientEvent("FearlessStudios-SwiftRideService:ExitRide", -1, vehNetID)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:AddPlayerToRide", function(rideOwner)
    TriggerClientEvent("FearlessStudios-SwiftRideService:IncreasePlayersInRide", rideOwner)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:RemovePlayerFromRide", function(rideOwner)
    TriggerClientEvent("FearlessStudios-SwiftRideService:DecreasePlayersInRide", rideOwner)
end)

RegisterNetEvent("FearlessStudios-SwiftRideService:DebugPedTask", function(driver)
    print('Task Command: ' .. GetPedScriptTaskCommand(NetworkGetEntityFromNetworkId(driver)))
    print('Task Stage: ' .. GetPedScriptTaskStage(NetworkGetEntityFromNetworkId(driver)))
end)

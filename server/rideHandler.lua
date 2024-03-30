RegisterNetEvent("FearlessStudios-SwiftRideService:RegisterRideForClients", function(vehNetID, rideOwner)
    TriggerClientEvent("FearlessStudios-SwiftRideService:RegisterActiveRide", -1, vehNetID, rideOwner)
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

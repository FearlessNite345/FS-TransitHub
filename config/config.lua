Config = {}

-- General Settings --
Config.checkForUpdate = true -- Check for Updates
Config.rideBanter = true     -- Enable driver banter

-- Money Settings --
Config.useMoney = false               -- Charge for rides
Config.costPerMileTaxi = 2.00         -- Cost per Mile for taxi (cents)
Config.costPerMileSwift = 5.00        -- Cost per Mile for swift (cents)
Config.costPerMileSwiftLuxury = 40.00 -- Cost per Mile for luxury swift (cents)
Config.costPerMileHeli = 95.00        -- Cost per Mile for luxury swift (cents)

-- Ride Settings --
Config.cancelRadius = 40.0 -- Recommended cancel radius (meters)

-- Vehicle Types --

-- Taxi Vehicles: Must be 4+ door vehicles
Config.taxiVehicles = {
    "taxi"
}

-- Swift Vehicles: Must be 4+ door vehicles
Config.swiftVehicles = {
    "cavalcade3",
    "cognoscenti",
    "emperor"
}

-- Swift Luxury Vehicles: Must be 4+ door vehicles
Config.swiftLuxuryVehicles = {
    "stretch",
    "patriot2",
}

-- Swift Luxury Vehicles: Must be 4+ door vehicles
Config.heliVehicles = {
    "maverick",
    "frogger"
}

-- Key Bindings --
Config.startRide = 38 -- Start ride key
Config.cancelKey = 73 -- Cancel ride key
Config.getInKey = 23  -- Get in vehicle key
Config.rushKey = 74   -- Rush key

-- Locales --
Config.Locales = {
    ["rideCancel"] = "Ride Canceled",
    ["errorCreateVehicle"] = "Error creating vehicle. Please try again.",
    ["noSeatsAvailable"] = "No seats available. Cancelling...",
    ["leftServiceArea"] = "Left service area. Cancelling...",
    ["serviceAlreadyActive"] = "Service is already active.",
    ["arrivedDestination"] = "You have arrived at your destination.",
    ["chargedRideCost"] = "Your payment: $",
    ["noMoney"] = "You dont have enough money for this ride.",
    ["cancelRide"] = "Cancel Ride",
    ["exitEarlyPassenger"] = "Exit Ride",
    ["enterVehicle"] = "Enter Vehicle",
    ["setWaypoint"] = "Set a Waypoint",
    ["startRide"] = "Start Ride",
    ["hurryUp"] = "Hurry Up",
    ["setNewWaypoint"] = "Set a New Waypoint",
    ["cooldownActive"] = "Cooldown is active. Please wait.",
    ["inRideServiceVehicle"] = "Already riding in a ride service vehicle",
    ["inVehicle"] = "Unable to call ride service while in a vehicle.",
    ["enteredVehicleCancel"] = "Ride canceled due to entering a vehicle."
}

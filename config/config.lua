Config = {}

-- General Settings --
Config.checkForUpdate = true -- Would you like to Check for Updates?
Config.useMoney = true -- Enable to charge for rides
Config.rideBanter = true -- If you want the driver to talk to you while riding

-- Ride Settings --
Config.cancelRadius = 30.0 -- I recommend 30.0 as it gives enough to move around before canceling the call for the RIDE

-- Vehicle Types --
-- Taxi Vehicles: Must be 4+ door vehicles
Config.taxiVehicles = {
    "taxi"
}

-- Swift Vehicles: Must be 4+ door vehicles
Config.swiftVehicles = {
    "surge",
    "buffalo4"
}

-- Swift Luxury Vehicles: Must be 4+ door vehicles
Config.SwiftLuxuryVehicles = {
    "stretch",
    "patriot2"
}

-- Key Bindings --
Config.startRide = 38 -- Key to start ride
Config.cancelKey = 73 -- Key to cancel ride
Config.getInKey = 23 -- Key to get in vehicle
Config.rushKey = 74 -- Key to rush
Config.changeDestKey = 38 -- Key to change destination

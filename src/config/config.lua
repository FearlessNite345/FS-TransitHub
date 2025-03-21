Config = {}

-- General Settings --
Config.framework = "bigdaddy" -- "bigdaddy", "custom", "none"
Config.rideBanter = true            -- If enabled, your driver might throw in some snarky comments along the way.
Config.requireNearHeliPad = false   -- If true, you’ll need to be near a helipad to summon a helicopter. Otherwise, they'll just materialize like magic.

-- Money Settings --
Config.useMoney = true               -- If false, all rides are free—congrats, you found the glitch in capitalism!
Config.costPerMileTaxi = 5.00         -- Budget-friendly transport for those who like their rides cheap and mildly questionable.
Config.costPerMileSwift = 10.00        -- A step up—because sometimes, you deserve a car that doesn’t rattle.
Config.costPerMileSwiftLuxury = 25.00 -- Luxury service: The kind of ride where people might mistake you for someone important.
Config.costPerMileHeli = 150.00       -- Helicopter service: For when you’re too rich for stoplights.

-- Ride Settings --
Config.cancelRadius = 40.0 -- If you wander more than 40 meters from the pickup point, your driver will assume you're ghosting them and leave.
Config.slowApproachPlayer = true -- If false, your ride will show up like it’s competing in a demolition derby.
Config.slowApproachDestination = true -- If false, your arrival will be more of a crash landing than a smooth stop.

-- Vehicle Types --
Config.taxiVehicles = {
    "taxi"
}

Config.swiftVehicles = {
    "cavalcade3",
    "cognoscenti",
    "emperor"
}

Config.swiftLuxuryVehicles = {
    "stretch",
    "patriot2"
}

Config.heliVehicles = {
    "maverick"
}

-- Key Bindings --
Config.startRide = 38 -- Press this to summon your ride—hopefully, they don’t have road rage.
Config.cancelKey = 73 -- Cancel your ride before the driver starts questioning their life choices.
Config.getInKey = 23  -- Get in the car before your driver assumes you flaked.
Config.rushKey = 74   -- Tell the driver to floor it—because who needs speed limits?

-- Locales --
Config.Locales = {
    ["rideCancel"] = "Ride canceled. Hope you enjoy walking!",
    ["errorCreateVehicle"] = "Vehicle creation failed. Try again, or just accept your fate.",
    ["noSeatsAvailable"] = "No seats available. Did you order a clown car?",
    ["leftServiceArea"] = "You wandered off too far. Ride canceled. Good luck out there.",
    ["notNearPickupZone"] = "You're too far from the pickup zone. Teleportation not included.",
    ["serviceAlreadyActive"] = "You already have a ride on the way. Patience, my friend.",
    ["arrivedDestination"] = "You’ve arrived! Now go do something productive.",
    ["chargedRideCost"] = "Your ride cost: $",
    ["noMoney"] = "You're broke. No money, no ride.",
    ["cancelRide"] = "Cancel Ride",
    ["exitEarlyPassenger"] = "Exit Ride",
    ["enterVehicle"] = "Enter Vehicle",
    ["setWaypoint"] = "Pick a destination before your driver starts making random stops.",
    ["startRide"] = "Start Ride",
    ["hurryUp"] = "Hurry Up",
    ["cooldownActive"] = "Cooldown active. Take a deep breath.",
    ["inRideServiceVehicle"] = "You're already in a ride. No need to double-dip.",
    ["inVehicle"] = "You can't call a ride while already in one. Try walking instead.",
    ["enteredVehicleCancel"] = "Ride canceled because you got in another car. Commitment issues?"
}

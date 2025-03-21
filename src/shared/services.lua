Services = {
    isServiceActive = false,
    isCooldownActive = false,
    isHeliService = false,
    realCost = 0,
    estimatedCost = 0,
}

RideService = {
    isRushed = false,
    noMoney = false,

    -- Blip IDs
    limoBlip = 724,
    taxiBlip = 198,
    swiftBlip = 326,

    -- Shared entities and state
    driver = nil,
    vehicle = nil,
    vehicleBlip = nil,
    radiusBlip = nil,
    destinationCoords = nil,
    waypoint = nil,
    rideType = nil,
    baseRideMultiplier = 1,
    numPeopleInRide = 1,

    -- Ride parameters
    driverStopRange = 1.0, -- tell the driver to get close while the stopRange is the actual threshold
    stopRange = 3.5,
    drivingStyle = 786603,
    rushedDrivingStyle = 1074528805,
    speedToPlayer = 18.0,
    speedToDestination = 25.0,
    rushedSpeed = 37.0,
    minSpawnDistance = 0,
    maxSpawnDistance = 250.0,
}

HeliService = {
    radiusBlip = nil,
    waypoint = nil,
    pilot = nil,
    heli = nil,
    heliBlip = nil,
    flareObject = nil,
    noMoney = false,
    heliSpeedToPlayer = 30.0,
    heliSpeedToWaypoint = 35.0
}

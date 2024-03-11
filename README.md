# FearlessStudios-FiveMTemplate

Hey there! Welcome to the FearlessStudios-FiveMTemplate. This is your go-to setup for crafting Lua resources tailored for FiveM.

## Utilizing Version Checker

This script provides a version-checking mechanism for your FiveM resource by comparing the current version with the latest version available on a specified GitHub repository.

#### Configuration

Before using the `versionCheck.lua` script, make sure to customize the following variables:

```lua
local authorName = 'CHANGEME'
local resourceName = 'CHANGEME'

local githubUsername = 'CHANGEME'
local githubRepo = 'CHANGEME'
local githubVersionFilename = 'CHANGEME'
```

## Utilizing Helper Functions

#### GetClosestModelWithinDistance

This function retrieves information about the closest model within a specified distance from the player.

```lua
local maxDistance = 10.0
local items = {
    { model = `prop_gas_pump_1a`, textHeightOffset = 1.2 },
    { model = `prop_gas_pump_old2`, textHeightOffset = 1.2 },
    -- Add more model data as needed
}

local closestModelCoords, closestModelHandle, closestTextOffset = GetClosestModelWithinDistance(maxDistance, items)
```

##### You can now use the retrieved information as needed
- model inside of items is the model hash for FiveM  
- closestModelCoords: Coordinates of the closest model
- closestModelHandle: Handle of the closest model
- closestTextOffset: Text height offset associated with the closest model (useful for drawing text on the model)

#### DrawNotification3D

Draws a 3D notification at the specified coordinates.

##### Parameters

- `coords` (table): The 3D coordinates where the notification should be displayed.
- `text` (string): The text of the notification.
- `seconds` (number): The duration of the notification in seconds.
- `color` (string): The color of the notification. Use one of the predefined colors. Refer to [FiveM Text Formatting](https://docs.fivem.net/docs/game-references/text-formatting/) for color codes.

##### Example

```lua
DrawNotification3D({ x = 10.0, y = 20.0, z = 30.0 }, "This is a 3D notification", 5, "g")
```

#### DrawNotification2D

Draws a 2D notification at the center of the screen.

##### Parameters

- `text` (string): The text of the notification.
- `seconds` (number): The duration of the notification in seconds.
- `color` (string): The color of the notification. Use one of the predefined colors. Refer to [FiveM Text Formatting](https://docs.fivem.net/docs/game-references/text-formatting/) for color codes.

##### Example

```lua
DrawNotification2D("This is a 2D notification", 5, "y")
```

#### DrawText3D

This function draws text in 3D space at the specified coordinates.

```lua
local x, y, z = 123.45, 67.89, 10.0
local scale = 0.5
local text = "This is a 3D text example"

DrawText3D(x, y, z, scale, text)
```

#### DrawText2D

This function draws text on the screen at 2D coordinates.

```lua
local x, y = 0.5, 0.8
local text = "This is a 2D text example"
local scale = 0.6
local center = true -- Set to false for left-aligned text

DrawText2D(x, y, text, scale, center)
```

## Contributing

Your contributions are invaluable! If you encounter a bug or have a brilliant enhancement in mind, please don't hesitate to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE), providing you with the freedom to integrate it seamlessly into your own projects.

Happy coding!

# CascadeUI 2.0

A clean, simple UI library for Roblox exploits inspired by CascadeUI.

## Features

- Sleek design with a dark theme
- Tab system for organizing different sections
- Various UI elements including:
  - Toggle
  - Button
  - Slider
  - Dropdown (auto close on outside click)
  - ColorPicker
  - Label
  - Textbox
  - Keybind
  - ProgressBar
  - Divider
- Optional `Flag` + config persistence (save/load)
- Optional `Tooltip` on elements
- Window-level APIs (Notify, SaveConfig, LoadConfig, GetFlag, SetFlag, Destroy)
- Window toggle key (default `RightShift`, configurable)

## Getting Started

### Booting library:

```lua
local CascadeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MermiXO/CascadeUI-2.0/refs/heads/main/src.lua"))()
```

### Creating a Window

```lua
local Window = CascadeUI:CreateWindow({
    Title = "CascadeUI",
    Size = UDim2.new(0, 550, 0, 400),
    Position = UDim2.new(0.5, -275, 0.5, -200),
    -- ToggleKey = Enum.KeyCode.RightShift, -- default
    -- ToggleKey = false, -- disable toggle key
})
```

### Creating Tabs

```lua
local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")
```

### Creating Sections

```lua
local GeneralSection = MainTab:CreateSection("General")
```

### Creating UI Elements

All elements accept optional:

- `Tooltip = "..."`
- `Flag = "SomeKey"` (for config persistence)

#### Toggle

```lua
local Toggle = Section:CreateToggle({
    Name = "Toggle",
    Default = false,
    Flag = "Example_Toggle",
    Tooltip = "Toggle supports Flag + Tooltip",
    Callback = function(Value)
        print("Toggle value:", Value)
    end
})

Toggle:Set(true)

local value = Toggle:Get()
```

#### Button

```lua
local Button = Section:CreateButton({
    Name = "Button",
    Callback = function()
        print("Button clicked!")
    end
})

Button:Fire()
```

#### Slider

```lua
local Slider = Section:CreateSlider({
    Name = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "Example_Slider",
    Tooltip = "Slider supports Flag + Tooltip",
    Callback = function(Value)
        print("Slider value:", Value)
    end
})

Slider:Set(75)

local value = Slider:Get()
```

#### Dropdown

```lua
local Dropdown = Section:CreateDropdown({
    Name = "Dropdown",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Flag = "Example_Dropdown",
    Tooltip = "Dropdown closes on outside click",
    Callback = function(Option)
        print("Selected option:", Option)
    end
})

Dropdown:Set("Option 2")

local option = Dropdown:Get()

Dropdown:Refresh({"New Option 1", "New Option 2"}, false)
```

#### Color Picker

```lua
local ColorPicker = Section:CreateColorPicker({
    Name = "Color Picker",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "Example_Color",
    Tooltip = "ColorPicker supports Flag + Tooltip",
    Callback = function(Color)
        print("Selected color:", Color)
    end
})

ColorPicker:Set(Color3.fromRGB(0, 255, 0))

local color = ColorPicker:Get()
```

#### Label

```lua
local Label = Section:CreateLabel({
    Name = "Label",
    Text = "Hello",
    Tooltip = "This is a label element"
})

Label:Set("Updated")
print(Label:Get())
```

#### Textbox

```lua
local Textbox = Section:CreateTextbox({
    Name = "Textbox",
    Default = "",
    Placeholder = "Type here...",
    Flag = "Example_Textbox",
    Tooltip = "Textbox supports Flag + Tooltip",
    Callback = function(text)
        print("Textbox:", text)
    end
})

Textbox:Set("Hi")
print(Textbox:Get())
```

#### Keybind

```lua
local Keybind = Section:CreateKeybind({
    Name = "Keybind",
    Default = Enum.KeyCode.G,
    Flag = "Example_Keybind",
    Tooltip = "Click to set. Press Backspace/Delete to clear.",
    Callback = function(key)
        print("Keybind fired:", key)
    end,
    ChangedCallback = function(newKey)
        print("Keybind changed:", newKey)
    end
})

Keybind:Set(Enum.KeyCode.H)
print(Keybind:Get())
```

#### ProgressBar

```lua
local Progress = Section:CreateProgressBar({
    Name = "Progress",
    Min = 0,
    Max = 100,
    Default = 25,
    Flag = "Example_Progress",
    Tooltip = "ProgressBar supports Set/Get + Flag"
})

Progress:Set(60)
print(Progress:Get())
```

#### Divider

```lua
local Divider = Section:CreateDivider({
    Text = "Inputs",
    Tooltip = "Divider element"
})
```

## Window APIs

```lua
Window:Notify({
    Title = "CascadeUI",
    Text = "Hello",
    Duration = 2
})

-- Flags
Window:SetFlag("Example_Textbox", "Loaded from SetFlag")
print(Window:GetFlag("Example_Textbox"))

-- Config
local json = Window:SaveConfig() -- returns JSON string
Window:LoadConfig(json) -- accepts JSON string, table, or file path (if supported)
```

## Example

Check out `example.lua` if you wanna test CascadeUI.

## Credits
- Inspired by SquidGurr

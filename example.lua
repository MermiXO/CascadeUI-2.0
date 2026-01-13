local CascadeUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/MermiXO/CascadeUI-2.0/refs/heads/main/src.lua'))()

local Window = CascadeUI:CreateWindow({
    Title = "CascadeUI",
    Size = UDim2.new(0, 550, 0, 400),
    Position = UDim2.new(0.5, -275, 0.5, -200)
})

local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")

local GeneralSection = MainTab:CreateSection("Test Stuff")
local SettingsSection = SettingsTab:CreateSection("Test Stuff")

Window:Notify({
    Title = "CascadeUI",
    Text = "Loaded example.lua",
    Duration = 2
})

local Label = GeneralSection:CreateLabel({
    Name = "Label",
    Text = "Hello from CascadeUI",
    Tooltip = "This is a label element"
})

local Divider = GeneralSection:CreateDivider({
    Name = "Divider",
    Text = "Inputs",
    Tooltip = "Divider element"
})

local Textbox = GeneralSection:CreateTextbox({
    Name = "Textbox",
    Default = "",
    Placeholder = "Type something...",
    Flag = "Example_Textbox",
    Tooltip = "Textbox supports Flag + Tooltip",
    Callback = function(text)
        print("Textbox:", text)
    end
})

local Keybind = GeneralSection:CreateKeybind({
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

local Toggle = GeneralSection:CreateToggle({
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

local Button = GeneralSection:CreateButton({
    Name = "Button",
    Callback = function()
        print("Button clicked!")
    end
})

Button:Fire()

local Slider = GeneralSection:CreateSlider({
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

local Dropdown = GeneralSection:CreateDropdown({
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

local ColorPicker = SettingsSection:CreateColorPicker({
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

local Progress = SettingsSection:CreateProgressBar({
    Name = "Progress",
    Min = 0,
    Max = 100,
    Default = 25,
    Flag = "Example_Progress",
    Tooltip = "ProgressBar supports Set/Get + Flag"
})

Progress:Set(60)

Window:SetFlag("Example_Textbox", "Loaded from SetFlag")

local saved = Window:SaveConfig()
print("Saved config JSON:", saved)

Window:LoadConfig(saved)
print("Loaded flags:", {
    Toggle = Window:GetFlag("Example_Toggle"),
    Slider = Window:GetFlag("Example_Slider"),
    Dropdown = Window:GetFlag("Example_Dropdown"),
    Textbox = Window:GetFlag("Example_Textbox"),
    Keybind = Window:GetFlag("Example_Keybind"),
    Progress = Window:GetFlag("Example_Progress"),
})

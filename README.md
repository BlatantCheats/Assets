# Please excuse that this readme was made with AI. I am not the best at english.

# Quartz UI Library

A lightweight, customizable Roblox UI library built with a clean dark design and simple API.

## Features

- Draggable window
- Scrollable tabs and component lists
- Multiple tabs
- Toggle components
- Button components
- Slider components
- Dropdown components
- Textbox components
- Customizable colors and sizing
- Component methods for updating elements
- Comfortaa font
- Rounded UI design

## Installation

Load Quartz using:

```lua
local Quartz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/obsidianmodmenu/Quartz-UI-Lib/main/Quartz.lua"
))()
```

## Getting Started

Create a window and add tabs:

```lua
local Window = Quartz:CreateWindow({
    Title = "Quartz",
    Size = UDim2.fromOffset(650, 430)
})

local Main = Window:CreateTab("Main")
local Settings = Window:CreateTab("Settings")
```

## Components

### Button

```lua
Main:AddButton({
    Title = "Example Button",
    Callback = function()
        print("Button clicked!")
    end
})
```

### Toggle

```lua
Main:AddToggle({
    Title = "Example Toggle",
    Default = false,
    Callback = function(value)
        print(value)
    end
})
```

### Slider

```lua
Main:AddSlider({
    Title = "Example Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print(value)
    end
})
```

### Dropdown

```lua
Main:AddDropdown({
    Title = "Example Dropdown",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Callback = function(value)
        print(value)
    end
})
```

### Textbox

```lua
Main:AddTextbox({
    Title = "Example Textbox",
    Placeholder = "Enter text...",
    Callback = function(value)
        print(value)
    end
})
```

## Component Methods

Components return objects that can be updated after creation.

| Component | Methods |
|---|---|
| Toggle | `Set()`, `Get()`, `SetTitle()` |
| Button | `SetTitle()`, `SetCallback()` |
| Slider | `Set()`, `Get()`, `SetTitle()` |
| Dropdown | `Set()`, `Get()`, `SetTitle()`, `SetOptions()` |
| Textbox | `Set()`, `Get()`, `SetTitle()` |

Example:

```lua
local Toggle = Main:AddToggle({
    Title = "Example",
    Callback = function(value)
        print(value)
    end
})

Toggle:Set(true)
```

## Window Methods

| Method | Description |
|---|---|
| `SetTitle(title)` | Changes the window title |
| `SetVisible(boolean)` | Shows or hides the window |
| `SetSize(UDim2)` | Changes the window size |
| `Destroy()` | Removes the window |

## Tab Methods

| Method | Description |
|---|---|
| `SetName(name)` | Renames a tab |
| `Select()` | Selects a tab |
| `ScrollToTop()` | Scrolls the tab to the top |

## Customization

Quartz supports theme customization through its theme settings.

Available theme properties:

- `Background`
- `Header`
- `Component`
- `Separator`
- `Text`
- `Accent`
- `Disabled`
- `Track`

## Example

```lua
local Quartz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/obsidianmodmenu/Quartz-UI-Lib/main/Quartz.lua"
))()

local Window = Quartz:CreateWindow({
    Title = "My Quartz UI",
    Size = UDim2.fromOffset(650, 430)
})

local Main = Window:CreateTab("Main")

Main:AddButton({
    Title = "Print Hello",
    Callback = function()
        print("Hello from Quartz!")
    end
})

Main:AddToggle({
    Title = "Example Toggle",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end
})
```

## Repository

[GitHub - Quartz UI Lib](https://github.com/obsidianmodmenu/Quartz-UI-Lib)

## License

See the repository's license file for usage and distribution terms.

---

**Quartz UI Library**  
Made by obsidianmodmenu.

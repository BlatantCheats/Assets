local Quartz = {}
Quartz.__index = Quartz

Quartz.Version = "1.0.0"

Quartz.Theme = {
    Background = Color3.fromRGB(30, 30, 39),
    Header = Color3.fromRGB(50, 51, 66),
    Component = Color3.fromRGB(50, 51, 66),
    Divider = Color3.fromRGB(79, 81, 87),
    Text = Color3.fromRGB(255, 255, 255),
    MutedText = Color3.fromRGB(175, 177, 188),
    Enabled = Color3.fromRGB(81, 255, 87),
    Disabled = Color3.fromRGB(255, 94, 97),
    Track = Color3.fromRGB(79, 81, 87),
    Slider = Color3.fromRGB(255, 255, 255),
    Input = Color3.fromRGB(35, 36, 46),
    Font = Enum.Font.Gotham,
    CornerRadius = 6,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local function cloneTable(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function mergeTheme(overrides)
    local theme = cloneTable(Quartz.Theme)
    if type(overrides) == "table" then
        for key, value in pairs(overrides) do
            theme[key] = value
        end
    end
    return theme
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6)
    }, parent)
end

local function textLabel(parent, text, size, position, theme, fontSize)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(text or ""),
        TextColor3 = theme.Text,
        Font = theme.Font,
        TextSize = fontSize or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = size,
        Position = position or UDim2.new(),
    }, parent)
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local success, err = pcall(callback, ...)
    if not success then
        warn("[Quartz] Callback error: " .. tostring(err))
    end
end

local function makeComponent(tab, title, height)
    local theme = tab.Window.Theme
    local frame = create("Frame", {
        Name = "QuartzComponent",
        BackgroundColor3 = theme.Component,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, height),
    }, tab.Content)

    corner(frame, theme.CornerRadius)

    local titleLabel = textLabel(
        frame,
        title or "Component",
        UDim2.new(1, -20, 0, 24),
        UDim2.new(0, 10, 0, 5),
        theme,
        14
    )

    local component = {
        Frame = frame,
        TitleLabel = titleLabel,
        Tab = tab,
        Connections = {},
        Destroyed = false,
    }

    function component:SetTitle(newTitle)
        self.TitleLabel.Text = tostring(newTitle or "")
    end

    function component:SetName(newName)
        self.Frame.Name = tostring(newName or "QuartzComponent")
    end

    function component:SetVisible(visible)
        self.Frame.Visible = visible == true
    end

    function component:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true

        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end

        self.Frame:Destroy()
    end

    table.insert(tab.Components, component)
    return component
end

function Quartz:CreateWindow(configuration)
    local config
    if type(configuration) == "string" then
        config = { Title = configuration }
    elseif type(configuration) == "table" then
        config = configuration
    else
        config = {}
    end

    local player = Players.LocalPlayer
    if not player then
        error("[Quartz] CreateWindow must be called from a client script.")
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local theme = mergeTheme(config.Theme)

    local gui = create("ScreenGui", {
        Name = config.GuiName or "QuartzUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 20,
    }, playerGui)

    local window = {
        Gui = gui,
        Theme = theme,
        Tabs = {},
        Components = {},
        SelectedTab = nil,
        Destroyed = false,
    }

    local width = config.Width or 650
    local height = config.Height or 430

    local main = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
    }, gui)
    corner(main, theme.CornerRadius + 2)

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = theme.Header,
        BorderSizePixel = 0,
    }, main)
    corner(header, theme.CornerRadius + 2)

    local headerCover = create("Frame", {
        Name = "HeaderBottom",
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = theme.Header,
        BorderSizePixel = 0,
    }, header)

    local title = textLabel(
        header,
        config.Title or "Quartz",
        UDim2.new(1, -65, 1, 0),
        UDim2.new(0, 15, 0, 0),
        theme,
        16
    )
    title.Font = theme.Font

    local closeButton = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = theme.Disabled,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = theme.Text,
        Font = theme.Font,
        TextSize = 20,
        AutoButtonColor = true,
    }, header)
    corner(closeButton, 5)

    local sidebar = create("Frame", {
        Name = "Tabs",
        Position = UDim2.new(0, 10, 0, 52),
        Size = UDim2.new(0, 132, 1, -62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, main)

    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)

    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        Position = UDim2.new(0, 152, 0, 52),
        Size = UDim2.new(1, -162, 1, -62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, main)

    window.Main = main
    window.Header = header
    window.TitleLabel = title
    window.Sidebar = sidebar
    window.ContentHolder = contentHolder

    local dragging = false
    local dragInput
    local dragStart
    local startPosition
    local dragConnection

    local headerInput = header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            if dragConnection then
                dragConnection:Disconnect()
            end

            dragConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local moveConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    table.insert(window.Components, {
        Destroy = function()
            headerInput:Disconnect()
            moveConnection:Disconnect()
            if dragConnection then
                dragConnection:Disconnect()
            end
        end
    })

    closeButton.Activated:Connect(function()
        window:SetVisible(false)
    end)

    function window:SetTitle(newTitle)
        self.TitleLabel.Text = tostring(newTitle or "")
    end

    function window:SetVisible(visible)
        self.Gui.Enabled = visible == true
    end

    function window:Toggle()
        self.Gui.Enabled = not self.Gui.Enabled
    end

    function window:SetSize(newWidth, newHeight)
        self.Main.Size = UDim2.fromOffset(newWidth, newHeight)
    end

    function window:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true

        for _, item in ipairs(self.Components) do
            if item.Destroy then
                item:Destroy()
            end
        end

        for _, tab in ipairs(self.Tabs) do
            tab:Destroy()
        end

        self.Gui:Destroy()
    end

    function window:CreateTab(tabName)
        local tab = {
            Name = tostring(tabName or "Tab"),
            Window = self,
            Components = {},
            Destroyed = false,
        }

        local tabButton = create("TextButton", {
            Name = "TabButton",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.Component,
            BorderSizePixel = 0,
            Text = tab.Name,
            TextColor3 = theme.Text,
            Font = theme.Font,
            TextSize = 13,
            AutoButtonColor = true,
        }, sidebar)
        corner(tabButton, theme.CornerRadius)

        local content = create("ScrollingFrame", {
            Name = tab.Name .. "Content",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Divider,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, contentHolder)

        local padding = create("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 6),
        }, content)

        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, content)

        tab.Button = tabButton
        tab.Content = content
        tab.Layout = layout

        function tab:Select()
            if self.Destroyed then
                return
            end

            for _, other in ipairs(self.Window.Tabs) do
                other.Content.Visible = other == self
                other.Button.BackgroundColor3 = other == self
                    and theme.Header
                    or theme.Component
            end

            self.Window.SelectedTab = self
        end

        function tab:SetName(newName)
            self.Name = tostring(newName or "Tab")
            self.Button.Text = self.Name
            self.Content.Name = self.Name .. "Content"
        end

        function tab:SetVisible(visible)
            self.Button.Visible = visible == true
            if not visible and self.Content.Visible then
                for _, other in ipairs(self.Window.Tabs) do
                    if other ~= self and other.Button.Visible then
                        other:Select()
                        break
                    end
                end
            end
        end

        function tab:ScrollToTop()
            self.Content.CanvasPosition = Vector2.new(0, 0)
        end

        function tab:Destroy()
            if self.Destroyed then
                return
            end
            self.Destroyed = true

            for _, component in ipairs(self.Components) do
                component:Destroy()
            end

            self.Button:Destroy()
            self.Content:Destroy()

            if self.Window.SelectedTab == self then
                self.Window.SelectedTab = nil
                for _, other in ipairs(self.Window.Tabs) do
                    if other ~= self and not other.Destroyed then
                        other:Select()
                        break
                    end
                end
            end
        end

        function tab:AddToggle(options)
            options = options or {}
            local component = makeComponent(self, options.Title or options.Name or "Toggle", 42)
            local value = options.Default == true

            local indicator = create("Frame", {
                Name = "Indicator",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 4),
                Size = UDim2.fromOffset(25, 25),
                BackgroundColor3 = value and theme.Enabled or theme.Disabled,
                BorderSizePixel = 0,
            }, component.Frame)
            corner(indicator, 4)

            local button = create("TextButton", {
                Name = "ToggleButton",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
            }, component.Frame)

            local function setValue(newValue, callback)
                value = newValue == true
                indicator.BackgroundColor3 = value and theme.Enabled or theme.Disabled
                if callback then
                    safeCallback(options.Callback, value)
                end
            end

            button.Activated:Connect(function()
                setValue(not value, true)
            end)

            function component:Set(newValue)
                setValue(newValue, false)
            end

            function component:Get()
                return value
            end

            function component:SetCallback(callback)
                options.Callback = callback
            end

            component.Indicator = indicator
            component.Button = button
            return component
        end

        function tab:AddButton(options)
            options = options or {}
            local component = makeComponent(self, options.Title or options.Name or "Button", options.Height or 42)

            local button = create("TextButton", {
                Name = "ActionButton",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = true,
            }, component.Frame)

            button.Activated:Connect(function()
                safeCallback(options.Callback)
            end)

            function component:Press()
                safeCallback(options.Callback)
            end

            function component:SetCallback(callback)
                options.Callback = callback
            end

            component.Button = button
            return component
        end

        function tab:AddSlider(options)
            options = options or {}
            local minimum = tonumber(options.Min) or 0
            local maximum = tonumber(options.Max) or 100
            if maximum < minimum then
                minimum, maximum = maximum, minimum
            end

            local decimals = math.max(0, math.floor(tonumber(options.Decimals) or 0))
            local value = math.clamp(tonumber(options.Default) or minimum, minimum, maximum)
            local component = makeComponent(self, options.Title or options.Name or "Slider", 79)

            local valueLabel = textLabel(
                component.Frame,
                tostring(value),
                UDim2.new(0, 45, 0, 20),
                UDim2.new(1, -55, 0, 6),
                theme,
                12
            )
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.TextColor3 = theme.MutedText

            local track = create("Frame", {
                Name = "Track",
                Position = UDim2.new(0, 7, 0, 48),
                Size = UDim2.new(1, -14, 0, 4),
                BackgroundColor3 = theme.Track,
                BorderSizePixel = 0,
            }, component.Frame)
            corner(track, 4)

            local fill = create("Frame", {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = theme.Slider,
                BorderSizePixel = 0,
            }, track)
            corner(fill, 4)

            local knob = create("Frame", {
                Name = "Knob",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(11, 11),
                BackgroundColor3 = theme.Slider,
                BorderSizePixel = 0,
            }, track)
            corner(knob, 6)

            local hitbox = create("TextButton", {
                Name = "SliderInput",
                Position = UDim2.new(0, -4, 0, -9),
                Size = UDim2.new(1, 8, 0, 22),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, track)

            local draggingSlider = false

            local function formatValue(number)
                return string.format("%." .. decimals .. "f", number)
            end

            local function setValue(newValue, callback)
                newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
                local multiplier = 10 ^ decimals
                value = math.clamp(math.floor(newValue * multiplier + 0.5) / multiplier, minimum, maximum)

                local alpha = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                valueLabel.Text = formatValue(value)

                if callback then
                    safeCallback(options.Callback, value)
                end
            end

            local function updateFromInput(input)
                local alpha = math.clamp(
                    (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
                    0,
                    1
                )
                setValue(minimum + (maximum - minimum) * alpha, true)
            end

            table.insert(component.Connections, hitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateFromInput(input)
                end
            end))

            table.insert(component.Connections, UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    updateFromInput(input)
                end
            end))

            table.insert(component.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end))

            function component:Set(newValue)
                setValue(newValue, false)
            end

            function component:Get()
                return value
            end

            function component:SetCallback(callback)
                options.Callback = callback
            end

            component.Track = track
            component.Fill = fill
            component.Knob = knob
            setValue(value, false)
            return component
        end

        function tab:AddDropdown(options)
            options = options or {}
            local values = options.Options or {}
            local selected = options.Default
            local expanded = false
            local component = makeComponent(self, options.Title or options.Name or "Dropdown", 42)

            local selectedLabel = textLabel(
                component.Frame,
                tostring(selected or options.Placeholder or "Select..."),
                UDim2.new(1, -20, 0, 20),
                UDim2.new(0, 10, 0, 20),
                theme,
                12
            )
            selectedLabel.TextColor3 = theme.MutedText

            local arrow = textLabel(
                component.Frame,
                "⌄",
                UDim2.fromOffset(18, 20),
                UDim2.new(1, -25, 0, 19),
                theme,
                16
            )
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local toggleButton = create("TextButton", {
                Name = "DropdownButton",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
            }, component.Frame)

            local optionsFrame = create("Frame", {
                Name = "Options",
                Position = UDim2.new(0, 0, 1, 5),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 5,
            }, component.Frame)
            corner(optionsFrame, theme.CornerRadius)

            local optionLayout = create("UIListLayout", {
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, optionsFrame)

            local optionPadding = create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            }, optionsFrame)

            local optionButtons = {}

            local function refreshOptions()
                for _, button in ipairs(optionButtons) do
                    button:Destroy()
                end
                table.clear(optionButtons)

                for index, option in ipairs(values) do
                    local optionValue = option
                    local button = create("TextButton", {
                        Name = "Option",
                        LayoutOrder = index,
                        Size = UDim2.new(1, 0, 0, 27),
                        BackgroundColor3 = theme.Component,
                        BorderSizePixel = 0,
                        Text = tostring(optionValue),
                        TextColor3 = theme.Text,
                        Font = theme.Font,
                        TextSize = 12,
                        AutoButtonColor = true,
                        ZIndex = 6,
                    }, optionsFrame)
                    corner(button, 4)

                    button.Activated:Connect(function()
                        selected = optionValue
                        selectedLabel.Text = tostring(optionValue)
                        selectedLabel.TextColor3 = theme.Text
                        expanded = false
                        optionsFrame.Visible = false
                        optionsFrame.Size = UDim2.new(1, 0, 0, 0)
                        arrow.Text = "⌄"
                        safeCallback(options.Callback, selected)
                    end)

                    table.insert(optionButtons, button)
                end
            end

            local function setExpanded(state)
                expanded = state
                optionsFrame.Visible = expanded
                arrow.Text = expanded and "⌃" or "⌄"

                if expanded then
                    local height = math.min(#values * 30 + 8, options.MaxHeight or 150)
                    optionsFrame.Size = UDim2.new(1, 0, 0, height)
                else
                    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
                end
            end

            toggleButton.Activated:Connect(function()
                setExpanded(not expanded)
            end)

            function component:Set(newValue)
                selected = newValue
                selectedLabel.Text = tostring(newValue or options.Placeholder or "Select...")
                selectedLabel.TextColor3 = newValue == nil and theme.MutedText or theme.Text
            end

            function component:Get()
                return selected
            end

            function component:SetOptions(newOptions)
                values = type(newOptions) == "table" and newOptions or {}
                refreshOptions()
                if selected ~= nil and not table.find(values, selected) then
                    selected = nil
                    selectedLabel.Text = tostring(options.Placeholder or "Select...")
                    selectedLabel.TextColor3 = theme.MutedText
                end
                setExpanded(false)
            end

            function component:SetCallback(callback)
                options.Callback = callback
            end

            component.OptionsFrame = optionsFrame
            component.Button = toggleButton
            refreshOptions()
            return component
        end

        function tab:AddTextbox(options)
            options = options or {}
            local component = makeComponent(self, options.Title or options.Name or "Textbox", 68)

            local input = create("TextBox", {
                Name = "Input",
                Position = UDim2.new(0, 8, 0, 31),
                Size = UDim2.new(1, -16, 0, 29),
                BackgroundColor3 = theme.Input,
                BorderSizePixel = 0,
                ClearTextOnFocus = options.ClearOnFocus == true,
                PlaceholderText = options.Placeholder or "Enter text...",
                PlaceholderColor3 = theme.MutedText,
                Text = tostring(options.Default or ""),
                TextColor3 = theme.Text,
                Font = theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, component.Frame)
            corner(input, 4)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }, input)

            input.FocusLost:Connect(function(enterPressed)
                safeCallback(options.Callback, input.Text, enterPressed)
            end)

            function component:Set(newValue)
                input.Text = tostring(newValue or "")
            end

            function component:Get()
                return input.Text
            end

            function component:SetPlaceholder(newPlaceholder)
                input.PlaceholderText = tostring(newPlaceholder or "")
            end

            function component:SetCallback(callback)
                options.Callback = callback
            end

            component.Input = input
            return component
        end

        table.insert(self.Tabs, tab)
        tabButton.Activated:Connect(function()
            tab:Select()
        end)

        if not self.SelectedTab then
            tab:Select()
        end

        return tab
    end

    return window
end

return Quartz

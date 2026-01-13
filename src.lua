local CascadeUI2 = {};
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local CoreGui = game:GetService("CoreGui");
local Players = game:GetService("Players");
local HttpService = game:GetService("HttpService");
local TextService = game:GetService("TextService");
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local function Create(instanceType)
	return function(properties)
		local instance = Instance.new(instanceType);
		for property, value in next, properties do
			if (property ~= "Parent") then
				instance[property] = value;
			end
		end
		if properties.Parent then
			instance.Parent = properties.Parent;
		end
		return instance;
	end;
end
local Colors = {Primary=Color3.fromRGB(30, 30, 35),Secondary=Color3.fromRGB(25, 25, 30),Tertiary=Color3.fromRGB(20, 20, 25),Text=Color3.fromRGB(240, 240, 240),Accent=Color3.fromRGB(68, 148, 255),DarkAccent=Color3.fromRGB(48, 128, 235)};
local Settings = {CornerRadius=UDim.new(0, 4),FontSize=Enum.FontSize.Size14,Font=Enum.Font.Gotham,Padding=10,TweenSpeed=0.2};
local function MakeDraggable(topBarObject, object, registerConnection)
	local Dragging = nil;
	local DragInput = nil;
	local DragStart = nil;
	local StartPosition = nil;
	local function Update(input)
		local Delta = input.Position - DragStart;
		object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y);
	end
	topBarObject.InputBegan:Connect(function(input)
		if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
			Dragging = true;
			DragStart = input.Position;
			StartPosition = object.Position;
			input.Changed:Connect(function()
				if (input.UserInputState == Enum.UserInputState.End) then
					Dragging = false;
				end
			end);
		end
	end);
	topBarObject.InputChanged:Connect(function(input)
		if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
			DragInput = input;
		end
	end);
	local conn = UserInputService.InputChanged:Connect(function(input)
		if ((input == DragInput) and Dragging) then
			Update(input);
		end
	end);
	if registerConnection then
		registerConnection(conn);
	end
end
CascadeUI2.CreateWindow = function(self, config)
	config = config or {};
	local title = config.Title or "CascadeUI2";
	local size = config.Size or UDim2.new(0, 550, 0, 400);
	local position = config.Position or UDim2.new(0.5, -275, 0.5, -200);
	local Connections = {};
	local Destroyed = false;
	local Flags = {};
	local PendingConfig = {};
	local Keybinds = {};
	local CapturingKeybind = nil;
	local OpenDropdowns = {};
	local WindowToggleKey = config.ToggleKey;
	if (WindowToggleKey == nil) then
		WindowToggleKey = Enum.KeyCode.RightShift;
	elseif (WindowToggleKey == false) then
		WindowToggleKey = nil;
	end
	local function RegisterConnection(conn)
		table.insert(Connections, conn);
		return conn;
	end
	local function RegisterFlag(flag, getFunc, setFunc)
		if not flag then
			return;
		end
		Flags[flag] = {Get=getFunc,Set=setFunc};
		if ((PendingConfig[flag] ~= nil) and setFunc) then
			local pendingValue = PendingConfig[flag];
			PendingConfig[flag] = nil;
			pcall(function()
				setFunc(DeserializeValue(pendingValue));
			end);
		end
	end
	local function SerializeValue(value)
		if (value == nil) then
			return {__type="nil"};
		end
		local valueType = typeof(value);
		if (valueType == "Color3") then
			return {__type="Color3",r=value.R,g=value.G,b=value.B};
		end
		if (valueType == "EnumItem") then
			return {__type="EnumItem",enum=value.EnumType.Name,name=value.Name};
		end
		return value;
	end
	local function DeserializeValue(value)
		if (type(value) ~= "table") then
			return value;
		end
		if (value.__type == "nil") then
			return nil;
		end
		if ((value.__type == "Color3") and value.r and value.g and value.b) then
			return Color3.new(value.r, value.g, value.b);
		end
		if ((value.__type == "EnumItem") and value.enum and value.name) then
			if (value.enum == "KeyCode") then
				return Enum.KeyCode[value.name];
			end
			if (value.enum == "UserInputType") then
				return Enum.UserInputType[value.name];
			end
		end
		return value;
	end
	local function KeyToText(key)
		if not key then
			return "None";
		end
		if (typeof(key) == "EnumItem") then
			return key.Name;
		end
		return tostring(key);
	end
	local ScreenGui = Create("ScreenGui")({Name="CascadeUI2",Parent=((RunService:IsStudio() and LocalPlayer.PlayerGui) or CoreGui),ZIndexBehavior=Enum.ZIndexBehavior.Sibling,ResetOnSpawn=false});
	local MainFrame = Create("Frame")({Name="MainFrame",Parent=ScreenGui,BackgroundColor3=Colors.Primary,BorderSizePixel=0,Position=position,Size=size,ClipsDescendants=true});
	local function DestroyWindow()
		if Destroyed then
			return;
		end
		Destroyed = true;
		for _, conn in ipairs(Connections) do
			if conn then
				pcall(function()
					conn:Disconnect();
				end);
			end
		end
		table.clear(Connections);
		pcall(function()
			ScreenGui:Destroy();
		end);
	end
	local NotificationContainer = Create("Frame")({Name="NotificationContainer",Parent=ScreenGui,BackgroundTransparency=1,AnchorPoint=Vector2.new(1, 1),Position=UDim2.new(1, -10, 1, -10),Size=UDim2.new(0, 260, 1, -20),ZIndex=50});
	local NotificationLayout = Create("UIListLayout")({Parent=NotificationContainer,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0, 6)});
	local function NotifyInternal(notificationConfig)
		notificationConfig = notificationConfig or {};
		local nTitle = notificationConfig.Title or "Notification";
		local nContent = notificationConfig.Content or notificationConfig.Text or "";
		local nDuration = notificationConfig.Duration or 3;
		local Notification = Create("Frame")({Name="Notification",Parent=NotificationContainer,BackgroundColor3=Colors.Secondary,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=51});
		Create("UICorner")({Parent=Notification,CornerRadius=Settings.CornerRadius});
		Create("UIPadding")({Parent=Notification,PaddingLeft=UDim.new(0, 10),PaddingRight=UDim.new(0, 10),PaddingTop=UDim.new(0, 8),PaddingBottom=UDim.new(0, 8)});
		local TitleLabel = Create("TextLabel")({Name="Title",Parent=Notification,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 16),Font=Enum.Font.GothamBold,Text=nTitle,TextColor3=Colors.Text,TextSize=14,TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52});
		local ContentLabel = Create("TextLabel")({Name="Content",Parent=Notification,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 16),Size=UDim2.new(1, 0, 0, 0),AutomaticSize=Enum.AutomaticSize.Y,Font=Settings.Font,Text=nContent,TextColor3=Colors.Text,TextSize=13,TextTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52});
		TweenService:Create(Notification, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0}):Play();
		TweenService:Create(TitleLabel, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=0}):Play();
		TweenService:Create(ContentLabel, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=0}):Play();
		task.delay(nDuration, function()
			if (not Notification or not Notification.Parent) then
				return;
			end
			local outTween = TweenService:Create(Notification, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=1});
			local outTitle = TweenService:Create(TitleLabel, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=1});
			local outContent = TweenService:Create(ContentLabel, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=1});
			outTween:Play();
			outTitle:Play();
			outContent:Play();
			outTween.Completed:Connect(function()
				if (Notification and Notification.Parent) then
					Notification:Destroy();
				end
			end);
		end);
	end
	local TooltipFrame = Create("Frame")({Name="Tooltip",Parent=ScreenGui,BackgroundColor3=Colors.Secondary,BorderSizePixel=0,Size=UDim2.new(0, 0, 0, 0),Visible=false,ZIndex=100});
	Create("UICorner")({Parent=TooltipFrame,CornerRadius=Settings.CornerRadius});
	Create("UIPadding")({Parent=TooltipFrame,PaddingLeft=UDim.new(0, 6),PaddingRight=UDim.new(0, 6),PaddingTop=UDim.new(0, 5),PaddingBottom=UDim.new(0, 5)});
	local TooltipText = Create("TextLabel")({Name="Text",Parent=TooltipFrame,BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Font=Settings.Font,Text="",TextColor3=Colors.Text,TextSize=13,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=101});
	RegisterConnection(UserInputService.InputChanged:Connect(function(input)
		if not TooltipFrame.Visible then
			return;
		end
		if (input.UserInputType == Enum.UserInputType.MouseMovement) then
			TooltipFrame.Position = UDim2.new(0, input.Position.X + 12, 0, input.Position.Y + 12);
		end
	end));
	local function AttachTooltip(target, text)
		if (not text or (text == "")) then
			return;
		end
		target.MouseEnter:Connect(function()
			TooltipText.Text = text;
			local bounds = TextService:GetTextSize(text, 13, Settings.Font, Vector2.new(280, 1000));
			TooltipFrame.Size = UDim2.new(0, bounds.X + 12, 0, bounds.Y + 10);
			local mousePos = UserInputService:GetMouseLocation();
			TooltipFrame.Position = UDim2.new(0, mousePos.X + 12, 0, mousePos.Y + 12);
			TooltipFrame.Visible = true;
		end);
		target.MouseLeave:Connect(function()
			TooltipFrame.Visible = false;
		end);
	end
	RegisterConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return;
		end
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			local mousePos = input.Position;
			local clickedInside = false;
			for _, dropdown in pairs(OpenDropdowns) do
				local container = dropdown and dropdown.Container;
				if (container and container.Parent) then
					local pos = container.AbsolutePosition;
					local size = container.AbsoluteSize;
					if ((mousePos.X >= pos.X) and (mousePos.X <= (pos.X + size.X)) and (mousePos.Y >= pos.Y) and (mousePos.Y <= (pos.Y + size.Y))) then
						clickedInside = true;
						break;
					end
				end
			end
			if not clickedInside then
				for _, dropdown in pairs(OpenDropdowns) do
					if (dropdown and dropdown.Close) then
						pcall(dropdown.Close);
					end
				end
			end
		end
		if CapturingKeybind then
			if (input.UserInputType ~= Enum.UserInputType.Keyboard) then
				return;
			end
			local key = input.KeyCode;
			if (key == Enum.KeyCode.Unknown) then
				return;
			end
			if (key == Enum.KeyCode.Escape) then
				if CapturingKeybind.Cancel then
					CapturingKeybind.Cancel();
				end
				CapturingKeybind = nil;
				return;
			end
			if ((key == Enum.KeyCode.Backspace) or (key == Enum.KeyCode.Delete)) then
				if CapturingKeybind.Apply then
					CapturingKeybind.Apply(nil);
				end
				CapturingKeybind = nil;
				return;
			end
			if CapturingKeybind.Apply then
				CapturingKeybind.Apply(key);
			end
			CapturingKeybind = nil;
			return;
		end
		if (WindowToggleKey and (input.UserInputType == Enum.UserInputType.Keyboard) and (input.KeyCode == WindowToggleKey)) then
			MainFrame.Visible = not MainFrame.Visible;
			return;
		end
		if (input.UserInputType == Enum.UserInputType.Keyboard) then
			for _, bind in ipairs(Keybinds) do
				local okKey, expectedKey = pcall(function()
					return (bind.GetKey and bind.GetKey()) or bind.Key;
				end);
				if (okKey and expectedKey and (expectedKey == input.KeyCode) and bind.Callback) then
					pcall(function()
						bind.Callback(input.KeyCode);
					end);
				end
			end
		end
	end));
	Create("UICorner")({Parent=MainFrame,CornerRadius=Settings.CornerRadius});
	local Shadow = Create("ImageLabel")({Name="Shadow",Parent=MainFrame,BackgroundTransparency=1,Position=UDim2.new(0, -15, 0, -15),Size=UDim2.new(1, 30, 1, 30),ZIndex=0,Image="rbxassetid://5554236805",ImageColor3=Color3.fromRGB(0, 0, 0),ImageTransparency=0.6,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(23, 23, 277, 277)});
	local TitleBar = Create("Frame")({Name="TitleBar",Parent=MainFrame,BackgroundColor3=Colors.Secondary,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 30)});
	Create("UICorner")({Parent=TitleBar,CornerRadius=UDim.new(0, 4)});
	local TitleText = Create("TextLabel")({Name="Title",Parent=TitleBar,BackgroundTransparency=1,Position=UDim2.new(0, 10, 0, 0),Size=UDim2.new(1, -20, 1, 0),Font=Settings.Font,Text=title,TextColor3=Colors.Text,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left});
	local CloseButton = Create("TextButton")({Name="CloseButton",Parent=TitleBar,BackgroundTransparency=1,Position=UDim2.new(1, -25, 0, 5),Size=UDim2.new(0, 20, 0, 20),Font=Enum.Font.GothamBold,Text="×",TextColor3=Colors.Text,TextSize=20});
	CloseButton.MouseButton1Click:Connect(function()
		DestroyWindow();
	end);
	MakeDraggable(TitleBar, MainFrame, RegisterConnection);
	local ContentContainer = Create("Frame")({Name="ContentContainer",Parent=MainFrame,BackgroundTransparency=1,Position=UDim2.new(0, 130, 0, 30),Size=UDim2.new(1, -130, 1, -30),ClipsDescendants=true});
	local Sidebar = Create("Frame")({Name="Sidebar",Parent=MainFrame,BackgroundColor3=Colors.Secondary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 30),Size=UDim2.new(0, 130, 1, -30)});
	local SidebarScrollFrame = Create("ScrollingFrame")({Name="SidebarScrollFrame",Parent=Sidebar,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 10),Size=UDim2.new(1, 0, 1, -20),CanvasSize=UDim2.new(0, 0, 0, 0),ScrollBarThickness=2,ScrollBarImageColor3=Colors.Accent,VerticalScrollBarPosition=Enum.VerticalScrollBarPosition.Right});
	local SidebarListLayout = Create("UIListLayout")({Parent=SidebarScrollFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0, 5)});
	Create("UIPadding")({Parent=SidebarScrollFrame,PaddingLeft=UDim.new(0, 5),PaddingRight=UDim.new(0, 5),PaddingTop=UDim.new(0, 5),PaddingBottom=UDim.new(0, 5)});
	local function UpdateSidebarCanvasSize()
		SidebarScrollFrame.CanvasSize = UDim2.new(0, 0, 0, SidebarListLayout.AbsoluteContentSize.Y + 10);
	end
	SidebarListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSidebarCanvasSize);
	local TabSystem = {};
	local Pages = {};
	local CurrentPage = nil;
	TabSystem.CreateTab = function(self, tabName)
		tabName = tabName or "Tab";
		local TabButton = Create("TextButton")({Name=(tabName .. "Button"),Parent=SidebarScrollFrame,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 30),Font=Settings.Font,Text=tabName,TextColor3=Colors.Text,TextSize=14,ClipsDescendants=true});
		Create("UICorner")({Parent=TabButton,CornerRadius=Settings.CornerRadius});
		local Page = Create("ScrollingFrame")({Name=(tabName .. "Page"),Parent=ContentContainer,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1, 0, 1, 0),CanvasSize=UDim2.new(0, 0, 0, 0),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Accent,Visible=false});
		Create("UIPadding")({Parent=Page,PaddingLeft=UDim.new(0, 10),PaddingRight=UDim.new(0, 10),PaddingTop=UDim.new(0, 10),PaddingBottom=UDim.new(0, 10)});
		local PageListLayout = Create("UIListLayout")({Parent=Page,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0, 8)});
		local function UpdatePageCanvasSize()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20);
		end
		PageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdatePageCanvasSize);
		Pages[tabName] = Page;
		TabButton.MouseButton1Click:Connect(function()
			for _, page in pairs(Pages) do
				page.Visible = false;
			end
			Page.Visible = true;
			CurrentPage = Page;
			for _, child in pairs(SidebarScrollFrame:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Colors.Tertiary;
					child.TextColor3 = Colors.Text;
				end
			end
			TabButton.BackgroundColor3 = Colors.Accent;
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255);
		end);
		if (CurrentPage == nil) then
			TabButton.BackgroundColor3 = Colors.Accent;
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255);
			Page.Visible = true;
			CurrentPage = Page;
		end
		local SectionSystem = {};
		SectionSystem.CreateSection = function(self, sectionName)
			sectionName = sectionName or "Section";
			local SectionContainer = Create("Frame")({Name=(sectionName .. "Section"),Parent=Page,BackgroundColor3=Colors.Secondary,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 36),AutomaticSize=Enum.AutomaticSize.Y});
			Create("UICorner")({Parent=SectionContainer,CornerRadius=Settings.CornerRadius});
			local SectionTitle = Create("TextLabel")({Name="Title",Parent=SectionContainer,BackgroundTransparency=1,Position=UDim2.new(0, 10, 0, 0),Size=UDim2.new(1, -20, 0, 26),Font=Settings.Font,Text=sectionName,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
			local ElementsContainer = Create("Frame")({Name="ElementsContainer",Parent=SectionContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 26),Size=UDim2.new(1, 0, 0, 0),AutomaticSize=Enum.AutomaticSize.Y});
			Create("UIPadding")({Parent=ElementsContainer,PaddingLeft=UDim.new(0, 10),PaddingRight=UDim.new(0, 10),PaddingBottom=UDim.new(0, 10)});
			local ElementsListLayout = Create("UIListLayout")({Parent=ElementsContainer,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0, 8)});
			local ElementSystem = {};
			ElementSystem.CreateToggle = function(self, toggleConfig)
				toggleConfig = toggleConfig or {};
				local name = toggleConfig.Name or "Toggle";
				local default = toggleConfig.Default or false;
				local callback = toggleConfig.Callback or function()
				end;
				local flag = toggleConfig.Flag;
				local tooltip = toggleConfig.Tooltip;
				local ToggleContainer = Create("Frame")({Name=(name .. "Toggle"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 30)});
				local ToggleLabel = Create("TextLabel")({Name="Label",Parent=ToggleContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, -50, 1, 0),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local ToggleFrame = Create("Frame")({Name="ToggleFrame",Parent=ToggleContainer,BackgroundColor3=((default and Colors.Accent) or Colors.Tertiary),BorderSizePixel=0,Position=UDim2.new(1, -40, 0.5, -10),Size=UDim2.new(0, 40, 0, 20)});
				Create("UICorner")({Parent=ToggleFrame,CornerRadius=UDim.new(0, 10)});
				local ToggleIndicator = Create("Frame")({Name="Indicator",Parent=ToggleFrame,BackgroundColor3=Color3.fromRGB(255, 255, 255),BorderSizePixel=0,Position=((default and UDim2.new(1, -18, 0.5, -8)) or UDim2.new(0, 2, 0.5, -8)),Size=UDim2.new(0, 16, 0, 16)});
				Create("UICorner")({Parent=ToggleIndicator,CornerRadius=UDim.new(0, 8)});
				local Toggled = default;
				local ToggleButton = Create("TextButton")({Name="ToggleButton",Parent=ToggleContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 1, 0),Text="",TextTransparency=1});
				ToggleButton.MouseButton1Click:Connect(function()
					Toggled = not Toggled;
					local toggleTween = TweenService:Create(ToggleFrame, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3=((Toggled and Colors.Accent) or Colors.Tertiary)});
					local indicatorTween = TweenService:Create(ToggleIndicator, TweenInfo.new(Settings.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=((Toggled and UDim2.new(1, -18, 0.5, -8)) or UDim2.new(0, 2, 0.5, -8))});
					toggleTween:Play();
					indicatorTween:Play();
					callback(Toggled);
				end);
				local ToggleElement = {};
				ToggleElement.Set = function(self, value)
					Toggled = value;
					ToggleFrame.BackgroundColor3 = (Toggled and Colors.Accent) or Colors.Tertiary;
					ToggleIndicator.Position = (Toggled and UDim2.new(1, -18, 0.5, -8)) or UDim2.new(0, 2, 0.5, -8);
					callback(Toggled);
				end;
				ToggleElement.Get = function(self)
					return Toggled;
				end;
				if tooltip then
					AttachTooltip(ToggleLabel, tooltip);
				end
				RegisterFlag(flag, function()
					return ToggleElement:Get();
				end, function(value)
					ToggleElement:Set(value);
				end);
				return ToggleElement;
			end;
			ElementSystem.CreateButton = function(self, buttonConfig)
				buttonConfig = buttonConfig or {};
				local name = buttonConfig.Name or "Button";
				local callback = buttonConfig.Callback or function()
				end;
				local tooltip = buttonConfig.Tooltip;
				local ButtonContainer = Create("Frame")({Name=(name .. "Button"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 30)});
				local Button = Create("TextButton")({Name="Button",Parent=ButtonContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Size=UDim2.new(1, 0, 1, 0),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14});
				Create("UICorner")({Parent=Button,CornerRadius=Settings.CornerRadius});
				if tooltip then
					AttachTooltip(Button, tooltip);
				end
				Button.MouseButton1Click:Connect(function()
					local originalColor = Button.BackgroundColor3;
					local downTween = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3=Colors.Accent});
					local upTween = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3=originalColor});
					downTween:Play();
					downTween.Completed:Connect(function()
						upTween:Play();
					end);
					callback();
				end);
				local ButtonElement = {};
				ButtonElement.Fire = function(self)
					callback();
				end;
				return ButtonElement;
			end;
			ElementSystem.CreateLabel = function(self, labelConfig)
				labelConfig = labelConfig or {};
				local name = labelConfig.Name or "Label";
				local default = labelConfig.Text or labelConfig.Default or "";
				local flag = labelConfig.Flag;
				local tooltip = labelConfig.Tooltip;
				local LabelContainer = Create("Frame")({Name=(name .. "Label"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 18)});
				local Label = Create("TextLabel")({Name="Label",Parent=LabelContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Font=Settings.Font,Text=default,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local CurrentText = default;
				local LabelElement = {};
				LabelElement.Set = function(self, text)
					CurrentText = tostring(text or "");
					Label.Text = CurrentText;
				end;
				LabelElement.Get = function(self)
					return CurrentText;
				end;
				if tooltip then
					AttachTooltip(Label, tooltip);
				end
				RegisterFlag(flag, function()
					return LabelElement:Get();
				end, function(value)
					LabelElement:Set(value);
				end);
				return LabelElement;
			end;
			ElementSystem.CreateTextbox = function(self, textboxConfig)
				textboxConfig = textboxConfig or {};
				local name = textboxConfig.Name or "Textbox";
				local default = textboxConfig.Default or "";
				local placeholder = textboxConfig.Placeholder or "";
				local callback = textboxConfig.Callback or function()
				end;
				local flag = textboxConfig.Flag;
				local tooltip = textboxConfig.Tooltip;
				local TextboxContainer = Create("Frame")({Name=(name .. "Textbox"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 55)});
				local TextboxLabel = Create("TextLabel")({Name="Label",Parent=TextboxContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 0, 20),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local Textbox = Create("TextBox")({Name="Input",Parent=TextboxContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 25),Size=UDim2.new(1, 0, 0, 30),Font=Settings.Font,Text=tostring(default or ""),PlaceholderText=tostring(placeholder or ""),TextColor3=Colors.Text,PlaceholderColor3=Color3.fromRGB(170, 170, 170),TextSize=14,ClearTextOnFocus=false});
				Create("UICorner")({Parent=Textbox,CornerRadius=Settings.CornerRadius});
				local CurrentText = tostring(default or "");
				Textbox.FocusLost:Connect(function()
					CurrentText = Textbox.Text;
					callback(CurrentText);
				end);
				local TextboxElement = {};
				TextboxElement.Set = function(self, text)
					CurrentText = tostring(text or "");
					Textbox.Text = CurrentText;
					callback(CurrentText);
				end;
				TextboxElement.Get = function(self)
					return CurrentText;
				end;
				if tooltip then
					AttachTooltip(Textbox, tooltip);
				end
				RegisterFlag(flag, function()
					return TextboxElement:Get();
				end, function(value)
					TextboxElement:Set(value);
				end);
				return TextboxElement;
			end;
			ElementSystem.CreateKeybind = function(self, keybindConfig)
				keybindConfig = keybindConfig or {};
				local name = keybindConfig.Name or "Keybind";
				local default = keybindConfig.Default;
				local callback = keybindConfig.Callback or function()
				end;
				local changedCallback = keybindConfig.ChangedCallback;
				local flag = keybindConfig.Flag;
				local tooltip = keybindConfig.Tooltip;
				local KeybindContainer = Create("Frame")({Name=(name .. "Keybind"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 30)});
				local KeybindLabel = Create("TextLabel")({Name="Label",Parent=KeybindContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, -90, 1, 0),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local KeybindButton = Create("TextButton")({Name="Key",Parent=KeybindContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(1, -90, 0.5, -10),Size=UDim2.new(0, 90, 0, 20),Font=Settings.Font,Text=KeyToText(default),TextColor3=Colors.Text,TextSize=14});
				Create("UICorner")({Parent=KeybindButton,CornerRadius=Settings.CornerRadius});
				if tooltip then
					AttachTooltip(KeybindButton, tooltip);
				end
				local CurrentKey = default;
				local function ApplyKey(key)
					CurrentKey = key;
					KeybindButton.Text = KeyToText(CurrentKey);
					if changedCallback then
						pcall(function()
							changedCallback(CurrentKey);
						end);
					end
				end
				KeybindButton.MouseButton1Click:Connect(function()
					if (CapturingKeybind and CapturingKeybind.Cancel) then
						pcall(function()
							CapturingKeybind.Cancel();
						end);
					end
					KeybindButton.Text = "...";
					CapturingKeybind = {Apply=function(key)
						ApplyKey(key);
					end,Cancel=function()
						KeybindButton.Text = KeyToText(CurrentKey);
					end};
				end);
				table.insert(Keybinds, {GetKey=function()
					return CurrentKey;
				end,Callback=callback});
				local KeybindElement = {};
				KeybindElement.Set = function(self, key)
					ApplyKey(key);
				end;
				KeybindElement.Get = function(self)
					return CurrentKey;
				end;
				RegisterFlag(flag, function()
					return KeybindElement:Get();
				end, function(value)
					KeybindElement:Set(value);
				end);
				return KeybindElement;
			end;
			ElementSystem.CreateProgressBar = function(self, progressConfig)
				progressConfig = progressConfig or {};
				local name = progressConfig.Name or "Progress";
				local min = progressConfig.Min or 0;
				local max = progressConfig.Max or 100;
				local default = progressConfig.Default;
				if (default == nil) then
					default = min;
				end
				local callback = progressConfig.Callback or function()
				end;
				local flag = progressConfig.Flag;
				local tooltip = progressConfig.Tooltip;
				default = math.clamp(default, min, max);
				local ProgressContainer = Create("Frame")({Name=(name .. "Progress"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 45)});
				local ProgressLabel = Create("TextLabel")({Name="Label",Parent=ProgressContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, -60, 0, 20),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local ValueLabel = Create("TextLabel")({Name="Value",Parent=ProgressContainer,BackgroundTransparency=1,Position=UDim2.new(1, -60, 0, 0),Size=UDim2.new(0, 60, 0, 20),Font=Settings.Font,Text=tostring(default),TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Right});
				local BarBackground = Create("Frame")({Name="Background",Parent=ProgressContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 25),Size=UDim2.new(1, 0, 0, 10)});
				Create("UICorner")({Parent=BarBackground,CornerRadius=UDim.new(0, 5)});
				local Fill = Create("Frame")({Name="Fill",Parent=BarBackground,BackgroundColor3=Colors.Accent,BorderSizePixel=0,Size=UDim2.new((default - min) / (max - min), 0, 1, 0)});
				Create("UICorner")({Parent=Fill,CornerRadius=UDim.new(0, 5)});
				if tooltip then
					AttachTooltip(ProgressLabel, tooltip);
				end
				local Value = default;
				local ProgressElement = {};
				ProgressElement.Set = function(self, value)
					value = math.clamp(value, min, max);
					Value = value;
					Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0);
					ValueLabel.Text = tostring(value);
					callback(value);
				end;
				ProgressElement.Get = function(self)
					return Value;
				end;
				RegisterFlag(flag, function()
					return ProgressElement:Get();
				end, function(value)
					ProgressElement:Set(value);
				end);
				return ProgressElement;
			end;
			ElementSystem.CreateDivider = function(self, dividerConfig)
				dividerConfig = dividerConfig or {};
				local name = dividerConfig.Name or "Divider";
				local text = dividerConfig.Text;
				local flag = dividerConfig.Flag;
				local tooltip = dividerConfig.Tooltip;
				local DividerContainer = Create("Frame")({Name=(name .. "Divider"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, (text and 20) or 10)});
				local DividerTextLabel = nil;
				local CurrentText = text;
				if text then
					DividerTextLabel = Create("TextLabel")({Name="Text",Parent=DividerContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 0, 18),Font=Settings.Font,Text=tostring(text),TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				end
				local Line = Create("Frame")({Name="Line",Parent=DividerContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, (text and 19) or 5),Size=UDim2.new(1, 0, 0, 1)});
				if tooltip then
					AttachTooltip(DividerTextLabel or Line, tooltip);
				end
				local DividerElement = {};
				DividerElement.Set = function(self, newText)
					CurrentText = newText;
					if DividerTextLabel then
						DividerTextLabel.Text = tostring(newText or "");
					end
				end;
				DividerElement.Get = function(self)
					return CurrentText;
				end;
				RegisterFlag(flag, function()
					return DividerElement:Get();
				end, function(value)
					DividerElement:Set(value);
				end);
				return DividerElement;
			end;
			ElementSystem.CreateSlider = function(self, sliderConfig)
				sliderConfig = sliderConfig or {};
				local name = sliderConfig.Name or "Slider";
				local min = sliderConfig.Min or 0;
				local max = sliderConfig.Max or 100;
				local default = sliderConfig.Default or min;
				local callback = sliderConfig.Callback or function()
				end;
				local flag = sliderConfig.Flag;
				local tooltip = sliderConfig.Tooltip;
				default = math.clamp(default, min, max);
				local SliderContainer = Create("Frame")({Name=(name .. "Slider"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 45)});
				local SliderLabel = Create("TextLabel")({Name="Label",Parent=SliderContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 0, 20),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local ValueLabel = Create("TextLabel")({Name="Value",Parent=SliderContainer,BackgroundTransparency=1,Position=UDim2.new(1, -40, 0, 0),Size=UDim2.new(0, 40, 0, 20),Font=Settings.Font,Text=tostring(default),TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Right});
				local SliderBackground = Create("Frame")({Name="Background",Parent=SliderContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 25),Size=UDim2.new(1, 0, 0, 10)});
				Create("UICorner")({Parent=SliderBackground,CornerRadius=UDim.new(0, 5)});
				local SliderFill = Create("Frame")({Name="Fill",Parent=SliderBackground,BackgroundColor3=Colors.Accent,BorderSizePixel=0,Size=UDim2.new((default - min) / (max - min), 0, 1, 0)});
				Create("UICorner")({Parent=SliderFill,CornerRadius=UDim.new(0, 5)});
				local Value = default;
				local function UpdateSlider(input)
					local sizeX = math.clamp((input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X, 0, 1);
					SliderFill.Size = UDim2.new(sizeX, 0, 1, 0);
					local newValue = math.floor(min + ((max - min) * sizeX));
					Value = newValue;
					ValueLabel.Text = tostring(newValue);
					callback(newValue);
				end
				local SliderButton = Create("TextButton")({Name="SliderButton",Parent=SliderBackground,BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Text="",TextTransparency=1});
				local dragging = false;
				SliderButton.MouseButton1Down:Connect(function(input)
					dragging = true;
					UpdateSlider({Position={X=input}});
				end);
				RegisterConnection(UserInputService.InputEnded:Connect(function(input)
					if (input.UserInputType == Enum.UserInputType.MouseButton1) then
						dragging = false;
					end
				end));
				RegisterConnection(UserInputService.InputChanged:Connect(function(input)
					if (dragging and (input.UserInputType == Enum.UserInputType.MouseMovement)) then
						UpdateSlider(input);
					end
				end));
				local SliderElement = {};
				SliderElement.Set = function(self, value)
					value = math.clamp(value, min, max);
					Value = value;
					SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0);
					ValueLabel.Text = tostring(value);
					callback(value);
				end;
				SliderElement.Get = function(self)
					return Value;
				end;
				if tooltip then
					AttachTooltip(SliderLabel, tooltip);
				end
				RegisterFlag(flag, function()
					return SliderElement:Get();
				end, function(value)
					SliderElement:Set(value);
				end);
				return SliderElement;
			end;
			ElementSystem.CreateDropdown = function(self, dropdownConfig)
				dropdownConfig = dropdownConfig or {};
				local name = dropdownConfig.Name or "Dropdown";
				local options = dropdownConfig.Options or {};
				local default = dropdownConfig.Default or options[1] or "";
				local callback = dropdownConfig.Callback or function()
				end;
				local flag = dropdownConfig.Flag;
				local tooltip = dropdownConfig.Tooltip;
				local DropdownContainer = Create("Frame")({Name=(name .. "Dropdown"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 30),ClipsDescendants=true});
				local DropdownLabel = Create("TextLabel")({Name="Label",Parent=DropdownContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 0, 20),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local DropdownButton = Create("TextButton")({Name="Button",Parent=DropdownContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 25),Size=UDim2.new(1, 0, 0, 30),Font=Settings.Font,Text=default,TextColor3=Colors.Text,TextSize=14});
				Create("UICorner")({Parent=DropdownButton,CornerRadius=Settings.CornerRadius});
				local DropdownArrow = Create("TextLabel")({Name="Arrow",Parent=DropdownButton,BackgroundTransparency=1,Position=UDim2.new(1, -20, 0, 0),Size=UDim2.new(0, 20, 1, 0),Font=Enum.Font.SourceSansBold,Text="▼",TextColor3=Colors.Text,TextSize=14});
				if tooltip then
					AttachTooltip(DropdownButton, tooltip);
				end
				local DropdownList = Create("Frame")({Name="List",Parent=DropdownContainer,BackgroundColor3=Colors.Tertiary,BorderSizePixel=0,Position=UDim2.new(0, 0, 0, 60),Size=UDim2.new(1, 0, 0, 0),Visible=false});
				Create("UICorner")({Parent=DropdownList,CornerRadius=Settings.CornerRadius});
				local DropdownListLayout = Create("UIListLayout")({Parent=DropdownList,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0, 5)});
				Create("UIPadding")({Parent=DropdownList,PaddingLeft=UDim.new(0, 5),PaddingRight=UDim.new(0, 5),PaddingTop=UDim.new(0, 5),PaddingBottom=UDim.new(0, 5)});
				local Expanded = false;
				local Selected = default;
				local function UpdateDropdownListSize()
					DropdownList.Size = UDim2.new(1, 0, 0, DropdownListLayout.AbsoluteContentSize.Y + 10);
					DropdownContainer.Size = UDim2.new(1, 0, 0, (Expanded and (60 + DropdownList.Size.Y.Offset)) or 60);
				end
				local function CloseDropdown()
					if not Expanded then
						return;
					end
					Expanded = false;
					DropdownList.Visible = false;
					DropdownArrow.Text = "▼";
					OpenDropdowns[DropdownButton] = nil;
					UpdateDropdownListSize();
				end
				for _, option in ipairs(options) do
					local OptionButton = Create("TextButton")({Name=(option .. "Option"),Parent=DropdownList,BackgroundColor3=Colors.Primary,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 25),Font=Settings.Font,Text=option,TextColor3=Colors.Text,TextSize=14});
					Create("UICorner")({Parent=OptionButton,CornerRadius=Settings.CornerRadius});
					OptionButton.MouseButton1Click:Connect(function()
						Selected = option;
						DropdownButton.Text = option;
						CloseDropdown();
						callback(option);
					end);
				end
				DropdownListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateDropdownListSize);
				UpdateDropdownListSize();
				DropdownButton.MouseButton1Click:Connect(function()
					if Expanded then
						CloseDropdown();
						return;
					end
					for _, dropdown in pairs(OpenDropdowns) do
						if (dropdown and dropdown.Close) then
							pcall(dropdown.Close);
						end
					end
					Expanded = true;
					DropdownList.Visible = true;
					DropdownArrow.Text = "▲";
					OpenDropdowns[DropdownButton] = {Container=DropdownContainer,Close=CloseDropdown};
					UpdateDropdownListSize();
				end);
				local DropdownElement = {};
				DropdownElement.Set = function(self, option)
					if table.find(options, option) then
						Selected = option;
						DropdownButton.Text = option;
						callback(option);
					end
				end;
				DropdownElement.Get = function(self)
					return Selected;
				end;
				DropdownElement.Refresh = function(self, newOptions, keepSelection)
					options = newOptions or {};
					for _, child in pairs(DropdownList:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy();
						end
					end
					for _, option in ipairs(options) do
						local OptionButton = Create("TextButton")({Name=(option .. "Option"),Parent=DropdownList,BackgroundColor3=Colors.Primary,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 25),Font=Settings.Font,Text=option,TextColor3=Colors.Text,TextSize=14});
						Create("UICorner")({Parent=OptionButton,CornerRadius=Settings.CornerRadius});
						OptionButton.MouseButton1Click:Connect(function()
							Selected = option;
							DropdownButton.Text = option;
							CloseDropdown();
							callback(option);
						end);
					end
					if (not keepSelection or not table.find(options, Selected)) then
						Selected = options[1] or "";
						DropdownButton.Text = Selected;
					end
					UpdateDropdownListSize();
				end;
				RegisterFlag(flag, function()
					return DropdownElement:Get();
				end, function(value)
					DropdownElement:Set(value);
				end);
				return DropdownElement;
			end;
			ElementSystem.CreateColorPicker = function(self, colorPickerConfig)
				colorPickerConfig = colorPickerConfig or {};
				local name = colorPickerConfig.Name or "ColorPicker";
				local default = colorPickerConfig.Default or Color3.fromRGB(255, 255, 255);
				local callback = colorPickerConfig.Callback or function()
				end;
				local flag = colorPickerConfig.Flag;
				local tooltip = colorPickerConfig.Tooltip;
				local ColorPickerContainer = Create("Frame")({Name=(name .. "ColorPicker"),Parent=ElementsContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 30)});
				local ColorPickerLabel = Create("TextLabel")({Name="Label",Parent=ColorPickerContainer,BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, -40, 1, 0),Font=Settings.Font,Text=name,TextColor3=Colors.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
				local ColorDisplay = Create("Frame")({Name="ColorDisplay",Parent=ColorPickerContainer,BackgroundColor3=default,BorderSizePixel=0,Position=UDim2.new(1, -30, 0.5, -10),Size=UDim2.new(0, 30, 0, 20)});
				Create("UICorner")({Parent=ColorDisplay,CornerRadius=Settings.CornerRadius});
				local ColorPickerButton = Create("TextButton")({Name="ColorPickerButton",Parent=ColorPickerContainer,BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Text="",TextTransparency=1});
				if tooltip then
					AttachTooltip(ColorPickerLabel, tooltip);
				end
				local CurrentColor = default;
				ColorPickerButton.MouseButton1Click:Connect(function()
					local colors = {Color3.fromRGB(255, 0, 0),Color3.fromRGB(0, 255, 0),Color3.fromRGB(0, 0, 255),Color3.fromRGB(255, 255, 0),Color3.fromRGB(255, 0, 255),Color3.fromRGB(0, 255, 255),Color3.fromRGB(255, 255, 255)};
					local currentIndex = 1;
					for i, color in ipairs(colors) do
						if (CurrentColor == color) then
							currentIndex = i;
							break;
						end
					end
					local nextIndex = (currentIndex % #colors) + 1;
					CurrentColor = colors[nextIndex];
					ColorDisplay.BackgroundColor3 = CurrentColor;
					callback(CurrentColor);
				end);
				local ColorPickerElement = {};
				ColorPickerElement.Set = function(self, color)
					CurrentColor = color;
					ColorDisplay.BackgroundColor3 = color;
					callback(color);
				end;
				ColorPickerElement.Get = function(self)
					return CurrentColor;
				end;
				RegisterFlag(flag, function()
					return ColorPickerElement:Get();
				end, function(value)
					ColorPickerElement:Set(value);
				end);
				return ColorPickerElement;
			end;
			return ElementSystem;
		end;
		return SectionSystem;
	end;
	TabSystem.Notify = function(self, notificationConfig)
		NotifyInternal(notificationConfig);
	end;
	TabSystem.Destroy = function(self)
		DestroyWindow();
	end;
	TabSystem.GetFlag = function(self, flag)
		if not flag then
			return nil;
		end
		local entry = Flags[flag];
		if (entry and entry.Get) then
			local ok, value = pcall(entry.Get);
			if ok then
				return value;
			end
		end
		return nil;
	end;
	TabSystem.SetFlag = function(self, flag, value)
		if not flag then
			return;
		end
		local entry = Flags[flag];
		if (entry and entry.Set) then
			pcall(function()
				entry.Set(value);
			end);
			return;
		end
		PendingConfig[flag] = SerializeValue(value);
	end;
	TabSystem.GetConfig = function(self)
		local configData = {};
		for flag, entry in pairs(Flags) do
			if (entry and entry.Get) then
				local ok, value = pcall(entry.Get);
				if ok then
					configData[flag] = SerializeValue(value);
				end
			end
		end
		return configData;
	end;
	TabSystem.SaveConfig = function(self, target)
		local configData = self:GetConfig();
		local ok, json = pcall(function()
			return HttpService:JSONEncode(configData);
		end);
		if not ok then
			return nil;
		end
		if ((type(target) == "string") and writefile) then
			pcall(function()
				writefile(target, json);
			end);
		end
		return json;
	end;
	TabSystem.LoadConfig = function(self, source)
		local decoded = nil;
		if (type(source) == "string") then
			local raw = source;
			if (readfile and isfile) then
				local okFile, exists = pcall(function()
					return isfile(source);
				end);
				if (okFile and exists) then
					local okRead, data = pcall(function()
						return readfile(source);
					end);
					if okRead then
						raw = data;
					end
				end
			end
			local ok, data = pcall(function()
				return HttpService:JSONDecode(raw);
			end);
			if not ok then
				return false;
			end
			decoded = data;
		elseif (type(source) == "table") then
			decoded = source;
		else
			return false;
		end
		for flag, value in pairs(decoded) do
			local entry = Flags[flag];
			if (entry and entry.Set) then
				pcall(function()
					entry.Set(DeserializeValue(value));
				end);
			else
				PendingConfig[flag] = value;
			end
		end
		return true;
	end;
	return TabSystem;
end;
return CascadeUI2;

--[[
	564 HUB | biblioteca
	Design: Neverlose preto e branco (design_lumim.txt)

	Uso:
		local Library = loadstring(game:HttpGet("URL_DA_LIB"))()
		local Window = Library:AddWindow("564", "Hub", "meu_projeto")

		local Tab = Window:AddTab("home", "Main")
		local Sec = Tab:AddSection("Geral")
		Sec:AddToggle("Ativo", false, function(v) end)
		Sec:AddSlider("Velocidade", 0, 100, 50, 1, "%.0f", function(v) end, "vel")
		Sec:AddDropdown("Modo", {"A", "B"}, "A", function(v) end, "modo")
		Sec:AddButton("Executar", function() Window:Notify("OK", "Feito", 3) end)

	Atalho: RightShift mostra/esconde. Minimizar vira o ícone 564.
	Valores marcados com "flag" são salvos em arquivo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local SPRITE = "rbxassetid://3926305904"
local ICONS = {
	ads = Vector2.new(205, 565),
	list = Vector2.new(485, 205),
	folder = Vector2.new(805, 45),
	earth = Vector2.new(604, 324),
	locked = Vector2.new(524, 644),
	home = Vector2.new(964, 205),
}
local MINIMIZE_ICON = "rbxassetid://10002398990"
local HUB_ICON = "rbxassetid://0" -- TROCAR pelo ID do ícone do hub 564

local THEME = {
	Background = Color3.fromRGB(0, 0, 0),
	Section = Color3.fromRGB(0, 0, 0),
	Button = Color3.fromRGB(0, 0, 0),
	Stroke = Color3.fromRGB(255, 255, 255),
	Main = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Hover = Color3.fromRGB(90, 90, 90),
	Row = Color3.fromRGB(28, 28, 28),
}

local FONT = Enum.Font.SourceSansSemibold
local FONTB = Enum.Font.SourceSansBold
local FONTR = Enum.Font.SourceSans
local WINDOW_SIZE = UDim2.fromOffset(620, 400)
local MINI_SIZE = UDim2.fromOffset(56, 56)
local MINI_POSITION = UDim2.new(0, 48, 1, -48)

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

-- corner() e stroke() podem ser usados dentro da lista de filhos (sem parent)
local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 3), Parent = parent })
end

local function stroke(parent, color)
	return create("UIStroke", {
		Color = color or THEME.Stroke,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function hover(obj, st)
	obj.MouseEnter:Connect(function()
		TweenService:Create(st, TweenInfo.new(0.2), { Color = THEME.Hover }):Play()
	end)
	obj.MouseLeave:Connect(function()
		TweenService:Create(st, TweenInfo.new(0.2), { Color = THEME.Stroke }):Play()
	end)
end

local function setIcon(img, name)
	local offset = ICONS[name]
	if not offset then
		return
	end
	img.Image = SPRITE
	img.ImageRectOffset = offset
	img.ImageRectSize = Vector2.new(35, 35)
end

local function makeDraggable(handle, target)
	local dragging, startInput, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

local function nextOrder(sec)
	sec.n = sec.n + 1
	return sec.n
end

local Library = {}
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

----------------------------------------------------------------
-- Janela
----------------------------------------------------------------
function Library:AddWindow(title, subtitle, configId)
	local self = setmetatable({}, Window)
	self.Tabs = {}
	self.ActiveTab = nil
	self.Expanded = WINDOW_SIZE
	self.configFile = "564_" .. tostring(configId or "hub") .. ".json"
	self.saved, self.dirty = {}, false

	pcall(function()
		if isfile and readfile and isfile(self.configFile) then
			local d = HttpService:JSONDecode(readfile(self.configFile))
			if type(d) == "table" then
				self.saved = d
			end
		end
	end)

	local parentGui
	pcall(function()
		parentGui = gethui and gethui()
	end)
	if not parentGui then
		local ok, cg = pcall(function() return game:GetService("CoreGui") end)
		parentGui = ok and cg or player:WaitForChild("PlayerGui")
	end
	local old = parentGui:FindFirstChild("Hub564")
	if old then
		old:Destroy()
	end

	self.gui = create("ScreenGui", {
		Name = "Hub564",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	})
	ProtectGui(self.gui)
	self.gui.Parent = parentGui

	self.Main = create("Frame", {
		Name = "Main",
		Parent = self.gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self.Expanded,
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, { corner(), stroke() })

	-- Cabeçalho
	self.Header = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
	}, {
		create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = THEME.Stroke,
			BorderSizePixel = 0,
		}),
	})

	create("TextLabel", {
		Parent = self.Header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Font = FONTB,
		Text = title .. (subtitle and (" | " .. subtitle) or ""),
		TextColor3 = THEME.Text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	self.status = create("TextLabel", {
		Parent = self.Header,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -84, 0.5, 0),
		Size = UDim2.fromOffset(160, 20),
		BackgroundTransparency = 1,
		Font = FONTR,
		Text = "idle",
		TextColor3 = THEME.Text,
		TextTransparency = 0.35,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	self.MinButton = create("ImageButton", {
		Parent = self.Header,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -46, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		Image = MINIMIZE_ICON,
		ScaleType = Enum.ScaleType.Fit,
	})

	self.CloseButton = create("TextButton", {
		Parent = self.Header,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		Font = FONTB,
		Text = "×",
		TextColor3 = THEME.Text,
		TextSize = 22,
		AutoButtonColor = false,
	})

	-- Abas e conteúdo
	self.TabBar = create("ScrollingFrame", {
		Parent = self.Main,
		Position = UDim2.fromOffset(0, 57),
		Size = UDim2.new(0, 190, 1, -57),
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	})

	create("Frame", {
		Parent = self.Main,
		Position = UDim2.fromOffset(190, 57),
		Size = UDim2.new(0, 1, 1, -57),
		BackgroundColor3 = THEME.Stroke,
		BorderSizePixel = 0,
	})

	self.Content = create("Frame", {
		Parent = self.Main,
		Position = UDim2.fromOffset(191, 57),
		Size = UDim2.new(1, -191, 1, -57),
		BackgroundTransparency = 1,
	})

	-- Ícone do hub (minimizado)
	self.Chip = create("ImageButton", {
		Parent = self.gui,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = MINI_SIZE,
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		Image = HUB_ICON,
		ScaleType = Enum.ScaleType.Fit,
		Visible = false,
	}, { corner(), stroke() })

	-- Notificações
	self.toasts = create("Frame", {
		Parent = self.gui,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(300, 300),
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})

	self.MinButton.MouseButton1Click:Connect(function()
		self:Minimize()
	end)
	self.Chip.MouseButton1Click:Connect(function()
		self:Restore()
	end)
	self.CloseButton.MouseButton1Click:Connect(function()
		if self.onClose then
			pcall(self.onClose)
		end
		self:_flush()
		self.gui:Destroy()
	end)

	makeDraggable(self.Header, self.Main)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift and self.gui.Parent then
			self.gui.Enabled = not self.gui.Enabled
		end
	end)

	-- salva a config a cada 2s quando algo mudou
	task.spawn(function()
		while self.gui.Parent do
			task.wait(2)
			self:_flush()
		end
	end)

	return self
end

function Window:_remember(flag, v)
	if flag then
		self.saved[flag] = v
		self.dirty = true
	end
end

function Window:_flush()
	if self.dirty and writefile then
		self.dirty = false
		pcall(function()
			writefile(self.configFile, HttpService:JSONEncode(self.saved))
		end)
	end
end

function Window:OnClose(fn)
	self.onClose = fn
end

function Window:SetStatus(t)
	self.status.Text = tostring(t)
end

function Window:Minimize()
	self.Chip.Visible = true
	local tween = TweenService:Create(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
		Size = MINI_SIZE,
		Position = MINI_POSITION,
	})
	tween:Play()
	tween.Completed:Connect(function()
		self.Main.Visible = false
	end)
end

function Window:Restore()
	self.Chip.Visible = false
	self.Main.Visible = true
	self.Main.Size = MINI_SIZE
	self.Main.Position = MINI_POSITION
	TweenService:Create(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
		Size = self.Expanded,
		Position = UDim2.fromScale(0.5, 0.5),
	}):Play()
end

function Window:Notify(head, body, duration)
	duration = duration or 3
	if #self.toasts:GetChildren() > 6 then
		return
	end
	local t = create("Frame", {
		Parent = self.toasts,
		Size = UDim2.fromOffset(300, 56),
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, { corner(), stroke() })
	create("TextLabel", {
		Parent = t,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 20),
		Font = FONT,
		Text = tostring(head),
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	create("TextLabel", {
		Parent = t,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -24, 0, 20),
		Font = FONTR,
		Text = tostring(body),
		TextColor3 = THEME.Text,
		TextTransparency = 0.3,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local bar = create("Frame", {
		Parent = t,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = THEME.Main,
		BorderSizePixel = 0,
	})
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 0, 2) }):Play()
	task.delay(duration, function()
		if t.Parent then
			t:Destroy()
		end
	end)
end

----------------------------------------------------------------
-- Abas
----------------------------------------------------------------
function Window:AddTab(icon, name)
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.sections = {}

	tab.Button = create("TextButton", {
		Parent = self.TabBar,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = THEME.Button,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = #self.Tabs + 1,
	}, { corner() })
	tab.ButtonStroke = stroke(tab.Button, THEME.Row)

	local iconImg = create("ImageLabel", {
		Parent = tab.Button,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ImageColor3 = THEME.Text,
	})
	setIcon(iconImg, icon)

	create("TextLabel", {
		Parent = tab.Button,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Font = FONT,
		Text = name,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	tab.Page = create("ScrollingFrame", {
		Parent = self.Content,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
	})

	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	tab.Button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			TweenService:Create(tab.ButtonStroke, TweenInfo.new(0.2), { Color = THEME.Hover }):Play()
		end
	end)
	tab.Button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			TweenService:Create(tab.ButtonStroke, TweenInfo.new(0.2), { Color = THEME.Row }):Play()
		end
	end)

	table.insert(self.Tabs, tab)
	if not self.ActiveTab then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Page.Visible = active
		TweenService:Create(t.ButtonStroke, TweenInfo.new(0.2), {
			Color = active and THEME.Main or THEME.Row,
		}):Play()
	end
	self.ActiveTab = tab
end

----------------------------------------------------------------
-- Seções e componentes
----------------------------------------------------------------
function Tab:AddSection(title)
	local sec = setmetatable({}, Section)
	sec.Window = self.Window
	sec.Page = self.Page
	sec.n = 1
	sec.title = title
	sec.Frame = create("Frame", {
		Parent = self.Page,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
	}, {
		corner(),
		stroke(),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	create("TextLabel", {
		Parent = sec.Frame,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = string.upper(title),
		TextColor3 = THEME.Text,
		TextTransparency = 0.3,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	table.insert(self.sections, sec)
	return sec
end

function Section:Notify(a, b, c)
	self.Window:Notify(a, b, c)
end

function Section:AddLabel(text)
	local l = create("TextLabel", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Text = tostring(text),
		Font = FONTR,
		TextSize = 15,
		TextColor3 = THEME.Text,
		TextTransparency = 0.3,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	return {
		Set = function(_, t)
			l.Text = tostring(t)
		end,
	}
end

function Section:AddButton(text, callback)
	local b = create("TextButton", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Button,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 16,
	}, { corner() })
	hover(b, stroke(b))
	b.MouseButton1Click:Connect(function()
		if callback then
			pcall(callback)
		end
	end)
	return {
		SetText = function(_, t)
			b.Text = tostring(t)
		end,
	}
end

function Section:AddToggle(text, default, callback)
	local value = default and true or false
	local row = create("TextButton", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -46, 1, 0),
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local pill = create("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(40, 20),
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
	}, { corner(), stroke() })
	local knob = create("Frame", {
		Parent = pill,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.25, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = THEME.Hover,
		BorderSizePixel = 0,
	}, { corner(6) })

	local function render(animate)
		TweenService:Create(knob, TweenInfo.new(animate and 0.15 or 0), {
			Position = UDim2.new(value and 0.75 or 0.25, 0, 0.5, 0),
			BackgroundColor3 = value and THEME.Main or THEME.Hover,
		}):Play()
	end
	render(false)

	row.Activated:Connect(function()
		value = not value
		render(true)
		if callback then
			pcall(callback, value)
		end
	end)
	if callback then
		pcall(callback, value)
	end

	return {
		Set = function(_, v, silent)
			value = v and true or false
			render(true)
			if callback and not silent then
				pcall(callback, value)
			end
		end,
		Get = function()
			return value
		end,
	}
end

function Section:AddSlider(text, min, max, default, step, fmt, callback, flag)
	local win = self.Window
	step = step or 1
	fmt = fmt or "%g"
	local value = flag and win.saved[flag]
	if type(value) ~= "number" then
		value = default
	end
	value = math.clamp(value, min, max)

	local row = create("Frame", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
	})
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 0, 18),
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valueLabel = create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(60, 18),
		Font = FONT,
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = create("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = THEME.Row,
		BorderSizePixel = 0,
	}, { corner(nil, 2) })
	local fill = create("Frame", {
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.Main,
		BorderSizePixel = 0,
	}, { corner(nil, 2) })
	local hit = create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
	})

	local function visual()
		local rel = (value - min) / math.max(max - min, 1e-9)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		valueLabel.Text = string.format(fmt, value)
	end
	visual()

	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = min + rel * (max - min)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		if v ~= value then
			value = v
			visual()
			win:_remember(flag, v)
			if callback then
				pcall(callback, v)
			end
		end
	end

	local connMove, connEnd, dragging = nil, nil, false
	local function stop()
		dragging = false
		self.Page.ScrollingEnabled = true
		if connMove then connMove:Disconnect() connMove = nil end
		if connEnd then connEnd:Disconnect() connEnd = nil end
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			stop()
			dragging = true
			self.Page.ScrollingEnabled = false
			setFromX(input.Position.X)
			connMove = UserInputService.InputChanged:Connect(function(i)
				if dragging and (i == input or i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					setFromX(i.Position.X)
				end
			end)
			connEnd = UserInputService.InputEnded:Connect(function(i)
				if i == input then
					stop()
				end
			end)
		end
	end)

	if callback then
		pcall(callback, value)
	end

	return {
		Set = function(_, v)
			value = math.clamp(v, min, max)
			visual()
			win:_remember(flag, value)
			if callback then
				pcall(callback, value)
			end
		end,
		Get = function()
			return value
		end,
	}
end

function Section:AddDropdown(text, options, default, callback, flag)
	local win = self.Window
	local value = flag and win.saved[flag]
	if not table.find(options, value) then
		value = default
	end

	local wrap = create("Frame", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local head = create("TextButton", {
		Parent = wrap,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local box = create("Frame", {
		Parent = head,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(130, 24),
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
	}, { corner(), stroke() })
	local valueLabel = create("TextLabel", {
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -26, 1, 0),
		Font = FONT,
		Text = tostring(value),
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = create("TextLabel", {
		Parent = box,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(12, 14),
		Font = FONTB,
		Text = "v",
		TextColor3 = THEME.Text,
		TextSize = 13,
	})

	local list = create("Frame", {
		Parent = wrap,
		LayoutOrder = 2,
		Visible = false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
	}, {
		corner(),
		stroke(),
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
	})

	local function choose(v, silent)
		value = v
		valueLabel.Text = tostring(v)
		list.Visible = false
		arrow.Text = "v"
		win:_remember(flag, v)
		if callback and not silent then
			pcall(callback, v)
		end
	end

	for i, o in ipairs(options) do
		local ob = create("TextButton", {
			Parent = list,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Font = FONT,
			Text = tostring(o),
			TextColor3 = THEME.Text,
			TextSize = 14,
			TextTransparency = 0.3,
		})
		ob.MouseEnter:Connect(function() ob.TextTransparency = 0 end)
		ob.MouseLeave:Connect(function() ob.TextTransparency = 0.3 end)
		ob.Activated:Connect(function() choose(o) end)
	end

	head.Activated:Connect(function()
		list.Visible = not list.Visible
		arrow.Text = list.Visible and "^" or "v"
	end)

	if callback then
		pcall(callback, value)
	end

	return {
		Set = function(_, v) choose(v) end,
		Get = function() return value end,
	}
end

function Section:AddInput(placeholder, callback, flag)
	local win = self.Window
	local initial = flag and win.saved[flag]
	local box = create("TextBox", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Text = type(initial) == "string" and initial or "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = THEME.Hover,
		TextColor3 = THEME.Text,
		Font = FONT,
		TextSize = 15,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
	}, {
		corner(),
		stroke(),
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	box.FocusLost:Connect(function(enter)
		win:_remember(flag, box.Text)
		if callback then
			pcall(callback, box.Text, enter)
		end
	end)
	return box
end

-- lista de paths com botão X. Mexe diretamente na tabela recebida.
function Section:AddPaths(tbl, flag, validate)
	local win = self.Window
	local sv = flag and win.saved[flag]
	if type(sv) == "table" and #tbl == 0 then
		for _, p in ipairs(sv) do
			if type(p) == "string" then
				table.insert(tbl, p)
			end
		end
	end

	local input = self:AddInput("Paste path here")
	local listFrame = create("Frame", {
		Parent = self.Frame,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local function refresh()
		for _, ch in ipairs(listFrame:GetChildren()) do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		for i, p in ipairs(tbl) do
			local r = create("Frame", {
				Parent = listFrame,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = THEME.Background,
				BorderSizePixel = 0,
			}, { corner(), stroke(nil, THEME.Row) })
			create("TextLabel", {
				Parent = r,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -36, 1, 0),
				Font = FONTR,
				Text = p,
				TextColor3 = THEME.Text,
				TextSize = 13,
				TextTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local x = create("TextButton", {
				Parent = r,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -2, 0.5, 0),
				Size = UDim2.fromOffset(26, 24),
				Font = FONTB,
				Text = "×",
				TextColor3 = THEME.Text,
				TextSize = 18,
				AutoButtonColor = false,
			})
			x.Activated:Connect(function()
				table.remove(tbl, i)
				win:_remember(flag, tbl)
				refresh()
			end)
		end
	end

	self:AddButton("Add Path", function()
		local text = (input.Text:gsub("^%s+", ""):gsub("%s+$", ""))
		if text == "" then
			return
		end
		for _, p in ipairs(tbl) do
			if p == text then
				input.Text = ""
				return
			end
		end
		table.insert(tbl, text)
		input.Text = ""
		win:_remember(flag, tbl)
		refresh()
		if validate and not validate(text) then
			self:Notify("Path", "path not found yet", 3)
		end
	end)
	self:AddButton("Clear All", function()
		table.clear(tbl)
		win:_remember(flag, tbl)
		refresh()
	end)

	refresh()
end

return Library

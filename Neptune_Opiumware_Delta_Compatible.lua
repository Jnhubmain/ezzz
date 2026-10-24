-- Neptune Hub | Redesigned Edition
-- Executor-compatible GUI build (also usable as a LocalScript in your own experience).
-- Self-contained UI with local movement controls, spectate, and player highlights.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
-- Executor-oriented build: avoids privileged APIs and external loaders.
-- Re-execution cleans up connections and visual effects from the previous run.
local function executorGlobal(name)
    local ok, value = pcall(function() return (getfenv and getfenv()[name]) or _G[name] end)
    if ok then return value end
end
local envGetter = executorGlobal("getgenv")
local sharedEnv = _G
if type(envGetter) == "function" then
    local ok, value = pcall(envGetter)
    if ok and type(value) == "table" then sharedEnv = value end
end
if type(sharedEnv.NeptuneRedesignedCleanup) == "function" then
    pcall(sharedEnv.NeptuneRedesignedCleanup)
end
local playerGui = localPlayer:WaitForChild("PlayerGui", 15)
local guiParent = playerGui
local gethuiFn = executorGlobal("gethui")
if type(gethuiFn) == "function" then
    local ok, target = pcall(gethuiFn)
    if ok and typeof(target) == "Instance" then guiParent = target end
end
if not guiParent then
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok then guiParent = core end
end
assert(guiParent, "Neptune: No available GUI parent")
for _, parent in ipairs({guiParent, playerGui}) do
    if parent then
        local existing = parent:FindFirstChild("NeptuneRedesigned")
        if existing then pcall(function() existing:Destroy() end) end
    end
end

local colors = {
    background = Color3.fromRGB(9, 13, 26), panel = Color3.fromRGB(15, 22, 40),
    card = Color3.fromRGB(22, 31, 52), border = Color3.fromRGB(39, 53, 78),
    accent = Color3.fromRGB(65, 130, 255), accentSoft = Color3.fromRGB(34, 63, 123),
    text = Color3.fromRGB(239, 245, 255), muted = Color3.fromRGB(143, 162, 193),
    off = Color3.fromRGB(52, 65, 89), green = Color3.fromRGB(59, 210, 155),
}
local state = {speed=false, jump=false, highlight=false, spectating=false, selected=nil, speedValue=24, jumpValue=75}
local disconnectors = {}
local highlights = {}
local currentTab = "Dashboard"
local stopped = false
local screens = {}
local currentHumanoid
local baseWalkSpeed, baseJumpPower, baseUseJumpPower
local trackedHumanoid

local function new(class, props, parent)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end
local function corner(parent, radius)
    new("UICorner", {CornerRadius=UDim.new(0, radius or 10)}, parent)
end
local function stroke(parent)
    new("UIStroke", {Color=colors.border, Thickness=1}, parent)
end
local function label(parent, content, size, color, bold)
    return new("TextLabel", {BackgroundTransparency=1, Text=content, TextSize=size or 14,
        TextColor3=color or colors.text, Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center}, parent)
end
local gui = new("ScreenGui", {Name="NeptuneRedesigned", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, guiParent)
local protectGui = executorGlobal("protect_gui") or executorGlobal("protectgui")
local synTable = executorGlobal("syn")
if not protectGui and type(synTable) == "table" then protectGui = synTable.protect_gui end
if type(protectGui) == "function" then pcall(protectGui, gui) end
local shadow = new("Frame", {Size=UDim2.fromOffset(806, 534), Position=UDim2.new(0.5,-403,0.5,-267), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.5}, gui)
corner(shadow, 19)
local root = new("Frame", {Size=UDim2.fromOffset(790,520), Position=UDim2.new(0.5,-395,0.5,-260), BackgroundColor3=colors.background, BorderSizePixel=0, ClipsDescendants=true}, gui)
corner(root,16); stroke(root)
local scale = new("UIScale", {Scale=1}, root)
local function fit()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    scale.Scale = math.min(1, (viewport.X-22)/790, (viewport.Y-22)/520)
    shadow.Size = UDim2.fromOffset(806*scale.Scale,534*scale.Scale)
    shadow.Position = UDim2.new(0.5,-403*scale.Scale,0.5,-267*scale.Scale)
end
fit()
if workspace.CurrentCamera then table.insert(disconnectors, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end

local sidebar = new("Frame", {Size=UDim2.fromOffset(205,520), BackgroundColor3=colors.panel, BorderSizePixel=0}, root)
new("Frame", {Size=UDim2.fromOffset(1,520), Position=UDim2.fromOffset(204,0), BackgroundColor3=colors.border, BorderSizePixel=0},sidebar)
local logo = label(sidebar,"◆  NEPTUNE",20,colors.text,true)
logo.Position=UDim2.fromOffset(24,25); logo.Size=UDim2.fromOffset(170,32)
local subtitle = label(sidebar,"REDESIGNED EDITION",10,colors.muted,true)
subtitle.Position=UDim2.fromOffset(26,58); subtitle.Size=UDim2.fromOffset(165,18)
local nav = new("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(11,114), Size=UDim2.fromOffset(184,305)}, sidebar)
new("UIListLayout",{Padding=UDim.new(0,7)},nav)
local content = new("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(205,0), Size=UDim2.fromOffset(585,520)},root)
local title = label(content,"Dashboard",24,colors.text,true)
title.Position=UDim2.fromOffset(28,24); title.Size=UDim2.fromOffset(370,35)
local description = label(content,"A cleaner way to control your experience.",12,colors.muted)
description.Position=UDim2.fromOffset(29,61);description.Size=UDim2.fromOffset(440,20)
local close = new("TextButton",{Text="×", TextSize=24, Font=Enum.Font.Gotham, TextColor3=colors.muted, BackgroundColor3=colors.card,
    Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(535,26),AutoButtonColor=false},content)
corner(close,8)
local body = new("Frame",{BackgroundTransparency=1, Position=UDim2.fromOffset(28,103),Size=UDim2.fromOffset(530,389)},content)
local function screen(name)
    local s = new("ScrollingFrame",{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=3,
        ScrollBarImageColor3=colors.accent,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},body)
    new("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},s)
    new("UIPadding",{PaddingBottom=UDim.new(0,10)},s)
    screens[name]=s; return s
end
local dashboard=screen("Dashboard")
local playerScreen=screen("Player")
local visualScreen=screen("Visuals")
local settingsScreen=screen("Settings")
local navButtons={}
local function switchTab(tab)
    currentTab=tab
    title.Text=tab
    local descriptions={Dashboard="Quick overview and useful tools.", Player="Movement and camera controls.", Visuals="Player visibility options.", Settings="Customize your interface."}
    description.Text=descriptions[tab] or ""
    for name,s in pairs(screens) do s.Visible=(name==tab) end
    for name,b in pairs(navButtons) do
        b.BackgroundColor3=name==tab and colors.accentSoft or colors.panel
        b.TextColor3=name==tab and colors.text or colors.muted
    end
end
for _, entry in ipairs({{"◈","Dashboard"},{"♙","Player"},{"◇","Visuals"},{"⚙","Settings"}}) do
    local tab=entry[2]
    local b = new("TextButton",{Size=UDim2.fromOffset(184,43),BackgroundColor3=colors.panel,
        Text="   "..entry[1].."   "..tab,TextColor3=colors.muted,TextSize=14,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},nav)
    corner(b,9); navButtons[tab]=b
    b.MouseButton1Click:Connect(function()switchTab(tab) end)
end
local bottom=label(sidebar,"v2.1   •   EXECUTOR EDITION",10,colors.muted,true)
bottom.Position=UDim2.fromOffset(24,482);bottom.Size=UDim2.fromOffset(170,20)

local function card(parent,heading,details)
    local f=new("Frame",{Size=UDim2.new(1,-8,0,76),BackgroundColor3=colors.card,BorderSizePixel=0},parent)
    corner(f,12);stroke(f)
    local a=label(f,heading,14,colors.text,true);a.Position=UDim2.fromOffset(17,13);a.Size=UDim2.fromOffset(385,22)
    local b=label(f,details,11,colors.muted);b.Position=UDim2.fromOffset(17,41);b.Size=UDim2.fromOffset(390,19)
    return f
end
local function toggle(parent,heading,details,initial,callback)
    local c=card(parent,heading,details)
    local button=new("TextButton",{Size=UDim2.fromOffset(49,26),Position=UDim2.new(1,-66,0.5,-13),Text="",
        BackgroundColor3=initial and colors.accent or colors.off,AutoButtonColor=false},c)
    corner(button,14)
    local knob=new("Frame",{Size=UDim2.fromOffset(20,20),Position=initial and UDim2.fromOffset(26,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},button)
    corner(knob,10)
    local enabled=initial
    local function set(value)
        enabled=value
        TweenService:Create(button,TweenInfo.new(.15),{BackgroundColor3=value and colors.accent or colors.off}):Play()
        TweenService:Create(knob,TweenInfo.new(.15),{Position=value and UDim2.fromOffset(26,3) or UDim2.fromOffset(3,3)}):Play()
        callback(value)
    end
    button.MouseButton1Click:Connect(function()set(not enabled) end)
    return set
end
local function action(parent,heading,details,caption,callback)
    local c=card(parent,heading,details)
    local b=new("TextButton",{Size=UDim2.fromOffset(100,31),Position=UDim2.new(1,-116,0.5,-15),BackgroundColor3=colors.accentSoft,
        Text=caption,TextColor3=colors.text,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false},c)
    corner(b,8);b.MouseButton1Click:Connect(callback)
    return b
end
local function section(parent,heading)
    local f=new("Frame",{Size=UDim2.new(1,-8,0,30),BackgroundTransparency=1},parent)
    local l=label(f,heading:upper(),11,colors.muted,true);l.Size=UDim2.fromScale(1,1)
end
local info=card(dashboard,"Welcome to Neptune","Modern interface • responsive layout • organized tools")
info.Size=UDim2.new(1,-8,0,90)
section(dashboard,"Quick access")
action(dashboard,"Player controls","Speed, jump and spectator camera","OPEN",function()switchTab("Player")end)
action(dashboard,"Visual options","Highlight other players","OPEN",function()switchTab("Visuals")end)
action(dashboard,"Interface settings","Hide or restore the panel","OPEN",function()switchTab("Settings")end)

section(playerScreen,"Movement")
local function getHumanoid()
    local character=localPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end
local function updateMovement()
    local h=getHumanoid()
    if not h then return end
    if h~=trackedHumanoid then
        trackedHumanoid=h
        baseWalkSpeed=h.WalkSpeed; baseJumpPower=h.JumpPower; baseUseJumpPower=h.UseJumpPower
    end
    h.WalkSpeed=state.speed and state.speedValue or (baseWalkSpeed or 16)
    if state.jump then
        h.UseJumpPower=true; h.JumpPower=state.jumpValue
    else
        h.UseJumpPower=baseUseJumpPower == nil and true or baseUseJumpPower
        h.JumpPower=baseJumpPower or 50
    end
end
local setSpeed=toggle(playerScreen,"Extra movement speed","Local movement setting (24 WalkSpeed)",false,function(v)state.speed=v;updateMovement()end)
local setJump=toggle(playerScreen,"Higher jump","Local jump setting (75 JumpPower)",false,function(v)state.jump=v;updateMovement()end)
section(playerScreen,"Spectator")
local playerSelect=card(playerScreen,"Selected player","Select a player from the list below")
local selectedLabel=playerSelect:FindFirstChildOfClass("TextLabel")
local picker = new("TextButton",{Size=UDim2.fromOffset(130,30),Position=UDim2.new(1,-146,.5,-15),BackgroundColor3=colors.accentSoft,
    Text="CHOOSE PLAYER",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=colors.text},playerSelect)
corner(picker,8)
local roster= new("Frame",{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false},playerScreen)
new("UIListLayout",{Padding=UDim.new(0,5)},roster)
local function stopSpectate()
    state.spectating=false
    local h=getHumanoid()
    if workspace.CurrentCamera and h then workspace.CurrentCamera.CameraSubject=h end
end
local function applySpectate()
    if not state.spectating then return end
    local target=state.selected
    local h=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if h and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject=h end
end
local function buildRoster()
    for _,child in ipairs(roster:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=localPlayer then
            local b=new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=colors.card,Text="   @"..p.Name,
                TextSize=12,TextColor3=colors.text,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},roster)
            corner(b,7)
            b.MouseButton1Click:Connect(function()
                state.selected=p;picker.Text="@"..p.Name;roster.Visible=false;applySpectate()
            end)
        end
    end
end
picker.MouseButton1Click:Connect(function() buildRoster();roster.Visible=not roster.Visible end)
toggle(playerScreen,"Spectate selected player","Switch your camera to the selected player",false,function(v)
    state.spectating=v
    if v then applySpectate() else stopSpectate() end
end)
action(playerScreen,"Return camera","Restore your own character camera","RESET",stopSpectate)

section(visualScreen,"Player overlays")
local function removeHighlight(p)
    if highlights[p] then highlights[p]:Destroy();highlights[p]=nil end
end
local function addHighlight(p)
    removeHighlight(p)
    if not state.highlight or p==localPlayer or not p.Character then return end
    local highlight=new("Highlight",{Name="NeptuneHighlight",FillColor=colors.accent,OutlineColor=colors.text,
        FillTransparency=.75,OutlineTransparency=.12,DepthMode=Enum.HighlightDepthMode.Occluded},p.Character)
    highlights[p]=highlight
end
local function refreshHighlights()
    for _,p in ipairs(Players:GetPlayers())do addHighlight(p)end
end
toggle(visualScreen,"Player highlights","Outline players using Roblox Highlight",false,function(v)
    state.highlight=v
    if v then refreshHighlights() else for p in pairs(highlights)do removeHighlight(p)end end
end)
action(visualScreen,"Refresh highlights","Refresh overlays after players respawn","REFRESH",refreshHighlights)


-- Mobile-friendly reopen button; works without a physical RightShift key.
local floating = new("TextButton", {
    Name="NeptuneOpenButton", Size=UDim2.fromOffset(56,56),
    Position=UDim2.new(0,14,0.5,-28), Text="N", TextSize=22,
    Font=Enum.Font.GothamBold, TextColor3=colors.text,
    BackgroundColor3=colors.accentSoft, BorderSizePixel=0,
    Visible=false, Active=true, ZIndex=200
}, gui)
corner(floating,18); stroke(floating)
local function showHub(visible)
    root.Visible=visible
    shadow.Visible=visible
    floating.Visible=not visible
end
floating.Activated:Connect(function() showHub(true) end)

section(settingsScreen,"Interface")
action(settingsScreen,"Hide interface","Press RightShift to open it again","HIDE",function()showHub(false) end)
action(settingsScreen,"Reset camera","Return camera control to your character","RESET",stopSpectate)
local hint=card(settingsScreen,"Keyboard shortcut","RightShift on desktop; floating N button on mobile")
hint.Size=UDim2.new(1,-8,0,76)

-- Dedicated drag handle: avoids intercepting tab and close button clicks.
local dragging, dragOrigin, rootOrigin, dragPointer
local topDrag = new("TextButton",{
    Name="DragHandle", BackgroundTransparency=1, Text="", AutoButtonColor=false,
    Size=UDim2.fromOffset(405,75), Position=UDim2.fromOffset(218,2),
    ZIndex=1, Active=true
},root)
-- Make this handle visually and interactively subordinate to the title/close controls.
local function startDragging(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging=true
    dragPointer=input
    dragOrigin=input.Position
    rootOrigin=root.Position
end
topDrag.InputBegan:Connect(startDragging)
title.InputBegan:Connect(startDragging)
description.InputBegan:Connect(startDragging)
local function stopDragging(input)
    if input==dragPointer or (input.UserInputType==Enum.UserInputType.MouseButton1 and dragPointer and dragPointer.UserInputType==Enum.UserInputType.MouseButton1) then
        dragging=false;dragPointer=nil
    end
end
table.insert(disconnectors,UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragPointer and dragPointer.UserInputType==Enum.UserInputType.Touch and input~=dragPointer then return end
    local delta = (input.Position - dragOrigin) / scale.Scale
    root.Position=UDim2.new(rootOrigin.X.Scale,rootOrigin.X.Offset+delta.X,rootOrigin.Y.Scale,rootOrigin.Y.Offset+delta.Y)
    shadow.Position=UDim2.new(root.Position.X.Scale,root.Position.X.Offset-8*scale.Scale,root.Position.Y.Scale,root.Position.Y.Offset-7*scale.Scale)
end))
table.insert(disconnectors,UserInputService.InputEnded:Connect(stopDragging))
table.insert(disconnectors,UserInputService.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then
        showHub(not root.Visible)
    end
end))
close.MouseButton1Click:Connect(function() showHub(false) end)
table.insert(disconnectors,localPlayer.CharacterAdded:Connect(function()
    trackedHumanoid=nil
    task.wait(.25)
    updateMovement()
    if not state.spectating then stopSpectate()else applySpectate()end
end))
table.insert(disconnectors,Players.PlayerAdded:Connect(function(p)
    table.insert(disconnectors,p.CharacterAdded:Connect(function()task.wait(.3);addHighlight(p);applySpectate()end))
    addHighlight(p)
end))
table.insert(disconnectors,Players.PlayerRemoving:Connect(function(p)
    removeHighlight(p)
    if state.selected==p then state.selected=nil;picker.Text="CHOOSE PLAYER";stopSpectate() end
end))
for _,p in ipairs(Players:GetPlayers())do
    if p~=localPlayer then table.insert(disconnectors,p.CharacterAdded:Connect(function()task.wait(.3);addHighlight(p);applySpectate()end))end
end
-- Safe shutdown: prevents event duplication when injecting again.
sharedEnv.NeptuneRedesignedCleanup = function()
    if stopped then return end
    stopped = true
    stopSpectate()
    state.speed=false; state.jump=false
    pcall(updateMovement)
    for p in pairs(highlights) do pcall(removeHighlight,p) end
    for _, connection in ipairs(disconnectors) do
        pcall(function() connection:Disconnect() end)
    end
    if gui then pcall(function() gui:Destroy() end) end
end
switchTab("Dashboard")
print("Neptune Redesigned compatible build loaded | RightShift / N button")

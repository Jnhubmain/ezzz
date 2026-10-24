--[[
    NEPTUNE N / COMPACT MENU ONLY
    Original interface rebuilt independently, inspired by the user's Aurora screenshots.
    Standard Roblox client APIs; optional executor file APIs for saving settings.

    Semi TP: equippable flying gear + continuous velocity/LinearVelocity travel,
    with 18 original Neptune map route definitions and dynamic podium fallback.
    Client-side movement can be corrected or blocked by a game server.

    Re-running cleans up the previous copy. RightControl shows/hides the UI.
    Standalone Neptune N menu: no encrypted Headless Hub code, loader, or second menu.
]]

local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local Run = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Http = game:GetService('HttpService')
local TPService = game:GetService('TeleportService')
local Workspace = game:GetService('Workspace')
local me = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = _G
pcall(function() if type(getgenv)=='function' then env=getgenv() end end)
-- Close an older copy of this N menu or its earlier standalone addon (if present).
for _,key in ipairs({'NeptuneNMenuStop','HeadlessNeptuneAddonStop'}) do
    if type(env[key])=='function' then pcall(env[key]) end
end

local COLORS = {
    bg=Color3.fromRGB(21,22,27), card=Color3.fromRGB(31,32,39),
    row=Color3.fromRGB(32,34,42), orange=Color3.fromRGB(255,92,20),
    purple=Color3.fromRGB(155,83,253), text=Color3.fromRGB(230,229,236),
    muted=Color3.fromRGB(148,149,165), off=Color3.fromRGB(52,54,64),
    green=Color3.fromRGB(92,242,152), red=Color3.fromRGB(255,103,112)
}
local W,H=308,350
local signals, createdHighlights, stops = {}, {}, {}
local stopped=false
local function track(signal,fn)
    local c=signal:Connect(fn)
    table.insert(signals,c)
    return c
end
local function make(kind,props,parent)
    local obj=Instance.new(kind)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function corner(item,size)
    return make('UICorner',{CornerRadius=UDim.new(0,size or 7)},item)
end
local function border(item,secondary,thick)
    local s=make('UIStroke',{Color=COLORS.orange,Thickness=thick or 1,Transparency=.03},item)
    local grad=make('UIGradient',{Rotation=12,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,secondary and COLORS.orange or COLORS.purple),
        ColorSequenceKeypoint.new(1,secondary and COLORS.purple or COLORS.orange)
    })},s)
    return s,grad
end
local function label(parent,content,size,color,bold)
    return make('TextLabel',{
        BackgroundTransparency=1,BorderSizePixel=0,Text=content or '',
        TextSize=size or 10,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3=color or COLORS.text,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd
    },parent)
end
local function plainButton(parent,content,props)
    local defaults={BackgroundColor3=COLORS.row,BorderSizePixel=0,Text=content,
        Font=Enum.Font.GothamBold,TextSize=10,TextColor3=COLORS.text,AutoButtonColor=true}
    for k,v in pairs(props or {}) do defaults[k]=v end
    local b=make('TextButton',defaults,parent)
    corner(b,7);border(b)
    return b
end

-- Executor-independent GUI parent, with safe fallbacks.
local guiParent=me:WaitForChild('PlayerGui')
pcall(function()
    if type(gethui)=='function' then
        local hidden=gethui()
        if typeof(hidden)=='Instance' then guiParent=hidden end
    end
end)
local gui=make('ScreenGui',{
    Name='NeptuneNMenuOnly',IgnoreGuiInset=true,ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=700
},guiParent)
pcall(function()
    if type(protect_gui)=='function' then protect_gui(gui) end
end)

local root=make('Frame',{
    Name='Main',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.52,.48),
    Size=UDim2.fromOffset(W,H),BackgroundColor3=COLORS.bg,BorderSizePixel=0,
    Active=true,ClipsDescendants=true
},gui)
corner(root,13);border(root)
local scale=make('UIScale',{Scale=1},root)
local actions=make('Frame',{
    Name='Actions',AnchorPoint=Vector2.new(1,.5),
    Position=UDim2.new(.52,-W/2-12,.48,60),Size=UDim2.fromOffset(128,268),
    BackgroundColor3=COLORS.bg,BorderSizePixel=0,Visible=true,Active=true
},gui)
corner(actions,10);border(actions)
local actionsScale=make('UIScale',{Scale=1},actions)
local menuOpen=true
local hideSideActions=false
local badge=make('Frame',{Position=UDim2.fromOffset(13,107),Size=UDim2.fromOffset(251,40),
    BackgroundColor3=COLORS.bg,BorderSizePixel=0},gui)
corner(badge,11);border(badge,true)
local badgeTitle=label(badge,'NEPTUNE N',12,COLORS.orange,true)
badgeTitle.Position=UDim2.fromOffset(13,6);badgeTitle.Size=UDim2.fromOffset(92,17)
local badgeVersion=label(badge,'MENU  v1.1',8,COLORS.muted)
badgeVersion.Position=UDim2.fromOffset(13,23);badgeVersion.Size=UDim2.fromOffset(100,12)
local performance=label(badge,'-- fps       -- ms',10,COLORS.green,true)
performance.Position=UDim2.fromOffset(119,11);performance.Size=UDim2.fromOffset(125,19)
local dot=make('Frame',{Size=UDim2.fromOffset(7,7),Position=UDim2.fromOffset(108,16),
    BackgroundColor3=COLORS.purple,BorderSizePixel=0},badge)
corner(dot,8)
local showOrb=plainButton(gui,'N',{
    Size=UDim2.fromOffset(41,41),Position=UDim2.fromOffset(12,165),
    BackgroundColor3=COLORS.bg,TextColor3=COLORS.orange,TextSize=16,Visible=false
})
local function layoutForScreen()
    local cam=Workspace.CurrentCamera
    local v=cam and cam.ViewportSize or Vector2.new(1280,720)
    local factor=math.clamp(math.min((v.X-20)/W,(v.Y-28)/H),.57,1)
    -- On narrow screens make all controls smaller and move the side actions lower.
    if v.X<720 then factor=math.min(factor,.82) end
    scale.Scale=factor
    actionsScale.Scale=factor
    actions.Visible=menuOpen and not hideSideActions and (v.X>690)
    root.Position=v.X<720 and UDim2.fromScale(.5,.50) or UDim2.fromScale(.52,.48)
    actions.Position=UDim2.new(v.X<720 and .5 or .52,-W/2*factor-12,.48,60)
    badge.Visible=menuOpen and v.X>690
end
layoutForScreen()
if Workspace.CurrentCamera then
    track(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),layoutForScreen)
end
local header=make('Frame',{Size=UDim2.new(1,0,0,39),BackgroundTransparency=1,
    Active=true},root)
local heading=label(header,'Neptune N',13,COLORS.orange,true)
heading.Position=UDim2.fromOffset(12,9);heading.Size=UDim2.fromOffset(155,19)
for idx,col in ipairs({COLORS.orange,COLORS.purple,Color3.fromRGB(255,180,69)}) do
    local orb=make('Frame',{Position=UDim2.fromOffset(235+(idx-1)*16,13),
        Size=UDim2.fromOffset(9,9),BackgroundColor3=col,BorderSizePixel=0},header)
    corner(orb,9)
end
local close=make('TextButton',{Position=UDim2.fromOffset(290,7),Size=UDim2.fromOffset(16,23),
    Text='×',Font=Enum.Font.GothamBold,TextSize=17,TextColor3=COLORS.muted,
    BackgroundTransparency=1},header)
local nav=make('Frame',{Position=UDim2.fromOffset(7,38),Size=UDim2.fromOffset(W-14,26),
    BackgroundTransparency=1},root)
make('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},nav)
local pages,tabButtons={},{ }
local pageTitles={'Stealing','Player','Visuals','Admin','Misc','Configs'}
local content=make('Frame',{Position=UDim2.fromOffset(7,70),
    Size=UDim2.fromOffset(W-14,H-78),BackgroundTransparency=1},root)
for i,name in ipairs(pageTitles) do
    local btn=make('TextButton',{
        Size=UDim2.fromOffset(i==1 and 53 or i==6 and 49 or 46,25),LayoutOrder=i,
        Text=name,TextSize=9,TextColor3=COLORS.muted,Font=Enum.Font.Gotham,
        BackgroundTransparency=1,AutoButtonColor=false
    },nav)
    local underline=make('Frame',{Name='Line',Position=UDim2.new(0,5,1,-2),
        Size=UDim2.new(1,-10,0,2),BackgroundColor3=COLORS.orange,
        BorderSizePixel=0,Visible=false},btn)
    local page=make('ScrollingFrame',{
        Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=2,ScrollBarImageColor3=COLORS.purple,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),
        ScrollingDirection=Enum.ScrollingDirection.Y,Visible=false,
        ClipsDescendants=true
    },content)
    make('UIListLayout',{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},page)
    make('UIPadding',{PaddingTop=UDim.new(0,1),PaddingRight=UDim.new(0,5),
        PaddingBottom=UDim.new(0,10)},page)
    pages[name]=page;tabButtons[name]=btn
end
local function switchPage(selected)
    for name,page in pairs(pages) do
        page.Visible=name==selected
        local b=tabButtons[name]
        b.TextColor3=name==selected and COLORS.text or COLORS.muted
        b.Line.Visible=name==selected
    end
end
for name,button in pairs(tabButtons) do
    track(button.Activated,function()switchPage(name)end)
end

local function section(page,name)
    local g=make('Frame',{
        Size=UDim2.new(1,-1,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=COLORS.card,BorderSizePixel=0
    },pages[page])
    corner(g,9);border(g)
    make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},g)
    make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},g)
    local t=label(g,name:upper(),9,COLORS.orange,true)
    t.Size=UDim2.new(1,0,0,12);t.LayoutOrder=0
    return g
end
local function row(parent,name)
    local r=make('Frame',{Size=UDim2.new(1,0,0,32),BackgroundColor3=COLORS.row,
        BorderSizePixel=0},parent)
    corner(r,8);border(r,true,.8)
    local title=label(r,name,10,COLORS.text,false)
    title.Position=UDim2.fromOffset(9,0);title.Size=UDim2.new(1,-89,1,0)
    return r,title
end
local setters={}
local settings={speed=false,jump=false,infinite=false,esp=false,baseEsp=false,podiumEsp=false,
    fullbright=false,selectedSlot=1,mount='Auto',travelSpeed=150,
    useRoutes=true,autoInteract=false,fov=70,selectedPlayer='', hideActions=false,
    spectate=false,headlessLook=false,noFog=false}
local function toggle(parent,name,key,handler)
    local r=row(parent,name)
    local control=make('TextButton',{
        Size=UDim2.fromOffset(38,20),Position=UDim2.new(1,-45,.5,-10),
        Text='',BackgroundColor3=COLORS.off,AutoButtonColor=false,BorderSizePixel=0
    },r)
    corner(control,12)
    local thumb=make('Frame',{Size=UDim2.fromOffset(15,15),Position=UDim2.fromOffset(3,2),
        BackgroundColor3=COLORS.text,BorderSizePixel=0},control)
    corner(thumb,12)
    local function set(v)
        settings[key]=(v==true)
        control.BackgroundColor3=settings[key] and COLORS.orange or COLORS.off
        thumb.Position=settings[key] and UDim2.fromOffset(20,2) or UDim2.fromOffset(3,2)
        if handler then
            local ok,err=pcall(handler,settings[key])
            if not ok then warn('[Neptune] '..name..': '..tostring(err)) end
        end
    end
    track(control.Activated,function()set(not settings[key])end)
    setters[key]=set
    set(settings[key] == true)
    return set,r
end
local function action(parent,name,callback)
    local r=row(parent,name)
    local b=plainButton(r,'RUN',{Size=UDim2.fromOffset(48,23),
        Position=UDim2.new(1,-54,.5,-11),TextColor3=COLORS.orange,TextSize=9})
    track(b.Activated,function()
        local ok,err=pcall(callback)
        if not ok then warn('[Neptune] '..name..': '..tostring(err)) end
    end)
    return b,r
end
local function stepper(parent,name,start,minv,maxv,step,callback)
    local current=start
    local r,t=row(parent,name..': '..tostring(current))
    t.Size=UDim2.new(1,-83,1,0)
    local minus=plainButton(r,'-',{Size=UDim2.fromOffset(29,22),
        Position=UDim2.new(1,-64,.5,-11),TextColor3=COLORS.orange,TextSize=14})
    local plus=plainButton(r,'+',{Size=UDim2.fromOffset(29,22),
        Position=UDim2.new(1,-31,.5,-11),TextColor3=COLORS.orange,TextSize=14})
    local function set(v)
        current=math.clamp(v,minv,maxv)
        t.Text=name..': '..tostring(current)
        callback(current)
    end
    track(minus.Activated,function()set(current-step)end)
    track(plus.Activated,function()set(current+step)end)
    return set
end
local function message(parent,contentText)
    local r=make('Frame',{Size=UDim2.new(1,0,0,43),BackgroundColor3=COLORS.row,
        BorderSizePixel=0},parent)
    corner(r,7)
    local t=label(r,contentText,9,COLORS.muted,false)
    t.TextWrapped=true;t.TextTruncate=Enum.TextTruncate.None
    t.Position=UDim2.fromOffset(8,4);t.Size=UDim2.new(1,-16,1,-8)
    return t
end

local cameraOriginal=Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70
local brightOriginal={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient,ClockTime=Lighting.ClockTime}
local oldHumanoid,oldSpeed,oldJump,oldUsesJumpPower=nil,nil,nil,nil
local function characterParts()
    local c=me.Character
    return c,c and c:FindFirstChildOfClass('Humanoid'),c and c:FindFirstChild('HumanoidRootPart')
end
local function applyMovement()
    local _,h=characterParts();if not h then return end
    if oldHumanoid~=h then
        oldHumanoid=h;oldSpeed=h.WalkSpeed;oldJump=h.JumpPower;oldUsesJumpPower=h.UseJumpPower
    end
    h.WalkSpeed=settings.speed and 25 or oldSpeed
    h.UseJumpPower=settings.jump and true or oldUsesJumpPower
    h.JumpPower=settings.jump and 72 or oldJump
end
local function setFullbright(v)
    if v then
        Lighting.Brightness=3
        Lighting.Ambient=Color3.fromRGB(190,190,195)
        Lighting.OutdoorAmbient=Color3.fromRGB(190,190,195)
        Lighting.ClockTime=14
    else
        for k,value in pairs(brightOriginal) do Lighting[k]=value end
    end
end
local function applyFov()
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=settings.fov end
end
local targetPlayer=nil
local spectating=false
local function cameraNormal()
    spectating=false
    local _,h=characterParts()
    if h and Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=h end
end
local function updateSpectate()
    if not spectating or not targetPlayer then return end
    local h=targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass('Humanoid')
    if h and Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=h end
end
local function clearESP()
    for _,h in ipairs(createdHighlights) do
        pcall(function()h:Destroy()end)
    end
    createdHighlights={}
end
local function addESP(obj,color)
    if not obj then return end
    local ok,hl=pcall(function()
        local h=Instance.new('Highlight')
        h.Name='NeptuneClientHighlight'
        h.Adornee=obj
        h.FillColor=color
        h.OutlineColor=COLORS.orange
        h.FillTransparency=.86
        h.OutlineTransparency=.07
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=obj
        return h
    end)
    if ok and hl then table.insert(createdHighlights,hl) end
end
local function refreshESP()
    clearESP()
    if settings.esp then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=me and p.Character then addESP(p.Character,COLORS.purple) end
        end
    end
    local plots=Workspace:FindFirstChild('Plots')
    if plots and settings.baseEsp then
        for _,plot in ipairs(plots:GetChildren()) do
            if plot:IsA('Model') then addESP(plot,Color3.fromRGB(255,170,65)) end
        end
    end
    if plots and settings.podiumEsp then
        local count=0
        for _,plot in ipairs(plots:GetChildren()) do
            local pods=plot:FindFirstChild('AnimalPodiums')
            if pods then
                for _,pod in ipairs(pods:GetChildren()) do
                    if pod:IsA('Model') or pod:IsA('BasePart') then
                        addESP(pod,COLORS.green)
                        count=count+1
                        if count>=25 then return end -- Roblox has a limited highlight budget.
                    end
                end
            end
        end
    end
end

-- Source-derived original Neptune 18-slot map-specific route data follow.
-- These route coordinates are only used near the same game layout.
local ROUTES = {}
ROUTES[1]={podSlots={"1","10"},b1={waypoints={Vector3.new(-352.51,-6.35,6.89),Vector3.new(-353.11,-6.46,113.28),Vector3.new(-333.95,-4.62,100.7)},greenPos=Vector3.new(-349.87,-6.52,82.97)},b2={waypoints={Vector3.new(-352.76,-6.38,114.06),Vector3.new(-351.49,-6.38,7),Vector3.new(-334.8,-5.04,18.9)},greenPos=Vector3.new(-349.42,-6.52,37.47)}}
ROUTES[2]={grab={b1=Vector3.new(-323.62,-4.87,94.83),b2=Vector3.new(-323.81,-4.76,24.58)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-327.32,-5.37,95.53)},greenPos=Vector3.new(-347,-7.27,96.85)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-327.74,-5.26,23.78)},greenPos=Vector3.new(-344.99,-7.16,26.28)}}
ROUTES[3]={podSlots={"3","8"},b1={waypoints={Vector3.new(-352.56,-6.35,6.43),Vector3.new(-352.5,-6.35,113.92),Vector3.new(-319.34,-4.62,99.2)},greenPos=Vector3.new(-345,-6.52,92)},b2={waypoints={Vector3.new(-352.76,-6.38,114.06),Vector3.new(-352.72,-6.38,6.3),Vector3.new(-319.81,-4.62,20.98)},greenPos=Vector3.new(-344,-6.52,29)}}
ROUTES[4]={podSlots={"4","7"},b1={waypoints={Vector3.new(-352.7,-6.38,6.47),Vector3.new(-352.59,-6.35,113.35),Vector3.new(-311.25,-4.57,98.98)},greenPos=Vector3.new(-337.58,-4.42,91.88)},b2={waypoints={Vector3.new(-352.76,-6.38,114.06),Vector3.new(-352.75,-6.38,6.15),Vector3.new(-312.58,-4.62,20.83)},greenPos=Vector3.new(-336.7,-4.62,28.2)}}
ROUTES[5]={podSlots={"5","6"},b1={waypoints={Vector3.new(-352.76,-6.74,7.06),Vector3.new(-352.76,-6.74,114.06),Vector3.new(-303.58,-4.78,102)},greenPos=Vector3.new(-331.3,-4.58,93.2)},b2={waypoints={Vector3.new(-352.76,-6.74,114.06),Vector3.new(-352.76,-6.74,7.06),Vector3.new(-303.48,-4.83,17.91)},greenPos=Vector3.new(-330.4,-4.53,26.6)}}
ROUTES[6]={grab={b1=Vector3.new(-301.05,-4.87,131.8),b2=Vector3.new(-331.58,-4.76,-11.37)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-301.45,-5.12,126.61)},greenPos=Vector3.new(-311.91,-5.37,116.65)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-335.76,-5.26,-9.52)},greenPos=Vector3.new(-345.1,-6.86,-0.77)}}
ROUTES[7]={grab={b1=Vector3.new(-308.95,-4.87,132.27),b2=Vector3.new(-324.12,-4.76,-10.94)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-310.69,-5.12,126.77)},greenPos=Vector3.new(-318.3,-5.37,117.26)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-326.93,-5.26,-7.11)},greenPos=Vector3.new(-330.14,-5.26,3.02)}}
ROUTES[8]={grab={b1=Vector3.new(-316.43,-4.87,131.69),b2=Vector3.new(-316.07,-4.76,-11.31)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-318.12,-5.12,125.58)},greenPos=Vector3.new(-325.05,-5.37,117.7)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-316.66,-5.06,-5.03)},greenPos=Vector3.new(-323.05,-5.26,4.12)}}
ROUTES[9]={grab={b1=Vector3.new(-323.99,-4.87,131.62),b2=Vector3.new(-308.89,-4.76,-11.27)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-325.46,-5.12,125.92)},greenPos=Vector3.new(-335.57,-5.37,116.43)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-310.28,-5.01,-5.47)},greenPos=Vector3.new(-316.93,-5.26,1.19)}}
ROUTES[10]={grab={b1=Vector3.new(-331.34,-4.87,131.85),b2=Vector3.new(-301.45,-4.76,-11.07)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-333.38,-5.12,126.12)},greenPos=Vector3.new(-345.51,-6.87,118.15)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-303.55,-5.11,-5.47)},greenPos=Vector3.new(-310.47,-5.26,0.6)}}
ROUTES[11]={grab={b1=Vector3.new(-331.2,13.13,95.86),b2=Vector3.new(-331.29,13.24,-10.88)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-330.78,6,94.89)},greenPos=Vector3.new(-343.47,-7.27,97.07)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-331.92,5.24,-15.3)},greenPos=Vector3.new(-344.39,-7.16,-15.11)}}
ROUTES[12]={grab={b1=Vector3.new(-331.2,13.13,95.86),b2=Vector3.new(-323.97,13.24,-10.87)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-323.71,6,94.51)},greenPos=Vector3.new(-344.05,-7.27,98.61)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-324.16,5.24,-15.1)},greenPos=Vector3.new(-345.1,-7.16,-10.35)}}
ROUTES[13]={grab={b1=Vector3.new(-316.21,13.13,96.09),b2=Vector3.new(-316.6,13.24,-10.95)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-316.75,6,96.26)},greenPos=Vector3.new(-325.61,-4.87,96.06)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-317.35,5.24,-14.98)},greenPos=Vector3.new(-328.77,-5.01,-12.06)}}
ROUTES[14]={grab={b1=Vector3.new(-309.03,13.13,95.84),b2=Vector3.new(-308.94,13.24,-11.24)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-312.86,5.24,97.53)},greenPos=Vector3.new(-328.82,-5.12,96.22)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-309.42,5.24,-15.15)},greenPos=Vector3.new(-319.79,-5.26,-11.06)}}
ROUTES[15]={grab={b1=Vector3.new(-301.03,13.13,95.45),b2=Vector3.new(-301.38,13.24,-11.37)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-301.73,6,99.7)},greenPos=Vector3.new(-314.93,-4.87,96.29)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-302.82,5.24,-14.83)},greenPos=Vector3.new(-314.2,-5.01,-11.4)}}
ROUTES[16]={grab={b1=Vector3.new(-331.54,13.08,130.61),b2=Vector3.new(-331.39,13.19,23.74)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-331.48,6,129.46)},greenPos=Vector3.new(-344.41,-7.27,131.44)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-331.34,5.24,28.39)},greenPos=Vector3.new(-345.52,-7.16,24.3)}}
ROUTES[17]={grab={b1=Vector3.new(-324.14,13.13,130.98),b2=Vector3.new(-323.67,13.24,24.91)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-323.83,6,129.6)},greenPos=Vector3.new(-343.86,-7.27,132.08)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-323.28,5.24,28.1)},greenPos=Vector3.new(-337.32,-5.26,24.37)}}
ROUTES[18]={grab={b1=Vector3.new(-316.62,13.13,131.5),b2=Vector3.new(-316.54,13.24,24.4)},b1={waypoints={Vector3.new(-352.76,-7.18,7.06),Vector3.new(-353.03,-7.18,113.2),Vector3.new(-315.83,6,132.49)},greenPos=Vector3.new(-331.34,-4.87,132.05)},b2={waypoints={Vector3.new(-352.76,-7.18,114.06),Vector3.new(-352.59,-7.12,13.95),Vector3.new(-316.85,5.24,27.92)},greenPos=Vector3.new(-328.71,-5.01,24.78)}}


local MOUNT_NAMES={
    'Flying Carpet','FlyingCarpet',"Witch's Broom","Witch'sBroom",'WitchBroom',
    "Cupid's Wings","Cupid'sWings",'CupidWings',"Santa's Sleigh", "Santa'sSleigh",
    'SantaSleigh','Waverider'
}
local function norm(text)
    return tostring(text or ''):lower():gsub('[^%w]','')
end
local function findMount(name)
    local char=me.Character
    local pack=me:FindFirstChildOfClass('Backpack')
    local function findIn(parent)
        if not parent then return nil end
        for _,tool in ipairs(parent:GetChildren()) do
            if tool:IsA('Tool') then
                local toolName=norm(tool.Name)
                if name~='Auto' then
                    if toolName==norm(name) then return tool end
                else
                    for _,candidate in ipairs(MOUNT_NAMES) do
                        if toolName==norm(candidate) then return tool end
                    end
                end
            end
        end
    end
    return findIn(char) or findIn(pack)
end
local function availableMounts()
    local options={'Auto'}
    local seen={}
    for _,container in ipairs({me.Character,me:FindFirstChildOfClass('Backpack')}) do
        if container then
            for _,tool in ipairs(container:GetChildren()) do
                if tool:IsA('Tool') and not seen[tool.Name] then
                    for _,n in ipairs(MOUNT_NAMES) do
                        if norm(tool.Name)==norm(n) then
                            table.insert(options,tool.Name)
                            seen[tool.Name]=true
                            break
                        end
                    end
                end
            end
        end
    end
    return options
end
local function plotOwner(plot)
    local sign=plot:FindFirstChild('PlotSign')
    local sg=sign and sign:FindFirstChild('SurfaceGui')
    local frame=sg and sg:FindFirstChild('Frame')
    local t=frame and frame:FindFirstChild('TextLabel')
    local text=t and t.Text or ''
    if text=='' or text=='Empty Base' then return nil end
    return text:gsub("'s [Bb]ase$",''):gsub('%s+$','')
end
local function getPlot()
    local plots=Workspace:FindFirstChild('Plots')
    if not plots then return nil,'Workspace.Plots is unavailable' end
    local myName=norm(me.Name)
    local myDisplay=norm(me.DisplayName)
    local potential,nearest=nil,math.huge
    local _,_,rootPart=characterParts()
    for _,plot in ipairs(plots:GetChildren()) do
        if plot:IsA('Model') then
            local owner=plotOwner(plot)
            if owner then
                local n=norm(owner)
                if targetPlayer then
                    if n==norm(targetPlayer.Name) or n==norm(targetPlayer.DisplayName) then
                        return plot,nil
                    end
                elseif n~=myName and n~=myDisplay then
                    local ok,pivot=pcall(function()return plot:GetPivot().Position end)
                    if ok then
                        local d=rootPart and (pivot-rootPart.Position).Magnitude or math.huge
                        if d<nearest then nearest=d;potential=plot end
                    end
                end
            end
        end
    end
    if targetPlayer then return nil,'Selected player has no loaded base' end
    return potential,potential and nil or 'No occupied enemy bases were found'
end
local function findPodium(plot,slot,sideKey)
    local podiums=plot:FindFirstChild('AnimalPodiums')
    if not podiums then return nil,nil,'Base has no AnimalPodiums' end
    local route=ROUTES[slot]
    local podium
    if sideKey and route then
        -- Original Neptune uses mirrored podium names on opposite sides of the map.
        if route.podSlots then
            local preferred=sideKey=='b1' and route.podSlots[1] or (route.podSlots[2] or route.podSlots[1])
            local alternate=sideKey=='b1' and (route.podSlots[2] or route.podSlots[1]) or route.podSlots[1]
            podium=podiums:FindFirstChild(preferred) or podiums:FindFirstChild(alternate)
        elseif route.grab and route.grab[sideKey] then
            -- Some numbered routes correspond to a physical position rather than
            -- a podium with the same numeric name. Choose the closest real slot.
            local coord=route.grab[sideKey]
            local nearest=math.huge
            for _,candidate in ipairs(podiums:GetChildren()) do
                local claim=candidate:FindFirstChild('Claim')
                local part=claim and claim:FindFirstChild('Main')
                if not part or not part:IsA('BasePart') then
                    part=candidate:IsA('BasePart') and candidate or candidate:FindFirstChildWhichIsA('BasePart',true)
                end
                if part then
                    local dist=(part.Position-coord).Magnitude
                    if dist<nearest then nearest=dist;podium=candidate end
                end
            end
            if nearest>23 then podium=nil end
        end
    end
    podium=podium or podiums:FindFirstChild(tostring(slot))
    if not podium then return nil,nil,'Slot '..slot..' is not loaded / no matching podium' end
    local main=podium:FindFirstChild('Claim')
    local point=main and main:FindFirstChild('Main')
    if not point or not point:IsA('BasePart') then
        point=podium:IsA('BasePart') and podium or podium:FindFirstChildWhichIsA('BasePart',true)
    end
    if not point then return nil,nil,'Slot has no valid position' end
    local prompt=podium:FindFirstChildWhichIsA('ProximityPrompt',true)
    return point,prompt,nil
end

local function knownRoute(plot,slot)
    if not settings.useRoutes then return nil end
    local config=ROUTES[slot]
    if not config then return nil end
    local ok,pos=pcall(function()return plot:GetPivot().Position end)
    if not ok then return nil end
    local side1=Vector3.new(-337,-5,100)
    local side2=Vector3.new(-335,-5,20)
    local d1=(pos-side1).Magnitude
    local d2=(pos-side2).Magnitude
    if math.min(d1,d2)>55 then return nil end
    if d1<=d2 then return config.b1,'b1' end
    return config.b2,'b2'
end

local tpActive=false
local tpCancel=false
local tpStatusLabel=nil
local tpRunButton=nil
local lastTpStatus='Ready'
local function status(message,isError)
    lastTpStatus=message
    if tpStatusLabel then
        tpStatusLabel.Text='STATUS  •  '..message
        tpStatusLabel.TextColor3=isError and COLORS.red or COLORS.muted
    end
end
local function releaseVelocity(objects)
    if objects then
        for _,item in ipairs(objects) do
            pcall(function()item:Destroy()end)
        end
    end
    local _,_,rootPart=characterParts()
    if rootPart then
        pcall(function()rootPart.AssemblyLinearVelocity=Vector3.zero end)
    end
end
local function flyTo(rootPart,destination,speed)
    local attach=Instance.new('Attachment')
    attach.Name='NeptuneFlyAnchor'
    attach.Parent=rootPart
    local lv=Instance.new('LinearVelocity')
    lv.Name='NeptuneSemiVelocity'
    lv.Attachment0=attach
    lv.RelativeTo=Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
    lv.MaxForce=1000000
    pcall(function()lv.ForceLimitsEnabled=false end)
    lv.Parent=rootPart
    local release={lv,attach}
    local started=os.clock()
    local origin=rootPart.Position
    local length=(destination-origin).Magnitude
    local timeout=math.clamp(length/math.max(speed,1)*4+2.2,4,12)
    local previous=rootPart.Position
    local stuckTimer=0
    while not tpCancel and not stopped do
        if not rootPart.Parent or me.Character~=rootPart.Parent then
            releaseVelocity(release);return false,'Character changed'
        end
        local delta=destination-rootPart.Position
        local dist=delta.Magnitude
        if dist<3.25 then releaseVelocity(release);return true end
        if os.clock()-started>timeout then
            releaseVelocity(release);return false,'Travel timed out / server may be blocking movement'
        end
        local directed=delta.Unit*math.min(speed,math.max(26,dist*5))
        lv.VectorVelocity=directed
        pcall(function()rootPart.AssemblyLinearVelocity=directed end)
        task.wait(.035)
        local moved=(rootPart.Position-previous).Magnitude
        if moved<.1 then stuckTimer=stuckTimer+.035 else stuckTimer=0 end
        previous=rootPart.Position
        if stuckTimer>1.7 then
            releaseVelocity(release);return false,'Carpet movement blocked'
        end
    end
    releaseVelocity(release)
    return false,'Cancelled'
end
local function runSemiTP()
    if tpActive then tpCancel=true;status('Cancelling...');return end
    local char,h,rootPart=characterParts()
    if not (char and h and rootPart) or h.Health<=0 then
        status('Your character is not ready',true);return
    end
    local mount=findMount(settings.mount)
    if not mount then
        status('Equip / obtain a flying carpet or compatible gear',true)
        return
    end
    local plot,err=getPlot()
    if not plot then status(err,true);return end
    local route,sideKey=knownRoute(plot,settings.selectedSlot)
    local point,prompt,podErr=findPodium(plot,settings.selectedSlot,sideKey)
    if not point then status(podErr,true);return end
    tpActive=true;tpCancel=false
    if tpRunButton then tpRunButton.Text='CANCEL' end
    task.spawn(function()
        local succeeded,fail=pcall(function()
            if mount.Parent~=char then h:EquipTool(mount) end
            task.wait(.12)
            if mount.Parent~=char then
                status('Could not equip '..mount.Name,true);return
            end
            pcall(function()mount:Activate()end)
            status('Carpet engaged • slot '..settings.selectedSlot)
            -- The source route's Y coordinates are ground-level. Fly several studs above
            -- the traversed positions to keep the mounted character off the floor.
            local target=point.Position+Vector3.new(0,4,0)
            local path={}
            if route and route.waypoints then
                for _,wp in ipairs(route.waypoints) do
                    table.insert(path,Vector3.new(wp.X,math.max(rootPart.Position.Y,wp.Y+7,target.Y),wp.Z))
                end
            else
                -- Unknown/updated map: use actual podium coordinates, no invented map route.
                status('Using live podium location')
            end
            table.insert(path,target)
            for i,destination in ipairs(path) do
                if tpCancel then status('Cancelled');return end
                status('Flying • '..i..'/'..#path..' • slot '..settings.selectedSlot)
                local ok,reason=flyTo(rootPart,destination,settings.travelSpeed)
                if not ok then status(reason,true);return end
            end
            status('Reached slot '..settings.selectedSlot)
            if settings.autoInteract and prompt and prompt.Parent then
                if type(fireproximityprompt)=='function' then
                    local ok=pcall(function()fireproximityprompt(prompt)end)
                    status(ok and 'Reached slot • interaction attempted' or 'Reached slot • interaction failed',not ok)
                else
                    status('At slot • tap the in-game interaction prompt')
                end
            end
        end)
        if not succeeded then status('Semi TP error: '..tostring(fail):sub(1,45),true) end
        tpActive=false;tpCancel=false
        if tpRunButton then tpRunButton.Text='RUN' end
    end)
end

-- Stealing tab: one-button flow and precise slot/gear controls.
local steal=section('Stealing','Semi Teleport')
message(steal,'One button • equip flying gear, choose slot 1–18, then RUN.')
local setSlot=stepper(steal,'Slot',1,1,18,1,function(v)settings.selectedSlot=v;status('Slot '..v..' selected')end)
local mountRow,mountLabel=row(steal,'Flying tool')
mountLabel.Size=UDim2.new(1,-100,1,0)
local mountBtn=plainButton(mountRow,'Auto  v',{
    Size=UDim2.fromOffset(91,23),Position=UDim2.new(1,-96,.5,-11),
    TextColor3=COLORS.orange,TextSize=9
})
local function refreshMountText()
    mountBtn.Text=(settings.mount=='Auto' and 'Auto' or settings.mount):sub(1,12)..' v'
end
track(mountBtn.Activated,function()
    local items=availableMounts()
    local index=1
    for i,value in ipairs(items) do if value==settings.mount then index=i end end
    settings.mount=items[index%#items+1]
    refreshMountText()
    status('Tool: '..settings.mount)
end)
local setTravel=stepper(steal,'Flight speed',150,60,300,30,function(v)settings.travelSpeed=v end)
toggle(steal,'Use original routes','useRoutes')
toggle(steal,'Interact at slot','autoInteract')
local semiRun=action(steal,'Carpet Semi TP',runSemiTP)
tpRunButton=semiRun
local tpStatusRow=make('Frame',{Size=UDim2.new(1,0,0,29),BackgroundTransparency=1},steal)
tpStatusLabel=label(tpStatusRow,'STATUS  •  Ready',9,COLORS.muted)
tpStatusLabel.Size=UDim2.new(1,-6,1,0)
local stealInfo=section('Stealing','Target Base')
message(stealInfo,'Choose a player in Player, or leave unselected to use the nearest occupied enemy base.')
action(stealInfo,'Locate target slot',function()
    local p,err=getPlot();if not p then status(err,true);return end
    local _,sideKey=knownRoute(p,settings.selectedSlot)
    local point,_,e=findPodium(p,settings.selectedSlot,sideKey)
    if point then status('Located '..p.Name..' / slot '..settings.selectedSlot)
    else status(e,true) end
end)

local movement=section('Player','Movement')
toggle(movement,'Speed','speed',function()applyMovement()end)
toggle(movement,'High jump','jump',function()applyMovement()end)
toggle(movement,'Infinite jump','infinite')
track(UIS.JumpRequest,function()
    if settings.infinite then
        local _,h=characterParts()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end
    end
end)
local playersGroup=section('Player','Player Selection')
local searchFrame=make('Frame',{Size=UDim2.new(1,0,0,32),BackgroundColor3=COLORS.row,
    BorderSizePixel=0},playersGroup)
corner(searchFrame,8);border(searchFrame,true,.8)
local searchBox=make('TextBox',{
    Size=UDim2.new(1,-14,1,0),Position=UDim2.fromOffset(7,0),BackgroundTransparency=1,
    Text='',PlaceholderText='Username / display name (optional)',ClearTextOnFocus=false,
    TextColor3=COLORS.text,PlaceholderColor3=COLORS.muted,TextSize=10,
    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left
},searchFrame)
local targetText=message(playersGroup,'Target: nearest occupied enemy base')
local function updateTargetDisplay()
    targetText.Text=targetPlayer and ('Target: '..targetPlayer.DisplayName..'  @'..targetPlayer.Name)
        or 'Target: nearest occupied enemy base'
end
local function pickTarget(fragment)
    fragment=norm(fragment)
    if fragment=='' then targetPlayer=nil;settings.selectedPlayer='';updateTargetDisplay();return true end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=me and (norm(p.Name):find(fragment,1,true) or norm(p.DisplayName):find(fragment,1,true)) then
            targetPlayer=p;settings.selectedPlayer=p.Name;updateTargetDisplay();updateSpectate();return true
        end
    end
    targetText.Text='Player not found';return false
end
track(searchBox.FocusLost,function(enter)
    if enter then pickTarget(searchBox.Text) end
end)
action(playersGroup,'Find player',function()pickTarget(searchBox.Text)end)
action(playersGroup,'Next player',function()
    local list={}
    for _,p in ipairs(Players:GetPlayers())do if p~=me then table.insert(list,p)end end
    if #list==0 then targetText.Text='No other players';return end
    local i=1
    for idx,p in ipairs(list)do if p==targetPlayer then i=idx%#list+1 end end
    targetPlayer=list[i]
    settings.selectedPlayer=targetPlayer.Name
    searchBox.Text=targetPlayer.Name
    updateTargetDisplay();updateSpectate()
end)
action(playersGroup,'Clear selection',function()
    targetPlayer=nil;settings.selectedPlayer='';searchBox.Text='';updateTargetDisplay();cameraNormal()
end)
local viewing=section('Player','Spectate')
toggle(viewing,'Spectate target','spectate',function(v)
    spectating=v
    if not v then cameraNormal()else updateSpectate()end
end)
action(viewing,'Restore camera',function()
    settings.spectate=false;cameraNormal()
    if setters.spectate then setters.spectate(false)end
end)

local visualGroup=section('Visuals','ESP')
toggle(visualGroup,'Player ESP','esp',refreshESP)
toggle(visualGroup,'Base ESP','baseEsp',refreshESP)
toggle(visualGroup,'Podium ESP','podiumEsp',refreshESP)
action(visualGroup,'Refresh visuals',refreshESP)
local visualExtra=section('Visuals','Graphics')
toggle(visualExtra,'Fullbright','fullbright',setFullbright)
local setFOV=stepper(visualExtra,'Camera FOV',70,50,110,5,function(v)
    settings.fov=v;applyFov()
end)

-- Independently implemented, client-local Headless look (not part of the protected VM).
local savedHeadVisuals=setmetatable({}, {__mode='k'})
local function putHeadVisual(item, value)
    if not item or not item.Parent then return end
    if item:IsA('BasePart') then
        if savedHeadVisuals[item]==nil then savedHeadVisuals[item]=item.LocalTransparencyModifier end
        item.LocalTransparencyModifier=value
    elseif item:IsA('Decal') or item:IsA('Texture') then
        if savedHeadVisuals[item]==nil then savedHeadVisuals[item]=item.Transparency end
        item.Transparency=value
    end
end
local function setHeadlessLook(on)
    if not on then
        for item,value in pairs(savedHeadVisuals) do
            pcall(function() if item.Parent then
                if item:IsA('BasePart') then item.LocalTransparencyModifier=value
                else item.Transparency=value end
            end end)
        end
        savedHeadVisuals=setmetatable({}, {__mode='k'})
        return
    end
    local character=me.Character
    local head=character and character:FindFirstChild('Head')
    if head and head:IsA('BasePart') then
        putHeadVisual(head,1)
        for _,child in ipairs(head:GetDescendants()) do
            if child:IsA('Decal') or child:IsA('Texture') then putHeadVisual(child,1) end
        end
    end
end
local fogBefore={FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd}
local atmosphereBefore=setmetatable({}, {__mode='k'})
local function setNoFog(on)
    if on then
        Lighting.FogStart=100000
        Lighting.FogEnd=100000
        for _,obj in ipairs(Lighting:GetChildren())do
            if obj:IsA('Atmosphere') then
                if atmosphereBefore[obj]==nil then atmosphereBefore[obj]=obj.Density end
                obj.Density=0
            end
        end
    else
        Lighting.FogStart=fogBefore.FogStart
        Lighting.FogEnd=fogBefore.FogEnd
        for obj,density in pairs(atmosphereBefore) do
            if obj.Parent then pcall(function()obj.Density=density end) end
        end
        atmosphereBefore=setmetatable({}, {__mode='k'})
    end
end
local cosmetics=section('Visuals','Avatar & World (local only)')
toggle(cosmetics,'Headless appearance','headlessLook',setHeadlessLook)
toggle(cosmetics,'No fog','noFog',setNoFog)
message(cosmetics,'These appearance changes affect only your client. Other players may not see them.')
local info=section('Misc','Menu information')
message(info,'Neptune N only. The original Headless Hub code is not loaded.')

local adminGroup=section('Admin','Local Utilities')
message(adminGroup,'Only locally implemented utilities are shown here.')
action(adminGroup,'List server players',function()
    print('[Neptune] Players in server:')
    for _,p in ipairs(Players:GetPlayers()) do
        print(' - '..p.Name..' ('..p.DisplayName..')')
    end
    status('Player list printed to executor console')
end)
local misc=section('Misc','Actions')
action(misc,'Instant reset',function()
    local _,h=characterParts();if h then h.Health=0 end
end)
action(misc,'Rejoin',function()
    local ok,err=pcall(function()TPService:Teleport(game.PlaceId,me)end)
    if not ok then warn('[Neptune] Rejoin: '..tostring(err))end
end)
action(misc,'Stop Semi TP',function()
    tpCancel=true
    status(tpActive and 'Cancelling...' or 'Nothing running')
end)
action(misc,'Disable ESP',function()
    for _,k in ipairs({'esp','baseEsp','podiumEsp'}) do
        if setters[k] then setters[k](false) end
    end
end)

local actionTitle=label(actions,'Actions',10,COLORS.orange,true)
actionTitle.Position=UDim2.fromOffset(0,10)
actionTitle.Size=UDim2.new(1,0,0,17)
actionTitle.TextXAlignment=Enum.TextXAlignment.Center
local actionItems={
    {'Semi TP',runSemiTP},
    {'Instant Reset',function()local _,h=characterParts();if h then h.Health=0 end end},
    {'Rejoin',function()pcall(function()TPService:Teleport(game.PlaceId,me)end)end},
    {'Spectate',function()spectating=not spectating;if spectating then updateSpectate()else cameraNormal()end end},
    {'Clear ESP',function()for _,key in ipairs({'esp','baseEsp','podiumEsp'})do if setters[key] then setters[key](false) end end end},
    {'Cancel Semi TP',function()tpCancel=true;status('Cancelling...')end},
    {'Hide UI',function()menuOpen=false;root.Visible=false;actions.Visible=false;badge.Visible=false;showOrb.Visible=true end}
}
for i,definition in ipairs(actionItems)do
    local b=plainButton(actions,definition[1],{
        Size=UDim2.fromOffset(112,28),Position=UDim2.fromOffset(8,32+(i-1)*32),
        TextSize=9,TextColor3=COLORS.text
    })
    track(b.Activated,definition[2])
end

local config=section('Configs','Appearance')
toggle(config,'Hide actions panel','hideActions',function(v)
    hideSideActions=v
    actions.Visible=menuOpen and not v
    if not v then layoutForScreen() end
end)
action(config,'Hide hub',function()
    menuOpen=false;root.Visible=false;actions.Visible=false;badge.Visible=false;showOrb.Visible=true
end)
local configFile='NeptuneN/settings.json'
local function folderReady()
    if type(makefolder)~='function' or type(isfolder)~='function' then return false end
    local ok=pcall(function()
        if not isfolder('NeptuneN') then makefolder('NeptuneN')end
    end)
    return ok
end
local function saveConfig()
    if type(writefile)~='function' or not folderReady() then
        status('Executor file saving is unavailable',true);return
    end
    local ok,err=pcall(function()writefile(configFile,Http:JSONEncode(settings))end)
    status(ok and 'Profile saved' or ('Save error: '..tostring(err):sub(1,28)),not ok)
end
local function loadConfig()
    if type(readfile)~='function' then status('Executor file reading is unavailable',true);return end
    local ok,loaded=pcall(function()return Http:JSONDecode(readfile(configFile))end)
    if not ok or type(loaded)~='table' then status('No saved profile found',true);return end
    for key,set in pairs(setters) do
        if type(loaded[key])=='boolean' then set(loaded[key])end
    end
    if tonumber(loaded.selectedSlot) then setSlot(math.floor(loaded.selectedSlot))end
    if tonumber(loaded.travelSpeed) then setTravel(math.floor(loaded.travelSpeed/30+.5)*30)end
    if tonumber(loaded.fov) then setFOV(math.floor(loaded.fov/5+.5)*5)end
    if type(loaded.mount)=='string' then settings.mount=loaded.mount;refreshMountText()end
    if type(loaded.selectedPlayer)=='string' then settings.selectedPlayer=loaded.selectedPlayer
        if loaded.selectedPlayer~='' then searchBox.Text=loaded.selectedPlayer;pickTarget(loaded.selectedPlayer) end
    end
    status('Profile loaded')
end
local profile=section('Configs','Profiles')
action(profile,'Save current',saveConfig)
action(profile,'Load saved',loadConfig)
action(profile,'Restore defaults',function()
    for key,set in pairs(setters) do set(key=='useRoutes') end
    setSlot(1);setTravel(150);setFOV(70)
    settings.mount='Auto';refreshMountText()
    status('Defaults restored')
end)
message(profile,'Configs are saved locally only if your executor supports readfile / writefile.')

local function visible(v)
    menuOpen=v
    root.Visible=v
    actions.Visible=v and not settings.hideActions
    badge.Visible=v
    showOrb.Visible=not v
    if v then layoutForScreen(); actions.Visible=actions.Visible and not settings.hideActions end
end
track(close.Activated,function()visible(false)end)
track(showOrb.Activated,function()visible(true)end)
track(UIS.InputBegan,function(input,processed)
    if not processed and (input.KeyCode==Enum.KeyCode.RightControl
        or input.KeyCode==Enum.KeyCode.RightShift) then visible(not menuOpen) end
end)
-- Header-only drag handling so tabs, switches and close button keep receiving clicks.
local dragging=false
local dragInput,dragPosition,startPosition
track(header.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or
        input.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragInput=input;dragPosition=input.Position;startPosition=root.Position
    end
end)
track(UIS.InputChanged,function(input)
    if not dragging then return end
    if input.UserInputType~=Enum.UserInputType.MouseMovement and
        input.UserInputType~=Enum.UserInputType.Touch then return end
    if dragInput and dragInput.UserInputType==Enum.UserInputType.Touch and input~=dragInput then return end
    local difference=(input.Position-dragPosition)
    root.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+difference.X,
        startPosition.Y.Scale,startPosition.Y.Offset+difference.Y)
    actions.Position=UDim2.new(root.Position.X.Scale,
        root.Position.X.Offset-(W/2+12)*scale.Scale,
        root.Position.Y.Scale,root.Position.Y.Offset+60*scale.Scale)
end)
track(UIS.InputEnded,function(input)
    if input==dragInput or (dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1
        and input.UserInputType==Enum.UserInputType.MouseButton1) then
        dragging=false;dragInput=nil
    end
end)
track(me.CharacterAdded,function()
    oldHumanoid=nil;tpCancel=true
    task.wait(.5)
    if not stopped then applyMovement();if spectating then updateSpectate() end
        if settings.headlessLook then pcall(setHeadlessLook,true) end
    end
end)
track(Players.PlayerRemoving,function(p)
    if p==targetPlayer then targetPlayer=nil;updateTargetDisplay();cameraNormal() end
    task.defer(refreshESP)
end)
track(Players.PlayerAdded,function(p)
    track(p.CharacterAdded,function()
        task.wait(.2);if not stopped then refreshESP()end
    end)
    task.defer(refreshESP)
end)
for _,p in ipairs(Players:GetPlayers()) do
    if p~=me then
        track(p.CharacterAdded,function()
            task.wait(.2);if not stopped then refreshESP()end
        end)
    end
end
local fpsCount,elapsed=0,0
track(Run.RenderStepped,function(dt)
    fpsCount=fpsCount+1;elapsed=elapsed+dt
    if elapsed>=1 then
        local frames=math.floor(fpsCount/elapsed+.5)
        local ping=0
        pcall(function()ping=math.floor(me:GetNetworkPing()*1000+.5)end)
        performance.Text=frames..' fps    '..ping..' ms'
        fpsCount=0;elapsed=0
    end
end)
local _elapsedUpdate=0
track(Run.Heartbeat,function(dt)
    _elapsedUpdate=_elapsedUpdate+dt
    if _elapsedUpdate>.45 then
        _elapsedUpdate=0
        if settings.speed or settings.jump then applyMovement()end
        if spectating then updateSpectate()end
    end
end)

local function stopHub()
    if stopped then return end
    stopped=true;tpCancel=true
    local _,h=characterParts()
    settings.speed=false;settings.jump=false;settings.infinite=false
    pcall(applyMovement)
    cameraNormal();clearESP();pcall(function()setFullbright(false)end)
    pcall(function()setHeadlessLook(false)end)
    pcall(function()setNoFog(false)end)
    pcall(function()if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=cameraOriginal end end)
    for _,c in ipairs(signals) do pcall(function()c:Disconnect()end)end
    pcall(function()gui:Destroy()end)
end
env.NeptuneNMenuStop=stopHub
if type(setters.useRoutes)=='function' then setters.useRoutes(true) end
if type(setters.autoInteract)=='function' then setters.autoInteract(false) end
switchPage('Stealing')
status('Ready • choose slot and flying gear')
print('[Neptune N] Compact menu ready - RightControl / RightShift to toggle.')

-- User-accessible local menu state. No protected Headless code is executed.
env.NeptuneNMenu = {version='1.0',features={'Semi TP','Slot Selector','Mount Picker','Player ESP','Base ESP','Podium ESP','Speed','Jump','Spectate','Fullbright','FOV','Headless Look','No Fog','Profiles'},getStatus=function()return lastTpStatus end,stop=stopHub}

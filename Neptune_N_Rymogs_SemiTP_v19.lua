-- Neptune N startup diagnostics: this is the only UI during initialization.
-- It remains visible only if the main script fails to build.
local function makeStartupNotice()
    local p=game:GetService('Players').LocalPlayer
    local pg=p and (p:FindFirstChildOfClass('PlayerGui') or p:WaitForChild('PlayerGui',12))
    if not pg then return nil,nil end
    local old=pg:FindFirstChild('NeptuneStartupNotice')
    if old then pcall(function()old:Destroy()end) end
    local g=Instance.new('ScreenGui')
    g.Name='NeptuneStartupNotice';g.ResetOnSpawn=false;g.IgnoreGuiInset=true
    g.DisplayOrder=10001;g.Parent=pg
    local f=Instance.new('Frame');f.Name='StartupCard';f.Size=UDim2.fromOffset(290,75)
    f.AnchorPoint=Vector2.new(.5,0);f.Position=UDim2.new(.5,0,0,65)
    f.BackgroundColor3=Color3.fromRGB(14,19,39);f.BorderSizePixel=0;f.Parent=g
    local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,9);c.Parent=f
    local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(106,114,255)
    stroke.Thickness=1.5;stroke.Parent=f
    local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.new(1,-20,1,-12)
    t.Position=UDim2.fromOffset(10,6);t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left
    t.TextYAlignment=Enum.TextYAlignment.Center;t.Font=Enum.Font.GothamBold
    t.TextSize=11;t.TextColor3=Color3.fromRGB(239,233,232)
    t.Text='NEPTUNE N  •  Launching Rymogs Semi TP v1.9…';t.Parent=f
    return g,t
end
local notice,noticeText
local setupOk,setupErr=pcall(function()notice,noticeText=makeStartupNotice()end)
local ok,result=xpcall(function()
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
    bg=Color3.fromRGB(15,15,23), card=Color3.fromRGB(23,22,37),
    row=Color3.fromRGB(34,32,50), blue=Color3.fromRGB(96,158,255),
    purple=Color3.fromRGB(193,104,247), text=Color3.fromRGB(246,240,255),
    muted=Color3.fromRGB(155,147,176), off=Color3.fromRGB(62,53,78),
    green=Color3.fromRGB(98,234,171), red=Color3.fromRGB(251,114,157),
    line=Color3.fromRGB(91,69,123), cyan=Color3.fromRGB(128,211,255)
}
local W,H=485,409
local ryWindowScale=1
-- SxeHub's Luraph v15.1 encoded payload is not executed or silently imported.
-- All controls in this edition are independently implemented and readable.
local signals, createdHighlights, stops = {}, {}, {}
local stopped=false
local function track(signal,fn)
    local c=signal:Connect(fn)
    table.insert(signals,c)
    return c
end
local function make(kind,props,parent)
    local obj=Instance.new(kind)
    for k,v in pairs(props or {}) do
        local ok,err=pcall(function() obj[k]=v end)
        if not ok then warn('[Neptune N] UI property '..tostring(kind)..'.'..tostring(k)..': '..tostring(err)) end
    end
    obj.Parent=parent
    return obj
end
local function corner(item,size)
    return make('UICorner',{CornerRadius=UDim.new(0,size or 7)},item)
end
local function border(item,secondary,thick)
    local quiet=secondary==true
    local stroke=make('UIStroke',{
        Color=COLORS.line,Thickness=thick or (quiet and .85 or 1.15),
        Transparency=quiet and .39 or .08
    },item)
    make('UIGradient',{Rotation=22,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,quiet and COLORS.line or COLORS.blue),
        ColorSequenceKeypoint.new(1,quiet and COLORS.purple or COLORS.purple)
    })},stroke)
    return stroke
end
local function softFill(item)
    make('UIGradient',{Rotation=100,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(30,26,47)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(13,14,23))
    })},item)
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
    corner(b,7);border(b,true,.9)
    return b
end

-- Prioritize PlayerGui: some executor gethui() containers are inaccessible or
-- are not actually rendered. Fall back to the hidden UI root only if needed.
local guiParent=me:FindFirstChildOfClass('PlayerGui') or me:WaitForChild('PlayerGui',12)
if not guiParent and type(gethui)=='function' then
    local ok,hidden=pcall(gethui)
    if ok and typeof(hidden)=='Instance' then guiParent=hidden end
end
assert(guiParent, 'Could not find PlayerGui or an executor GUI parent')
local oldGui=guiParent:FindFirstChild('NeptuneNMenuOnly')
if oldGui then pcall(function()oldGui:Destroy()end)end
local gui=make('ScreenGui',{
    Name='NeptuneNMenuOnly',IgnoreGuiInset=true,ResetOnSpawn=false,
    Enabled=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10000
},nil)
local guiOK=pcall(function()gui.Parent=guiParent end)
if not guiOK or not gui.Parent then
    local ok,hidden=pcall(function()return type(gethui)=='function' and gethui()end)
    if ok and typeof(hidden)=='Instance' then
        guiOK=pcall(function()gui.Parent=hidden end)
    end
end
assert(guiOK and gui.Parent,'Neptune N GUI could not be parented: executor UI permissions denied')

-- The N window and Actions window are separate top-level GUI siblings.
-- Their positions, drag state, and visibility never depend on one another.
local root=make('Frame',{
    Name='Main',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.45,.43),
    Size=UDim2.fromOffset(W,H),BackgroundColor3=COLORS.bg,BorderSizePixel=0,
    Active=true,ClipsDescendants=true,ZIndex=5
},gui)
corner(root,12);border(root,false,1.4);softFill(root)
local scale=make('UIScale',{Scale=1},root)
local actions=make('Frame',{
    Name='Actions',AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.63,.74),Size=UDim2.fromOffset(144,306),
    BackgroundColor3=COLORS.bg,BorderSizePixel=0,Visible=true,Active=true,
    ClipsDescendants=true,ZIndex=5
},gui)
corner(actions,11);border(actions,false,1.4);softFill(actions)
local actionsScale=make('UIScale',{Scale=1},actions)
local menuOpen=true
local hideSideActions=false
local rootWasDragged=false
local actionsWereDragged=false
-- Persistent, independent performance badge (remains live even if N is minimized).
local badge=make('Frame',{Position=UDim2.fromOffset(13,58),Size=UDim2.fromOffset(273,43),
    BackgroundColor3=COLORS.bg,BorderSizePixel=0},gui)
corner(badge,11);border(badge,false,1.1);softFill(badge)
local badgeTitle=label(badge,'NEPTUNE N',11,COLORS.blue,true)
badgeTitle.Position=UDim2.fromOffset(12,5);badgeTitle.Size=UDim2.fromOffset(104,18)
local badgeVersion=label(badge,'RYMOGS TOOLS  •  v1.8',7,COLORS.muted)
badgeVersion.Position=UDim2.fromOffset(12,25);badgeVersion.Size=UDim2.fromOffset(112,11)
local fpsCard=make('Frame',{Position=UDim2.fromOffset(121,9),Size=UDim2.fromOffset(63,26),
    BackgroundColor3=COLORS.card,BorderSizePixel=0},badge)
corner(fpsCard,7)
local fpsText=label(fpsCard,'FPS  --',10,COLORS.cyan,true)
fpsText.Position=UDim2.fromOffset(6,4);fpsText.Size=UDim2.fromOffset(54,18)
local pingCard=make('Frame',{Position=UDim2.fromOffset(190,9),Size=UDim2.fromOffset(75,26),
    BackgroundColor3=COLORS.card,BorderSizePixel=0},badge)
corner(pingCard,7)
local pingText=label(pingCard,'-- ms',10,COLORS.purple,true)
pingText.Position=UDim2.fromOffset(6,4);pingText.Size=UDim2.fromOffset(65,18)
local showOrb=plainButton(gui,'N',{
    Size=UDim2.fromOffset(41,41),Position=UDim2.fromOffset(12,166),
    BackgroundColor3=COLORS.bg,TextColor3=COLORS.blue,TextSize=16,Visible=false
})
-- Actions has its own reopen button, independent from the N toggle.
local showActionsOrb=plainButton(gui,'A',{
    Size=UDim2.fromOffset(36,36),Position=UDim2.fromOffset(61,168),
    BackgroundColor3=COLORS.bg,TextColor3=COLORS.purple,TextSize=15,Visible=false
})
local function layoutForScreen()
    local cam=Workspace.CurrentCamera
    local v=cam and cam.ViewportSize or Vector2.new(1280,720)
    local factor=math.clamp(math.min((v.X-20)/W,(v.Y-28)/H),.64,1)
    if v.X<720 then factor=math.min(factor,.84) end
    scale.Scale=factor*ryWindowScale
    actionsScale.Scale=math.min(factor,.94)*ryWindowScale
    -- Set default positions only: never snap either window back after dragging.
    if not rootWasDragged then
        root.Position=v.X<780 and UDim2.fromScale(.50,.39) or UDim2.fromScale(.45,.43)
    end
    if not actionsWereDragged then
        if v.X<720 then
            actions.Position=UDim2.fromScale(.23,.74)
        else
            actions.Position=UDim2.fromScale(.63,.74)
        end
    end
    actions.Visible=not hideSideActions
    showActionsOrb.Visible=hideSideActions
    badge.Visible=true
end
layoutForScreen()
if Workspace.CurrentCamera then
    track(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),layoutForScreen)
end
local header=make('Frame',{Size=UDim2.new(1,0,0,39),BackgroundTransparency=1,
    Active=true},root)
local heading=label(header,'NEPTUNE   /   N HUB',13,COLORS.text,true)
heading.Position=UDim2.fromOffset(15,9);heading.Size=UDim2.fromOffset(242,19)
for idx,col in ipairs({COLORS.blue,COLORS.purple,COLORS.cyan}) do
    local orb=make('Frame',{Position=UDim2.fromOffset(W-112+(idx-1)*17,13),
        Size=UDim2.fromOffset(9,9),BackgroundColor3=col,BorderSizePixel=0},header)
    corner(orb,9)
end
local close=make('TextButton',{Position=UDim2.new(1,-29,0,7),Size=UDim2.fromOffset(16,23),
    Text='×',Font=Enum.Font.GothamBold,TextSize=17,TextColor3=COLORS.muted,
    BackgroundTransparency=1},header)
local headerDragRegion=make('TextButton',{
    Name='MainDragHandle',Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,-142,0,38),
    BackgroundTransparency=1,Text='',AutoButtonColor=false,Active=true
},header)
-- Reference-inspired left navigation instead of the old horizontal tab strip.
local nav=make('Frame',{Position=UDim2.fromOffset(9,46),
    Size=UDim2.fromOffset(111,H-56),BackgroundColor3=COLORS.card,
    BorderSizePixel=0},root)
corner(nav,8);border(nav,true,.8)
make('UIListLayout',{FillDirection=Enum.FillDirection.Vertical,
    Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
make('UIPadding',{PaddingTop=UDim.new(0,9),PaddingLeft=UDim.new(0,5)},nav)
local pages,tabButtons={},{ }
local pageTitles={'Stealing','Player','Visuals','Admin','Misc','Configs'}
local content=make('Frame',{Position=UDim2.fromOffset(129,48),
    Size=UDim2.fromOffset(W-138,H-58),BackgroundTransparency=1},root)
for i,name in ipairs(pageTitles) do
    local btn=make('TextButton',{
        Size=UDim2.fromOffset(100,35),LayoutOrder=i,
        Text=name,TextSize=10,TextColor3=COLORS.muted,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=COLORS.row,
        BackgroundTransparency=.7,AutoButtonColor=false
    },nav)
    corner(btn,7)
    make('UIPadding',{PaddingLeft=UDim.new(0,12)},btn)
    local underline=make('Frame',{Name='Line',Position=UDim2.fromOffset(2,7),
        Size=UDim2.fromOffset(3,20),BackgroundColor3=COLORS.purple,
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
        b.BackgroundTransparency=name==selected and .08 or .72
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
    corner(g,9);border(g,true,1)
    make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},g)
    make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},g)
    local t=label(g,name:upper(),9,COLORS.blue,true)
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
local settings={speed=false,jump=false,infinite=false,noclip=false,lowGraphics=false,targetHighlight=false,esp=false,baseEsp=false,podiumEsp=false,
    fullbright=false,selectedSlot=1,mount='Auto',travelSpeed=150,semiMode='Adaptive',semiStep=6,
    useRoutes=true,autoInteract=false,fov=70,selectedPlayer='', hideActions=false,
    spectate=false,headlessLook=false,noFog=false,distanceTags=false,crosshair=false,
    ryFpsBoost=false,ryCarpetSpeed=false,ryFloat=false,ryAntiRagdoll=false,
    ryCarpetSpeedValue=140,ryWindowSize=100,ryHotkeys=true,
    ryTPSpeed=480,ryTPHighPingCap=true,ryTPAntiLagback=true}
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
        control.BackgroundColor3=settings[key] and COLORS.blue or COLORS.off
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
        Position=UDim2.new(1,-54,.5,-11),TextColor3=COLORS.blue,TextSize=9})
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
        Position=UDim2.new(1,-64,.5,-11),TextColor3=COLORS.blue,TextSize=14})
    local plus=plainButton(r,'+',{Size=UDim2.fromOffset(29,22),
        Position=UDim2.new(1,-31,.5,-11),TextColor3=COLORS.blue,TextSize=14})
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


-- Restore any collisions this client changed when noclip is switched off.
-- Running only against the local character avoids changing other players or the map.
local noclipOriginal=setmetatable({}, {__mode='k'})
local function updateNoclip()
    if not settings.noclip then
        for part,old in pairs(noclipOriginal) do
            if part.Parent then pcall(function()part.CanCollide=old end) end
        end
        noclipOriginal=setmetatable({}, {__mode='k'})
        return
    end
    local character=me.Character
    if not character then return end
    for _,part in ipairs(character:GetDescendants()) do
        if part:IsA('BasePart') then
            if noclipOriginal[part]==nil then noclipOriginal[part]=part.CanCollide end
            if part.CanCollide then part.CanCollide=false end
        end
    end
end
-- Roblox physics can restore CanCollide each step, so reapply it while enabled.
track(Run.Stepped,function()
    if not stopped and settings.noclip then updateNoclip() end
end)

-- Local graphics mode: caches properties and restores the originals when disabled.
-- Large workspaces are traversed in batches so toggling does not freeze the whole GUI.
local reducedOriginals=setmetatable({}, {__mode='k'})
local graphicsRequest=0
local graphicsTypes={ParticleEmitter=true,Trail=true,Beam=true,Smoke=true,Fire=true,Sparkles=true}
local function setLowGraphics(on)
    graphicsRequest=graphicsRequest+1
    local currentRequest=graphicsRequest
    if not on then
        for obj,original in pairs(reducedOriginals) do
            if obj.Parent then
                pcall(function()
                    for key,value in pairs(original) do obj[key]=value end
                end)
            end
        end
        reducedOriginals=setmetatable({}, {__mode='k'})
        return
    end
    task.spawn(function()
        local count=0
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if stopped or graphicsRequest~=currentRequest or not settings.lowGraphics then return end
            if obj:IsA('BasePart') and not obj:IsDescendantOf(me.Character or Workspace.Terrain) then
                if not reducedOriginals[obj] then
                    reducedOriginals[obj]={CastShadow=obj.CastShadow,Reflectance=obj.Reflectance}
                end
                pcall(function()obj.CastShadow=false;obj.Reflectance=0 end)
            elseif graphicsTypes[obj.ClassName] then
                if not reducedOriginals[obj] then reducedOriginals[obj]={Enabled=obj.Enabled} end
                pcall(function()obj.Enabled=false end)
            end
            count=count+1
            if count%80==0 then task.wait() end
        end
    end)
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
        h.OutlineColor=COLORS.blue
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

-- Independently implemented lightweight distance tags. Local-only UI; no remotes.
local distanceLabels={}
local function clearDistanceTags()
    for _,card in pairs(distanceLabels) do
        pcall(function() card:Destroy() end)
    end
    distanceLabels={}
end
local function updateDistanceTags()
    if not settings.distanceTags then
        if next(distanceLabels) then clearDistanceTags() end
        return
    end
    local myCharacter=me.Character
    local myRoot=myCharacter and myCharacter:FindFirstChild('HumanoidRootPart')
    local seen={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=me then
            local character=p.Character
            local head=character and character:FindFirstChild('Head')
            if head and head:IsA('BasePart') then
                seen[p]=true
                local widget=distanceLabels[p]
                if not widget or not widget.Parent or widget.Adornee~=head then
                    if widget then widget:Destroy() end
                    widget=make('BillboardGui',{
                        Name='NeptuneDistance_'..tostring(p.UserId),
                        Size=UDim2.fromOffset(170,34),
                        StudsOffsetWorldSpace=Vector3.new(0,2.8,0),
                        AlwaysOnTop=true,MaxDistance=600,LightInfluence=0,
                        Adornee=head,ResetOnSpawn=false
                    },guiParent)
                    local display=label(widget,'',11,COLORS.cyan,true)
                    display.Name='DistanceText'
                    display.Size=UDim2.fromScale(1,1)
                    display.TextXAlignment=Enum.TextXAlignment.Center
                    display.TextStrokeTransparency=.25
                    distanceLabels[p]=widget
                end
                local otherRoot=character:FindFirstChild('HumanoidRootPart')
                local distance=(myRoot and otherRoot) and math.floor((myRoot.Position-otherRoot.Position).Magnitude+.5) or nil
                local tag=widget:FindFirstChild('DistanceText')
                if tag then
                    tag.Text=p.DisplayName..(distance and ('  •  '..distance..' studs') or '')
                    tag.TextColor3=(p==targetPlayer) and COLORS.purple or COLORS.cyan
                end
            end
        end
    end
    for p,widget in pairs(distanceLabels) do
        if not seen[p] then pcall(function() widget:Destroy() end);distanceLabels[p]=nil end
    end
end
local selectedHighlight=nil
local function refreshSelectedHighlight()
    if selectedHighlight then pcall(function()selectedHighlight:Destroy()end) end
    selectedHighlight=nil
    if not settings.targetHighlight or not targetPlayer or not targetPlayer.Character then return end
    local ok,h=pcall(function()
        local high=Instance.new('Highlight')
        high.Name='NeptuneSelectedTarget'
        high.Adornee=targetPlayer.Character
        high.FillColor=COLORS.cyan
        high.OutlineColor=COLORS.purple
        high.FillTransparency=.83
        high.OutlineTransparency=0
        high.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        high.Parent=targetPlayer.Character
        return high
    end)
    if ok then selectedHighlight=h end
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
-- Three independent movement strategies. The original protected SxeHub
-- behaviour could not be recovered; this is a new, source-readable approach.
-- Adaptive first attempts Roblox physics movement, then small CFrame steps
-- only if physics stalls. Any server correction is reported as a failure.
local function flyTo(rootPart,destination,speed)
    local function validCharacter()
        return rootPart and rootPart.Parent and me.Character==rootPart.Parent and not stopped
    end
    local function physicsMove()
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
        local start=os.clock()
        local dist0=(destination-rootPart.Position).Magnitude
        local timeout=math.clamp(dist0/math.max(speed,1)*4+3,4,13)
        local previous=rootPart.Position
        local stalled=0
        while not tpCancel and not stopped do
            if not validCharacter() then
                releaseVelocity(release)
                return false,'Character changed',false
            end
            local delta=destination-rootPart.Position
            local remaining=delta.Magnitude
            if remaining<3.5 then
                releaseVelocity(release)
                return true,nil,false
            end
            if os.clock()-start>timeout then
                releaseVelocity(release)
                return false,'Carpet flight timed out',true
            end
            local direction=delta.Unit*math.min(speed,math.max(26,remaining*4))
            lv.VectorVelocity=direction
            pcall(function()rootPart.AssemblyLinearVelocity=direction end)
            task.wait(.045)
            local progress=(rootPart.Position-previous).Magnitude
            stalled=(progress<.12) and (stalled+.045) or 0
            previous=rootPart.Position
            if stalled>1.25 then
                releaseVelocity(release)
                return false,'Carpet flight appears blocked',true
            end
        end
        releaseVelocity(release)
        return false,'Cancelled',false
    end
    local function microStepMove()
        local dist0=(destination-rootPart.Position).Magnitude
        local step=math.clamp(tonumber(settings.semiStep) or 6,2,10)
        local timeout=math.clamp(dist0/math.max(speed,40)*4+3,5,16)
        local begin=os.clock()
        local correctionTime=0
        while not tpCancel and not stopped do
            if not validCharacter() then return false,'Character changed' end
            local delta=destination-rootPart.Position
            local distance=delta.Magnitude
            if distance<3.5 then return true end
            if os.clock()-begin>timeout then return false,'Step movement timed out' end
            local direction=delta.Unit
            local before=rootPart.Position
            local shift=direction*math.min(step,distance)
            local ok=pcall(function()
                -- Retain the avatar's current facing direction while taking
                -- multiple small steps rather than one large teleport.
                rootPart.CFrame=rootPart.CFrame+shift
                rootPart.AssemblyLinearVelocity=direction*math.min(speed,150)
            end)
            if not ok then return false,'Unable to move character assembly' end
            task.wait(.05)
            local improvement=(rootPart.Position-before):Dot(direction)
            if improvement<.5 then
                correctionTime=correctionTime+.05
            else
                correctionTime=0
            end
            if correctionTime>.65 then
                return false,'Server corrected movement; cannot finish TP'
            end
        end
        return false,'Cancelled'
    end
    local mode=settings.semiMode or 'Adaptive'
    if mode~='Steps' then
        local ok,reason,canFallback=physicsMove()
        if ok or mode=='Carpet' or not canFallback or tpCancel then
            return ok,reason
        end
        status('Carpet stalled • trying short steps')
    end
    return microStepMove()
end
-- RYMOGS SEMI TP MOVEMENT ADAPTATION (v1.9)
-- The source's manualFullTP/doVelocityTP depends on its live pet scanner,
-- grapple hook internals, private routing and doClone. Those systems are NOT
-- run here. This module adapts its independently readable smoothRoute,
-- equipped-tool, torso-velocity, timed jump, ping cap and lagback responses
-- for Neptune's existing plot/podium route and 18-slot selection.
local ryTP = {}
function ryTP.smoothRoute(points)
    if type(points)~='table' or #points<3 then return points end
    local spaced={points[1]}
    for i=2,#points do
        local p=points[i]
        if (p-spaced[#spaced]).Magnitude>=2 or i==#points then
            spaced[#spaced+1]=p
        end
    end
    if #spaced<3 then return spaced end
    local reduced={spaced[1]}
    for i=2,#spaced-1 do
        local p=spaced[i]
        local incoming=p-reduced[#reduced]
        local outgoing=spaced[i+1]-p
        if incoming.Magnitude<=.1 or outgoing.Magnitude<=.1 or
            incoming.Unit:Dot(outgoing.Unit)<.995 then
            reduced[#reduced+1]=p
        end
    end
    reduced[#reduced+1]=spaced[#spaced]
    return reduced
end
function ryTP.ping()
    local ok,value=pcall(function()return me:GetNetworkPing()*1000 end)
    if ok and type(value)=='number' and value>=0 and value<60000 then
        return value
    end
    local ok2,ping=pcall(function()
        return game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    end)
    if ok2 and type(ping)=='number' and ping>=0 then return ping end
    return nil
end
function ryTP.flyPath(rootPart,rawPath,tool)
    local path=ryTP.smoothRoute(rawPath)
    if not path or #path==0 then return false,'No destination waypoints' end
    local character=me.Character
    local hum=character and character:FindFirstChildOfClass('Humanoid')
    if not (hum and rootPart and rootPart.Parent==character) then
        return false,'Character is unavailable'
    end
    local originalAutoRotate=hum.AutoRotate
    local driver=character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso') or rootPart
    local speed=math.clamp(tonumber(settings.ryTPSpeed) or 480,200,600)
    local routeDistance=0
    local previous=rootPart.Position
    for _,p in ipairs(path) do
        routeDistance=routeDistance+(p-previous).Magnitude
        previous=p
    end
    local timeout=math.clamp(routeDistance/90*4+8,10,65)
    local began=os.clock()
    local index=1
    local lagbacks=0
    local speedMultiplier=1
    local previousDistance=nil
    local previousPosition=rootPart.Position
    local lastMove=os.clock()
    local lastJump=0
    local lastEquip=0
    local lastPingCheck=0
    local ping=nil
    local failure=nil
    local complete=false
    local function setVelocity(vec)
        if driver and driver.Parent then
            pcall(function()driver.AssemblyLinearVelocity=vec end)
        end
        if rootPart~=driver and rootPart and rootPart.Parent then
            pcall(function()rootPart.AssemblyLinearVelocity=vec end)
        end
    end
    pcall(function()hum.AutoRotate=false end)
    status('Rymogs flight • '..#path..' waypoints • slot '..settings.selectedSlot)
    while not tpCancel and not stopped do
        if not rootPart.Parent or me.Character~=character or not hum.Parent or hum.Health<=0 then
            failure='Character changed or died during flight';break
        end
        local now=os.clock()
        if now-began>timeout then failure='Rymogs flight timed out';break end
        if rootPart.Position.Y < -55 then failure='Flight entered the void';break end
        if tool and tool.Parent~=character and now-lastEquip>.85 then
            lastEquip=now
            pcall(function()hum:EquipTool(tool)end)
            if tool.Parent~=character then
                failure='Flying tool was unequipped';break
            end
        end
        if now-lastPingCheck>.8 then
            lastPingCheck=now
            ping=ryTP.ping()
        end
        local waypoint=path[index]
        local delta=waypoint-rootPart.Position
        local remaining=delta.Magnitude
        -- Rymogs' MK_ARRIVE defaults to 3, with speed-based tolerance.
        local arrival=math.clamp((speed*speedMultiplier)/60*1.25,3,8)
        if remaining<=arrival then
            index=index+1
            previousDistance=nil
            previousPosition=rootPart.Position
            lastMove=now
            if index>#path then
                complete=true;break
            end
            waypoint=path[index]
            delta=waypoint-rootPart.Position
            remaining=delta.Magnitude
            status('Rymogs flight • waypoint '..index..'/'..#path)
        end
        if remaining>.1 then
            local pos=rootPart.Position
            if (pos-previousPosition).Magnitude>.75 or (previousDistance and previousDistance-remaining>.08) then
                lastMove=now
            end
            if now-lastMove>1.4 then
                failure='Rymogs flight stalled (possible game restriction)';break
            end
            -- Detect backward corrections like Rymogs AntiLagbackTP.
            if settings.ryTPAntiLagback and previousDistance and
                remaining-previousDistance>2.5 and (pos-previousPosition).Magnitude>4 then
                lagbacks=lagbacks+1
                speedMultiplier=math.max(.45,speedMultiplier*.7)
                status('Lagback '..lagbacks..' • slowing flight')
                if lagbacks>=4 then
                    failure='Too many lagbacks; server rejected flight';break
                end
            end
            previousPosition=pos
            previousDistance=remaining
            local flightSpeed=speed*speedMultiplier
            if settings.ryTPHighPingCap and ping and ping>=170 then
                flightSpeed=math.min(flightSpeed,350)
            end
            -- Match Rymogs' speed-based waypoint steering with a ceiling on
            -- upward flight velocity, rather than instant CFrame teleport.
            local direction=delta.Unit
            local targetSpeed=math.min(flightSpeed,math.max(50,remaining*4))
            local velocity=direction*targetSpeed
            if velocity.Y>55 then
                velocity=Vector3.new(velocity.X,55,velocity.Z)
            end
            setVelocity(velocity)
            -- Flight jump pulses are an original Rymogs technique.
            if now-lastJump>.18 and hum.FloorMaterial~=Enum.Material.Air then
                lastJump=now
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump=true
                end)
            end
        end
        Run.Heartbeat:Wait()
    end
    setVelocity(Vector3.zero)
    pcall(function()if hum.Parent then hum.AutoRotate=originalAutoRotate end end)
    if tpCancel or stopped then return false,'Cancelled' end
    if failure then return false,failure end
    if not complete then return false,'Rymogs flight stopped before arrival' end
    -- Do NOT force the original script's CFrame snap/clone: these depend on
    -- its game-specific implementation and can be rejected by the server.
    local final=(rootPart.Position-path[#path]).Magnitude
    if final>math.max(9,speed/60*1.25+2) then
        return false,'Arrival position was not reached'
    end
    return true
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
            status('Carpet equipped • '..settings.semiMode..' mode • slot '..settings.selectedSlot)
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
            if settings.semiMode=='Rymogs' then
                local ok,reason=ryTP.flyPath(rootPart,path,mount)
                if not ok then status(reason,true);return end
            else
                for i,destination in ipairs(path) do
                    if tpCancel then status('Cancelled');return end
                    status('Flying • '..i..'/'..#path..' • slot '..settings.selectedSlot)
                    local ok,reason=flyTo(rootPart,destination,settings.travelSpeed)
                    if not ok then status(reason,true);return end
                end
            end
            -- A teleport may appear successful locally and then be rolled back
            -- by the server. Verify the final distance after a short delay.
            task.wait(.4)
            if not rootPart.Parent or (rootPart.Position-target).Magnitude>9 then
                status('Position rolled back or corrected by server',true)
                return
            end
            status('Reached slot '..settings.selectedSlot..' • position verified')
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

-- RYMOGS READABLE-SOURCE ADAPTATION (v1.8)
-- Sources: LEAKEDBYSLICED_RYMOGS.lua: FPS boost/restore, flying-tool speed,
-- floating platform, local anti-ragdoll, UI scaling and default keyboard bindings.
-- Implemented locally for Neptune; does NOT execute the leaked source or
-- adopt its remote interception, invisible stealing, auto-buying or telemetry.
local ryPlus = {}
do
    local Lighting = game:GetService('Lighting')
    local restoration = setmetatable({}, {__mode='k'})
    local boostSerial = 0
    local floatPlatform = nil
    local renderBefore = nil
    local engineSettings = nil
    pcall(function()engineSettings=getfenv().settings end)
    local function saveProperty(obj,key,val)
        if not obj then return end
        local props = restoration[obj]
        if not props then props={};restoration[obj]=props end
        if props[key]==nil then props[key]=val end
    end
    local function changeProperty(obj,key,value)
        local ok,old=pcall(function()return obj[key]end)
        if ok and old~=value then
            saveProperty(obj,key,old)
            pcall(function()obj[key]=value end)
        end
    end
    local function adjustItem(item)
        if not item or not item.Parent or not settings.ryFpsBoost then return end
        if me.Character and item:IsDescendantOf(me.Character) then return end
        -- Do not modify any locally created Neptune GUI / carrier objects.
        if item.Name:sub(1,7)=='Neptune' or item.Name:sub(1,7)=='RyFloat' then return end
        if item:IsA('ParticleEmitter') or item:IsA('Trail') or item:IsA('Beam')
          or item:IsA('Smoke') or item:IsA('Fire') or item:IsA('Sparkles')
          or item:IsA('PointLight') or item:IsA('SpotLight') or item:IsA('SurfaceLight') then
            changeProperty(item,'Enabled',false)
        elseif item:IsA('Decal') or item:IsA('Texture') then
            if not(item.Name=='face' and item.Parent and item.Parent.Name=='Head') then
                changeProperty(item,'Transparency',1)
            end
        elseif item:IsA('BasePart') then
            changeProperty(item,'CastShadow',false)
            changeProperty(item,'Reflectance',0)
        end
    end
    local function restoreAll()
        for obj,props in pairs(restoration) do
            if obj and obj.Parent then
                for key,value in pairs(props) do
                    pcall(function()obj[key]=value end)
                end
            end
        end
        restoration=setmetatable({}, {__mode='k'})
        if renderBefore then
            pcall(function()if type(engineSettings)=='function' then engineSettings().Rendering.QualityLevel=renderBefore end end)
            renderBefore=nil
        end
    end
    function ryPlus.setFPS(on)
        boostSerial=boostSerial+1
        settings.ryFpsBoost=(on==true)
        local serial=boostSerial
        if not on then restoreAll();return end
        pcall(function()
            if type(engineSettings)=='function' then
                renderBefore=engineSettings().Rendering.QualityLevel
                engineSettings().Rendering.QualityLevel=Enum.QualityLevel.Level01
            end
        end)
        changeProperty(Lighting,'GlobalShadows',false)
        changeProperty(Lighting,'FogStart',1000000)
        changeProperty(Lighting,'FogEnd',1000000)
        changeProperty(Lighting,'EnvironmentDiffuseScale',0)
        changeProperty(Lighting,'EnvironmentSpecularScale',0)
        pcall(function()
            local terrain=Workspace.Terrain
            changeProperty(terrain,'WaterWaveSize',0)
            changeProperty(terrain,'WaterWaveSpeed',0)
            changeProperty(terrain,'WaterReflectance',0)
            changeProperty(terrain,'Decoration',false)
        end)
        for _,item in ipairs(Lighting:GetChildren()) do
            if item:IsA('Atmosphere') then changeProperty(item,'Density',0)
            elseif item:IsA('PostEffect') or item:IsA('Clouds') then
                changeProperty(item,'Enabled',false)
            end
        end
        task.spawn(function()
            local descendants=Workspace:GetDescendants()
            for i,item in ipairs(descendants) do
                if stopped or not settings.ryFpsBoost or serial~=boostSerial then return end
                pcall(adjustItem,item)
                if i%150==0 then Run.Heartbeat:Wait() end
            end
        end)
    end
    track(Workspace.DescendantAdded,function(item)
        if settings.ryFpsBoost then pcall(adjustItem,item) end
    end)
    track(Lighting.ChildAdded,function(item)
        if not settings.ryFpsBoost then return end
        if item:IsA('Atmosphere') then changeProperty(item,'Density',0)
        elseif item:IsA('PostEffect') or item:IsA('Clouds') then
            changeProperty(item,'Enabled',false)
        end
    end)
    function ryPlus.setCarpet(on)
        settings.ryCarpetSpeed=(on==true)
        if on then
            local tool=findMount(settings.mount)
            local _,hum=characterParts()
            if tool and hum and tool.Parent~=me.Character then pcall(function()hum:EquipTool(tool)end)end
        end
    end
    local function cleanFloat()
        if floatPlatform then pcall(function()floatPlatform:Destroy()end)end
        floatPlatform=nil
    end
    function ryPlus.setFloat(on)
        settings.ryFloat=(on==true)
        cleanFloat()
        if not on then return end
        local _,hum,rootPart=characterParts()
        if not rootPart or not hum then
            settings.ryFloat=false
            status('Float needs an active character',true)
            return
        end
        local p=Instance.new('Part')
        p.Name='RyFloatPlatform_Neptune';p.Size=Vector3.new(7,1,7)
        p.Anchored=true;p.CanCollide=true;p.CanTouch=false;p.CanQuery=false
        p.Transparency=1;p.CastShadow=false
        p.CFrame=CFrame.new(rootPart.Position-Vector3.new(0,3.35,0))
        p.Parent=Workspace
        floatPlatform=p
    end
    function ryPlus.setAntiRagdoll(on)
        settings.ryAntiRagdoll=(on==true)
    end
    track(Run.Heartbeat,function()
        if stopped then return end
        local _,hum,rootPart=characterParts()
        if settings.ryFloat and floatPlatform and rootPart then
            floatPlatform.CFrame=CFrame.new(rootPart.Position-Vector3.new(0,3.35,0))
        end
        if settings.ryCarpetSpeed and not tpActive and hum and rootPart and hum.Health>0 then
            local tool=findMount(settings.mount)
            if tool and tool.Parent==me.Character then
                local move=hum.MoveDirection
                local velocity=rootPart.AssemblyLinearVelocity
                local speed=math.clamp(tonumber(settings.ryCarpetSpeedValue) or 140,20,400)
                pcall(function()
                    rootPart.AssemblyLinearVelocity=Vector3.new(move.X*speed,velocity.Y,move.Z*speed)
                end)
            end
        end
        if settings.ryAntiRagdoll and hum and hum.Health>0 then
            local state=hum:GetState()
            if state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then
                pcall(function()hum:ChangeState(Enum.HumanoidStateType.Running)end)
            end
        end
    end)
    track(me.CharacterAdded,function()
        -- As in the source, a platform should not persist through respawning.
        settings.ryFloat=false;cleanFloat()
    end)
    function ryPlus.setWindowScale(value)
        local factor=math.clamp(tonumber(value) or 1,.65,1.25)
        ryWindowScale=factor
        settings.ryWindowSize=math.floor(factor*100+.5)
        layoutForScreen()
        local view=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
        for _,child in ipairs(gui:GetChildren()) do
            if child:IsA('Frame') then
                local uiScale=child:FindFirstChildOfClass('UIScale')
                if uiScale and child.Name:match('^Mini_') then
                    uiScale.Scale=(view.X<950 and .84 or 1)*ryWindowScale
                elseif uiScale and child.Name=='WindowDock' then
                    uiScale.Scale=math.min(1,(view.X-20)/585)*ryWindowScale
                end
            end
        end
    end
    function ryPlus.stop()
        boostSerial=boostSerial+1
        settings.ryFpsBoost=false;restoreAll()
        settings.ryCarpetSpeed=false;settings.ryAntiRagdoll=false
        settings.ryFloat=false;cleanFloat()
    end
end

-- Stealing tab: one-button flow and precise slot/gear controls.
local steal=section('Stealing','Semi Teleport')
message(steal,'Select slot 1–18, choose a carpet, then press RUN. Adaptive mode attempts carpet flight first.')
local setSlot=stepper(steal,'Slot',1,1,18,1,function(v)settings.selectedSlot=v;status('Slot '..v..' selected')end)
local mountRow,mountLabel=row(steal,'Flying tool')
mountLabel.Size=UDim2.new(1,-100,1,0)
local mountBtn=plainButton(mountRow,'Auto  v',{
    Size=UDim2.fromOffset(91,23),Position=UDim2.new(1,-96,.5,-11),
    TextColor3=COLORS.blue,TextSize=9
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
local modeRow,modeLabel=row(steal,'Semi TP mode')
modeLabel.Size=UDim2.new(1,-111,1,0)
local modeButton=plainButton(modeRow,'Adaptive  v',{
    Size=UDim2.fromOffset(105,23),Position=UDim2.new(1,-110,.5,-11),
    TextColor3=COLORS.purple,TextSize=9
})
local modeOptions={'Adaptive','Carpet','Steps','Rymogs'}
local function setSemiMode(value)
    if value~='Adaptive' and value~='Carpet' and value~='Steps' and value~='Rymogs' then value='Adaptive' end
    settings.semiMode=value
    modeButton.Text=value..'  v'
end
track(modeButton.Activated,function()
    local current=1
    for i,value in ipairs(modeOptions) do if value==settings.semiMode then current=i break end end
    setSemiMode(modeOptions[current%#modeOptions+1])
    status('Semi TP mode: '..settings.semiMode)
end)
local setSemiStep=stepper(steal,'Step distance',6,2,10,1,function(v)settings.semiStep=v end)
local setRyTPSpeed=stepper(steal,'Rymogs TP speed',480,200,600,40,function(v)settings.ryTPSpeed=v end)
toggle(steal,'Rymogs high-ping cap','ryTPHighPingCap')
toggle(steal,'Rymogs anti-lagback','ryTPAntiLagback')
message(steal,'Rymogs mode uses smooth physics flight, jump pulses, ping cap and lagback slowdown. No forced instant teleport or private game remotes.')
action(steal,'Equip selected flying tool',function()
    local tool=findMount(settings.mount)
    local _,h=characterParts()
    if not tool then status('No matching carpet or flying gear in inventory',true);return end
    if not h then status('Character not ready',true);return end
    if tool.Parent~=me.Character then
        local ok,err=pcall(function()h:EquipTool(tool)end)
        if not ok then status('Equip failed: '..tostring(err):sub(1,36),true);return end
    end
    status(tool.Parent==me.Character and ('Equipped '..tool.Name) or 'Tool equip not confirmed',tool.Parent~=me.Character)
end)
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
toggle(movement,'Noclip (local)','noclip',function()updateNoclip()end)
toggle(movement,'Infinite jump','infinite')
toggle(movement,'Carpet Speed (Rymogs)','ryCarpetSpeed',ryPlus.setCarpet)
toggle(movement,'Float Platform (Rymogs)','ryFloat',ryPlus.setFloat)
toggle(movement,'Anti Ragdoll (local)','ryAntiRagdoll',ryPlus.setAntiRagdoll)
local setRyCarpetSpeed=stepper(movement,'Carpet Speed',140,20,400,20,function(v)settings.ryCarpetSpeedValue=v end)
action(movement,'Sit / stand',function()
    local _,h=characterParts()
    if not h then status('Character not ready',true);return end
    h.Sit=not h.Sit
    status(h.Sit and 'Sitting' or 'Standing')
end)
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
local targetDistanceText=message(playersGroup,'Target distance: --')
local function updateTargetDisplay()
    targetText.Text=targetPlayer and ('Target: '..targetPlayer.DisplayName..'  @'..targetPlayer.Name)
        or 'Target: nearest occupied enemy base'
end
local function pickTarget(fragment)
    fragment=norm(fragment)
    if fragment=='' then targetPlayer=nil;settings.selectedPlayer='';updateTargetDisplay();refreshSelectedHighlight();return true end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=me and (norm(p.Name):find(fragment,1,true) or norm(p.DisplayName):find(fragment,1,true)) then
            targetPlayer=p;settings.selectedPlayer=p.Name;updateTargetDisplay();updateSpectate();refreshSelectedHighlight();return true
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
    updateTargetDisplay();updateSpectate();refreshSelectedHighlight()
end)
action(playersGroup,'Clear selection',function()
    targetPlayer=nil;settings.selectedPlayer='';searchBox.Text='';updateTargetDisplay();refreshSelectedHighlight();cameraNormal()
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
toggle(visualGroup,'Highlight selected target','targetHighlight',refreshSelectedHighlight)
toggle(visualGroup,'Player distance tags','distanceTags',updateDistanceTags)
action(visualGroup,'Refresh visuals',refreshESP)
-- Center-dot crosshair for mobile and desktop; shown only on this client.
local crosshair=make('Frame',{
    Name='NeptuneCrosshair',AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(6,6),
    BackgroundColor3=COLORS.cyan,BorderSizePixel=0,Visible=false,ZIndex=15
},gui)
corner(crosshair,6)
border(crosshair,true,.8)
local crossSection=section('Visuals','Reticle')
toggle(crossSection,'Center-dot crosshair','crosshair',function(enabled) crosshair.Visible=enabled end)
local visualExtra=section('Visuals','Graphics')
toggle(visualExtra,'Fullbright','fullbright',setFullbright)
toggle(visualExtra,'Low graphics (local)','lowGraphics',setLowGraphics)
toggle(visualExtra,'FPS Boost (Rymogs)','ryFpsBoost',ryPlus.setFPS)
message(visualExtra,'FPS Boost hides effects and textures and restores saved visual settings when disabled.')
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
message(info,'Includes readable Rymogs-derived local tools: FPS Boost, Carpet Speed, Float, Anti Ragdoll, UI scaling and keybinds. The original leaked hub and game-specific remotes are not executed.')

local adminGroup=section('Admin','Local Utilities')
message(adminGroup,'Only locally implemented utilities are shown here.')
action(adminGroup,'List server players',function()
    print('[Neptune] Players in server:')
    for _,p in ipairs(Players:GetPlayers()) do
        print(' - '..p.Name..' ('..p.DisplayName..')')
    end
    status('Player list printed to executor console')
end)
action(adminGroup,'Print my coordinates',function()
    local _,_,rootPart=characterParts()
    if not rootPart then status('Character not ready',true);return end
    local position=rootPart.Position
    local value=string.format('%.1f, %.1f, %.1f',position.X,position.Y,position.Z)
    print('[Neptune] Position: '..value)
    if type(setclipboard)=='function' then
        local ok=pcall(function()setclipboard(value)end)
        status(ok and ('Coordinates copied: '..value) or ('Coordinates printed: '..value))
    else
        status('Coordinates printed: '..value)
    end
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

local actionsHeader=make('Frame',{
    Name='ActionsHeader',Size=UDim2.new(1,0,0,31),
    BackgroundColor3=COLORS.card,BorderSizePixel=0,Active=true
},actions)
corner(actionsHeader,9)
local actionsAccent=make('Frame',{
    Position=UDim2.new(0,10,1,-2),Size=UDim2.new(1,-20,0,2),
    BackgroundColor3=COLORS.blue,BorderSizePixel=0
},actionsHeader)
make('UIGradient',{Color=ColorSequence.new(COLORS.blue,COLORS.purple)},actionsAccent)
local actionTitle=label(actionsHeader,'ACTIONS',11,COLORS.purple,true)
actionTitle.Position=UDim2.fromOffset(11,7)
actionTitle.Size=UDim2.fromOffset(102,17)
local actionClose=make('TextButton',{
    Size=UDim2.fromOffset(20,22),Position=UDim2.new(1,-25,0,4),
    Text='×',Font=Enum.Font.GothamBold,TextSize=16,
    TextColor3=COLORS.muted,BackgroundTransparency=1,
    AutoButtonColor=true
},actionsHeader)
local actionsDragRegion=make('TextButton',{
    Name='ActionsDragHandle',Size=UDim2.fromOffset(114,30),
    BackgroundTransparency=1,Text='',AutoButtonColor=false,Active=true
},actionsHeader)
local actionItems={
    {'Semi TP',runSemiTP},
    {'Instant Reset',function()local _,h=characterParts();if h then h.Health=0 end end},
    {'Rejoin',function()pcall(function()TPService:Teleport(game.PlaceId,me)end)end},
    {'Spectate',function()spectating=not spectating;if spectating then updateSpectate()else cameraNormal()end end},
    {'Clear ESP',function()for _,key in ipairs({'esp','baseEsp','podiumEsp'})do if setters[key] then setters[key](false) end end end},
    {'Noclip',function()if setters.noclip then setters.noclip(not settings.noclip) end end},
    {'Cancel Semi TP',function()tpCancel=true;status('Cancelling...')end},
    {'Hide N Menu',function()menuOpen=false;root.Visible=false;showOrb.Visible=true end}
}
for i,definition in ipairs(actionItems)do
    local b=plainButton(actions,definition[1],{
        Size=UDim2.fromOffset(128,28),Position=UDim2.fromOffset(8,37+(i-1)*33),
        TextSize=9,TextColor3=COLORS.text
    })
    track(b.Activated,definition[2])
end

local config=section('Configs','Appearance')
toggle(config,'Hide actions panel','hideActions',function(v)
    hideSideActions=v
    actions.Visible=not v
    showActionsOrb.Visible=v
end)
action(config,'Hide N menu',function()
    menuOpen=false;root.Visible=false;showOrb.Visible=true
end)
-- The SxeHub wrapper exposes a Base64 decoder. Its game code is encrypted.
-- This portable profile feature reuses ONLY that data-encoding idea.
-- No SxeHub payload, remote script, or user-pasted code is executed.
local base64Chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local base64Lookup={}
for i=1,#base64Chars do base64Lookup[base64Chars:sub(i,i)]=i-1 end
local function encodeBase64(src)
    local output={}
    for i=1,#src,3 do
        local a,b,c=src:byte(i,i+2)
        local triple=a*65536+(b or 0)*256+(c or 0)
        local x=math.floor(triple/262144)%64
        local y=math.floor(triple/4096)%64
        local z=math.floor(triple/64)%64
        local w=triple%64
        output[#output+1]=base64Chars:sub(x+1,x+1)..base64Chars:sub(y+1,y+1)
            ..(b and base64Chars:sub(z+1,z+1) or '=')
            ..(c and base64Chars:sub(w+1,w+1) or '=')
    end
    return table.concat(output)
end
local function decodeBase64(input)
    if type(input)~='string' or #input>16000 then return nil,'Invalid or oversized profile' end
    input=input:gsub('%s+','')
    if #input==0 or #input%4~=0 or input:find('[^A-Za-z0-9+/=]') then return nil,'Invalid Base64' end
    local out={}
    for i=1,#input,4 do
        local a,b,c,d=input:sub(i,i),input:sub(i+1,i+1),input:sub(i+2,i+2),input:sub(i+3,i+3)
        if not base64Lookup[a] or not base64Lookup[b] then return nil,'Invalid profile characters' end
        if (c=='=' and d~='=') or (i<#input-3 and (c=='=' or d=='=')) then return nil,'Incorrect Base64 padding' end
        local v=base64Lookup[a]*262144+base64Lookup[b]*4096+(base64Lookup[c] or 0)*64+(base64Lookup[d] or 0)
        out[#out+1]=string.char(math.floor(v/65536)%256)
        if c~='=' then out[#out+1]=string.char(math.floor(v/256)%256) end
        if d~='=' then out[#out+1]=string.char(v%256) end
    end
    return table.concat(out)
end
local function applySettingsData(loaded)
    if type(loaded)~='table' then return false end
    for key,set in pairs(setters) do
        if type(loaded[key])=='boolean' then set(loaded[key]) end
    end
    if tonumber(loaded.selectedSlot) then setSlot(math.floor(loaded.selectedSlot)) end
    if tonumber(loaded.travelSpeed) then setTravel(math.floor(loaded.travelSpeed/30+.5)*30) end
    if tonumber(loaded.semiStep) then setSemiStep(math.floor(loaded.semiStep+.5)) end
    if tonumber(loaded.ryTPSpeed) then setRyTPSpeed(math.floor(loaded.ryTPSpeed/40+.5)*40) end
    if type(loaded.semiMode)=='string' then setSemiMode(loaded.semiMode) end
    if tonumber(loaded.fov) then setFOV(math.floor(loaded.fov/5+.5)*5) end
    if tonumber(loaded.ryCarpetSpeedValue) then setRyCarpetSpeed(math.floor(loaded.ryCarpetSpeedValue/20+.5)*20)end
    if tonumber(loaded.ryWindowSize) then ryPlus.setWindowScale(loaded.ryWindowSize/100)end
    if type(loaded.mount)=='string' and #loaded.mount<100 then
        settings.mount=loaded.mount;refreshMountText()
    end
    if type(loaded.selectedPlayer)=='string' and #loaded.selectedPlayer<100 then
        settings.selectedPlayer=loaded.selectedPlayer
        searchBox.Text=loaded.selectedPlayer
        pickTarget(loaded.selectedPlayer)
    end
    return true
end
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
    applySettingsData(loaded)
    status('Profile loaded')
end
local profile=section('Configs','Profiles')
action(profile,'Save current',saveConfig)
action(profile,'Load saved',loadConfig)
-- Converts only plain saved options; never loads/executed Lua from the source.
action(profile,'Import Rymogs config',function()
    if type(readfile)~='function' or type(isfile)~='function' then
        status('Executor cannot read saved Rymogs configs',true);return
    end
    local path='rymogspriv_config.json'
    local exists=false
    pcall(function()exists=isfile(path)end)
    if not exists then status('No rymogspriv_config.json found',true);return end
    local ok,old=pcall(function()return Http:JSONDecode(readfile(path))end)
    if not ok or type(old)~='table' then status('Rymogs config is invalid',true);return end
    local toggles=type(old.Toggles)=='table' and old.Toggles or {}
    local maps={AntiRagdoll='ryAntiRagdoll',Float='ryFloat',
        CarpetSpeed='ryCarpetSpeed',InfiniteJump='infinite'}
    local count=0
    for oldName,newName in pairs(maps) do
        if type(toggles[oldName])=='boolean' and setters[newName] then
            setters[newName](toggles[oldName]);count=count+1
        end
    end
    if type(old.FlyingTool)=='string' and #old.FlyingTool<80 then
        settings.mount=old.FlyingTool;refreshMountText();count=count+1
    end
    if tonumber(old.UIScale) then
        ryPlus.setWindowScale(old.UIScale);count=count+1
    end
    local sideFile='rymogspriv_sidetp.json'
    local sideOK,sideConfig=pcall(function()
        if isfile(sideFile) then return Http:JSONDecode(readfile(sideFile))end
    end)
    if sideOK and type(sideConfig)=='table' then
        if tonumber(sideConfig.tpVelocity) then
            setRyTPSpeed(math.floor(math.clamp(sideConfig.tpVelocity,200,600)/40+.5)*40)
            count=count+1
        end
        if type(sideConfig.antiLagbackTP)=='boolean' and setters.ryTPAntiLagback then
            setters.ryTPAntiLagback(sideConfig.antiLagbackTP)
            count=count+1
        end
    end
    status('Imported '..count..' Rymogs preferences')
end)
action(profile,'Restore defaults',function()
    for key,set in pairs(setters) do set(key=='useRoutes' or key=='ryTPHighPingCap' or key=='ryTPAntiLagback') end
    setSlot(1);setTravel(150);setSemiMode('Adaptive');setSemiStep(6);setRyTPSpeed(480);setFOV(70)
    settings.mount='Auto';refreshMountText()
    setRyCarpetSpeed(140);ryPlus.setWindowScale(1)
    status('Defaults restored')
end)
message(profile,'Configs are saved locally only if your executor supports readfile / writefile.')
local share=section('Configs','Portable Profile')
message(share,'Uses Base64 data encoding from the readable SxeHub wrapper. Imports settings only; it never runs pasted Lua.')
local shareBox=make('TextBox',{
    Name='PortableProfile',Size=UDim2.new(1,0,0,76),
    BackgroundColor3=COLORS.row,BorderSizePixel=0,
    Text='',PlaceholderText='Exported profile code appears here. Paste one to import.',
    TextSize=9,TextColor3=COLORS.text,PlaceholderColor3=COLORS.muted,
    Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,MultiLine=true,
    ClearTextOnFocus=false
},share)
corner(shareBox,8);border(shareBox,true,.8)
action(share,'Export settings',function()
    local success,encoded=pcall(function()
        return 'NEPTUNE1:'..encodeBase64(Http:JSONEncode({schema=1,settings=settings}))
    end)
    if not success then status('Could not export settings',true);return end
    shareBox.Text=encoded
    local clipper=type(setclipboard)=='function' and setclipboard
        or (type(toclipboard)=='function' and toclipboard or nil)
    local copied=false
    if clipper then copied=pcall(function()clipper(encoded)end) end
    status(copied and 'Profile copied to clipboard' or 'Profile created in text box')
end)
action(share,'Import settings',function()
    local encoded=shareBox.Text:gsub('%s+','')
    local payload=encoded:match('^NEPTUNE1:(.+)$')
    if not payload then status('Paste a NEPTUNE1 profile',true);return end
    local decoded,err=decodeBase64(payload)
    if not decoded then status(err or 'Invalid profile',true);return end
    local ok,profileData=pcall(function()return Http:JSONDecode(decoded)end)
    if not ok or type(profileData)~='table' or profileData.schema~=1
        or type(profileData.settings)~='table' then
        status('Invalid or unsupported profile data',true);return
    end
    applySettingsData(profileData.settings)
    status('Portable profile imported')
end)
action(share,'Clear profile box',function()shareBox.Text='';status('Profile box cleared')end)
local layoutTools=section('Configs','Window Layout')
local setRyWindowScale=stepper(layoutTools,'UI Size %',100,65,125,5,function(v)ryPlus.setWindowScale(v/100)end)
toggle(layoutTools,'Keyboard shortcuts','ryHotkeys')
message(layoutTools,'Q carpet speed  •  B float  •  H walk speed  •  T semi TP; ignored while typing.')
action(layoutTools,'Recenter both windows',function()
    rootWasDragged=false;actionsWereDragged=false
    layoutForScreen()
    status('N and Actions positions restored')
end)

-- Completely independent window controls. Hiding N does not hide Actions.
local function visible(v)
    menuOpen=v
    root.Visible=v
    showOrb.Visible=not v
    badge.Visible=true
end
local function setActionsVisible(v)
    -- Go through the toggle setter so the Configs switch stays in sync.
    if type(setters.hideActions)=='function' then
        setters.hideActions(not v)
    else
        hideSideActions=not v
        settings.hideActions=not v
        actions.Visible=v
        showActionsOrb.Visible=not v
    end
end
track(close.Activated,function()visible(false)end)
track(showOrb.Activated,function()visible(true)end)
track(actionClose.Activated,function()setActionsVisible(false)end)
track(showActionsOrb.Activated,function()setActionsVisible(true)end)
track(UIS.InputBegan,function(input,processed)
    if not processed and (input.KeyCode==Enum.KeyCode.RightControl
        or input.KeyCode==Enum.KeyCode.RightShift) then visible(not menuOpen) end
end)

-- Each title-bar drag handle controls only its own window.
-- Touch and mouse both supported; tab buttons, switches and actions stay clickable.
local function makeDraggable(handle,window,onMove)
    local dragging=false
    local dragTouch=nil
    local dragStart=nil
    local initialPosition=nil
    track(handle.InputBegan,function(input)
        local inputType=input.UserInputType
        if inputType~=Enum.UserInputType.MouseButton1
            and inputType~=Enum.UserInputType.Touch then return end
        dragging=true
        dragTouch=(inputType==Enum.UserInputType.Touch) and input or nil
        dragStart=input.Position
        initialPosition=window.Position
    end)
    track(UIS.InputChanged,function(input)
        if not dragging then return end
        local inputType=input.UserInputType
        if dragTouch then
            if input~=dragTouch then return end
        elseif inputType~=Enum.UserInputType.MouseMovement then
            return
        end
        local delta=input.Position-dragStart
        local desired=UDim2.new(
            initialPosition.X.Scale,initialPosition.X.Offset+delta.X,
            initialPosition.Y.Scale,initialPosition.Y.Offset+delta.Y)
        window.Position=desired
        if onMove then onMove()end
    end)
    track(UIS.InputEnded,function(input)
        if not dragging then return end
        if dragTouch then
            if input~=dragTouch then return end
        elseif input.UserInputType~=Enum.UserInputType.MouseButton1 then
            return
        end
        dragging=false;dragTouch=nil;dragStart=nil
    end)
end
makeDraggable(headerDragRegion,root,function()rootWasDragged=true end)
makeDraggable(actionsDragRegion,actions,function()actionsWereDragged=true end)

local function initializeFloatingWindows()

--[[
    NEPTUNE FLOATING WINDOWS v1.7
    The screenshot is a layout reference only. This script does not import or
    execute SXE HUB's protected code. Every button below calls an existing,
    inspectable Neptune operation; no fabricated server-admin permissions.
]]
local floatingWindows={}
local floatingLabels={}
local ignoredInMini={}
local miniDragged={}
local miniDefaultOpen={}
local dockButtons={}
local miniReady=false
local function viewport()
    local camera=Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280,720)
end
local function floatingScale()
    local view=viewport()
    return (view.X<950 and .84 or 1)*ryWindowScale
end
local function miniRefreshDock()
    for key,button in pairs(dockButtons)do
        local item=floatingWindows[key]
        local opened=(key=='Main' and root.Visible)
            or (key=='Actions' and actions.Visible)
            or (item and item.Visible) or false
        button.BackgroundColor3=opened and COLORS.purple or COLORS.row
        button.TextColor3=opened and COLORS.text or COLORS.muted
    end
end
local function miniSetVisible(key,on)
    local window=floatingWindows[key]
    if key=='Main' then
        visible(on)
    elseif key=='Actions' then
        setActionsVisible(on)
    elseif window then
        window.Visible=on
    end
    miniRefreshDock()
end
local function miniWindow(key,caption,width,height,x,y,openDesktop)
    local view=viewport()
    local initiallyOpen=openDesktop and view.X>=1020
    local panel=make('Frame',{
        Name='Mini_'..key,AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(x,y),Size=UDim2.fromOffset(width,height),
        BackgroundColor3=COLORS.bg,BorderSizePixel=0,Visible=initiallyOpen,
        Active=true,ClipsDescendants=true,ZIndex=8
    },gui)
    corner(panel,10);border(panel,false,1.2);softFill(panel)
    local panelScale=make('UIScale',{Scale=floatingScale()},panel)
    local head=make('Frame',{Name='Title',Size=UDim2.new(1,0,0,35),
        BackgroundColor3=COLORS.card,BorderSizePixel=0,Active=true},panel)
    local dot=make('Frame',{Position=UDim2.fromOffset(10,12),
        Size=UDim2.fromOffset(10,10),BorderSizePixel=0,
        BackgroundColor3=COLORS.purple},head)
    corner(dot,10)
    local title=label(head,'NEPTUNE  /  '..caption,10,COLORS.text,true)
    title.Position=UDim2.fromOffset(25,8)
    title.Size=UDim2.new(1,-65,0,21)
    local line=make('Frame',{Position=UDim2.new(0,8,1,-2),
        Size=UDim2.new(1,-16,0,2),BorderSizePixel=0,
        BackgroundColor3=COLORS.purple},head)
    make('UIGradient',{Color=ColorSequence.new(COLORS.blue,COLORS.purple)},line)
    local closeMini=make('TextButton',{Text='×',Font=Enum.Font.GothamBold,
        TextSize=18,TextColor3=COLORS.muted,BackgroundTransparency=1,
        Position=UDim2.new(1,-29,0,5),Size=UDim2.fromOffset(24,24)
    },head)
    local miniDrag=make('TextButton',{Text='',BackgroundTransparency=1,
        Size=UDim2.new(1,-38,1,0),Active=true,AutoButtonColor=false},head)
    local body=make('ScrollingFrame',{
        Name='Contents',Position=UDim2.fromOffset(6,39),
        Size=UDim2.new(1,-12,1,-45),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=2,
        ScrollBarImageColor3=COLORS.purple,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0),ClipsDescendants=true
    },panel)
    make('UIListLayout',{Padding=UDim.new(0,5),
        SortOrder=Enum.SortOrder.LayoutOrder},body)
    make('UIPadding',{PaddingBottom=UDim.new(0,5),
        PaddingRight=UDim.new(0,4)},body)
    miniDragged[key]=false
    floatingWindows[key]=panel
    miniDefaultOpen[key]=initiallyOpen
    makeDraggable(miniDrag,panel,function()miniDragged[key]=true end)
    track(closeMini.Activated,function()miniSetVisible(key,false)end)
    local function resizeAndPlace()
        panelScale.Scale=floatingScale()
        if not miniDragged[key] then panel.Position=UDim2.fromScale(x,y) end
    end
    if Workspace.CurrentCamera then
        track(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resizeAndPlace)
    end
    return body,panel
end
local function miniText(parent,value,size,color)
    local box=make('Frame',{Size=UDim2.new(1,-2,0,25),
        BackgroundColor3=COLORS.row,BorderSizePixel=0},parent)
    corner(box,6)
    local txt=label(box,value,size or 9,color or COLORS.muted)
    txt.Position=UDim2.fromOffset(9,3)
    txt.Size=UDim2.new(1,-18,1,-6)
    return txt
end
local function miniBtn(parent,text,callback,highlight)
    local btn=plainButton(parent,text,{
        Size=UDim2.new(1,-3,0,28),BackgroundColor3=highlight and COLORS.purple or COLORS.row,
        TextColor3=COLORS.text,TextSize=9
    })
    track(btn.Activated,function()
        local ok,err=pcall(callback)
        if not ok then
            status('Window control: '..tostring(err):sub(1,65),true)
            warn('[Neptune Mini] '..tostring(err))
        end
    end)
    return btn
end
local function miniPair(parent,a,af,b,bf)
    local holder=make('Frame',{Size=UDim2.new(1,-2,0,28),
        BackgroundTransparency=1},parent)
    local left=plainButton(holder,a,{Size=UDim2.new(.5,-3,1,0),
        TextColor3=COLORS.text,TextSize=9})
    local right=plainButton(holder,b,{Position=UDim2.new(.5,3,0,0),
        Size=UDim2.new(.5,-3,1,0),TextColor3=COLORS.text,TextSize=9})
    track(left.Activated,function()local ok,err=pcall(af);if not ok then status(tostring(err),true) end end)
    track(right.Activated,function()local ok,err=pcall(bf);if not ok then status(tostring(err),true) end end)
    return left,right
end
local function toggleLocalSetting(key)
    if setters[key] then setters[key](not settings[key]) end
end

-- Left utility window: independently closable, only real local controls.
local utilityBody=miniWindow('Utility','MOVEMENT',220,211,.132,.32,true)
miniText(utilityBody,'LOCAL CONTROLS  •  synced with N menu',9,COLORS.purple)
miniPair(utilityBody,'Noclip',function()toggleLocalSetting('noclip')end,
    'Speed',function()toggleLocalSetting('speed')end)
miniPair(utilityBody,'High jump',function()toggleLocalSetting('jump')end,
    'Infinite jump',function()toggleLocalSetting('infinite')end)
miniPair(utilityBody,'Carpet Speed',function()toggleLocalSetting('ryCarpetSpeed')end,
    'Float',function()toggleLocalSetting('ryFloat')end)
miniPair(utilityBody,'Headless look',function()toggleLocalSetting('headlessLook')end,
    'No fog',function()toggleLocalSetting('noFog')end)
miniBtn(utilityBody,'SIT / STAND',function()
    local _,hum=characterParts()
    if hum then hum.Sit=not hum.Sit;status(hum.Sit and 'Sitting' or 'Standing')end
end)

-- Steal window: uses the *same* state and carpet movement code as the Stealing tab.
local stealBody=miniWindow('Steal','STEAL  •  CARPET',236,222,.848,.245,true)
local miniSlotText=miniText(stealBody,'SLOT 01 / 18',10,COLORS.purple)
miniPair(stealBody,'−  SLOT',function()setSlot(math.max(1,settings.selectedSlot-1))end,
    'SLOT  +',function()setSlot(math.min(18,settings.selectedSlot+1))end)
local miniModeBtn=miniBtn(stealBody,'MODE  •  Adaptive',function()
    local index=1
    for i,v in ipairs(modeOptions) do if v==settings.semiMode then index=i break end end
    setSemiMode(modeOptions[index%#modeOptions+1])
end)
local miniTool=miniText(stealBody,'TOOL  •  Auto',9,COLORS.muted)
miniBtn(stealBody,'START / CANCEL SEMI TP',runSemiTP,true)
miniPair(stealBody,'EQUIP TOOL',function()
    local tool=findMount(settings.mount)
    local _,hum=characterParts()
    if not tool or not hum then status('Need a flying tool',true);return end
    hum:EquipTool(tool)
    status('Equip attempted: '..tool.Name)
end,'OPEN STEAL TAB',function()visible(true);switchPage('Stealing')end)

-- Target mini-window, with real player lookups and existing spectate controls.
local targetBody=miniWindow('Target','STEAL TARGET',238,213,.848,.552,true)
local miniTargetName=miniText(targetBody,'TARGET  •  none selected',9,COLORS.purple)
local targetInput=make('TextBox',{
    Size=UDim2.new(1,-3,0,28),Text='',PlaceholderText='Search player / display name',
    TextColor3=COLORS.text,PlaceholderColor3=COLORS.muted,
    BackgroundColor3=COLORS.row,BorderSizePixel=0,
    Font=Enum.Font.Gotham,TextSize=10,ClearTextOnFocus=false
},targetBody)
corner(targetInput,7);border(targetInput,true,.8)
miniPair(targetBody,'FIND',function()pickTarget(targetInput.Text)end,
    'NEXT',function()
        local names={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=me and not ignoredInMini[p.UserId] then table.insert(names,p)end
        end
        table.sort(names,function(a,b)return a.Name<b.Name end)
        if #names==0 then status('No available players',true);return end
        local index=0
        for i,p in ipairs(names)do if p==targetPlayer then index=i;break end end
        local player=names[index%#names+1]
        pickTarget(player.Name)
        targetInput.Text=player.Name
    end)
miniPair(targetBody,'SPECTATE',function()
    if setters.spectate then setters.spectate(not settings.spectate) end
end,'CLEAR',function()
    targetInput.Text='';pickTarget('')
    if setters.spectate then setters.spectate(false)end
end)
miniBtn(targetBody,'OPEN PLAYER TAB',function()visible(true);switchPage('Player')end)

-- Admin panel means local player management, NOT game/server admin permission.
local adminBody=miniWindow('Admin','ADMIN  •  LOCAL',269,246,.134,.785,true)
local adminTabRow=make('Frame',{Size=UDim2.new(1,-2,0,28),BackgroundTransparency=1},adminBody)
local adminSections={}
local adminTabBtns={}
for idx,sectionName in ipairs({'Players','Ignore','Tools'})do
    local btn=plainButton(adminTabRow,sectionName,{
        Position=UDim2.new((idx-1)/3,(idx-1)*2,0,0),
        Size=UDim2.new(1/3,-4,1,0),TextColor3=COLORS.muted,TextSize=9
    })
    adminTabBtns[sectionName]=btn
end
local adminArea=make('Frame',{Size=UDim2.new(1,-3,0,156),
    BackgroundTransparency=1},adminBody)
local function adminSection(name)
    local page=make('ScrollingFrame',{Name=name,Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,Visible=false,
        ScrollBarThickness=3,ScrollBarImageColor3=COLORS.purple,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0)},adminArea)
    make('UIListLayout',{Padding=UDim.new(0,4),
        SortOrder=Enum.SortOrder.LayoutOrder},page)
    adminSections[name]=page
    return page
end
local playerList=adminSection('Players')
local ignorePage=adminSection('Ignore')
local toolsPage=adminSection('Tools')
local function clearRows(parent)
    for _,child in ipairs(parent:GetChildren()) do
        if child:IsA('GuiObject') then child:Destroy()end
    end
end
local function adminRefreshPlayers()
    clearRows(playerList)
    local count=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=me then
            count=count+1
            local isIgnored=ignoredInMini[p.UserId]
            miniBtn(playerList,(isIgnored and '× ' or '● ')..p.DisplayName..'  @'..p.Name,function()
                targetInput.Text=p.Name
                pickTarget(p.Name)
                status('Selected '..p.Name)
            end)
        end
    end
    if count==0 then miniText(playerList,'No other players in server')end
end
miniText(ignorePage,'LOCAL IGNORE LIST  •  menu only',9,COLORS.purple)
local ignoreInfo=miniText(ignorePage,'Ignored players: 0',9)
miniBtn(ignorePage,'IGNORE / UNIGNORE SELECTED',function()
    if not targetPlayer then status('Select a player first',true);return end
    local id=targetPlayer.UserId
    ignoredInMini[id]=not ignoredInMini[id] or nil
    adminRefreshPlayers()
    status((ignoredInMini[id] and 'Ignored ' or 'Unignored ')..targetPlayer.Name)
end)
miniBtn(ignorePage,'CLEAR IGNORE LIST',function()
    for id in pairs(ignoredInMini)do ignoredInMini[id]=nil end
    adminRefreshPlayers();status('Local ignore list cleared')
end)
miniPair(toolsPage,'RESET',function()
    local _,hum=characterParts();if hum then hum.Health=0 end
end,'REJOIN',function()TPService:Teleport(game.PlaceId,me)end)
miniBtn(toolsPage,'COPY MY COORDINATES',function()
    local _,_,r=characterParts()
    if not r then status('Character not ready',true);return end
    local pos=r.Position
    local message=string.format('%.1f, %.1f, %.1f',pos.X,pos.Y,pos.Z)
    local copier=type(setclipboard)=='function' and setclipboard or nil
    if copier then pcall(function()copier(message)end) end
    status('Coordinates: '..message)
end)
miniBtn(toolsPage,'LIST PLAYERS IN CONSOLE',function()
    for _,p in ipairs(Players:GetPlayers())do print('[Neptune Player] '..p.Name)end
    status('Player list printed to console')
end)
local function selectAdminTab(name)
    for key,page in pairs(adminSections)do
        page.Visible=key==name
        adminTabBtns[key].TextColor3=key==name and COLORS.text or COLORS.muted
        adminTabBtns[key].BackgroundColor3=key==name and COLORS.purple or COLORS.row
    end
    if name=='Players' then adminRefreshPlayers() end
end
for key,button in pairs(adminTabBtns)do
    track(button.Activated,function()selectAdminTab(key)end)
end
selectAdminTab('Players')

-- Rymogs-derived local utility controls. Each button delegates to the same
-- setting setter used by the main menu; there are no fake/unwired controls.
local ryBody=miniWindow('RyTools','RYMOGS  •  LOCAL TOOLS + TP',244,285,.49,.53,false)
miniText(ryBody,'RYMOGS FLIGHT  •  original 18 slot selector',9,COLORS.purple)
miniPair(ryBody,'USE RY TP MODE',function()
    setSemiMode('Rymogs');status('Rymogs Semi TP selected')
end,'START / CANCEL',runSemiTP)
miniPair(ryBody,'FLIGHT -40',function()
    setRyTPSpeed(settings.ryTPSpeed-40)
end,'FLIGHT +40',function()
    setRyTPSpeed(settings.ryTPSpeed+40)
end)
miniText(ryBody,'Rymogs-mode defaults: 480 speed, ping cap on',9,COLORS.muted)
miniPair(ryBody,'FPS BOOST',function()toggleLocalSetting('ryFpsBoost')end,
    'CARPET SPEED',function()toggleLocalSetting('ryCarpetSpeed')end)
miniPair(ryBody,'FLOAT PLATFORM',function()toggleLocalSetting('ryFloat')end,
    'ANTI RAGDOLL',function()toggleLocalSetting('ryAntiRagdoll')end)
miniPair(ryBody,'CARPET -20',function()
    setRyCarpetSpeed(math.max(20,settings.ryCarpetSpeedValue-20))
end,'CARPET +20',function()
    setRyCarpetSpeed(math.min(400,settings.ryCarpetSpeedValue+20))
end)
miniPair(ryBody,'UI SMALLER',function()
    setRyWindowScale(math.max(65,settings.ryWindowSize-5))
end,'UI LARGER',function()
    setRyWindowScale(math.min(125,settings.ryWindowSize+5))
end)
miniBtn(ryBody,'OPEN CONFIG / WINDOW SETTINGS',function()
    miniSetVisible('Main',true);switchPage('Configs')
end)

-- Screenshot-like cooldown/status window, but only shows metrics this script
-- can actually verify. Game-specific ability timers are not fabricated.
local monitorBody=miniWindow('Status','LIVE STATUS',215,198,.85,.843,true)
local stateRow=miniText(monitorBody,'SEMI TP  •  READY',10,COLORS.green)
local slotRow=miniText(monitorBody,'SELECTED SLOT  •  01',9)
local monitorPerf=miniText(monitorBody,'FPS --  /  PING --',9,COLORS.purple)
local monitorText=miniText(monitorBody,'WAITING FOR A ROUTE',9)
miniBtn(monitorBody,'CANCEL SEMI TP',function()
    if tpActive then tpCancel=true;status('Cancelling...')
    else status('Semi TP is not running') end
end)

-- Persistent launcher in a floating dock: closing any mini window does not
-- destroy it, and every panel can be reopened without rerunning the script.
local dock=make('Frame',{Name='WindowDock',AnchorPoint=Vector2.new(.5,1),
    Position=UDim2.new(.5,0,1,-10),Size=UDim2.fromOffset(585,40),
    BackgroundColor3=COLORS.bg,BorderSizePixel=0,Visible=true,ZIndex=18},gui)
corner(dock,10);border(dock,false,1.2);softFill(dock)
local dockScale=make('UIScale',{Scale=math.min(1,(viewport().X-20)/585)},dock)
make('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),
    VerticalAlignment=Enum.VerticalAlignment.Center},dock)
make('UIPadding',{PaddingLeft=UDim.new(0,7)},dock)
for idx,entry in ipairs({
    {'Main','N'}, {'Steal','STEAL'}, {'Target','TARGET'}, {'Admin','ADMIN'},
    {'Utility','MOVE'}, {'RyTools','RY TOOLS'}, {'Actions','ACTIONS'}, {'Status','STATUS'}
}) do
    local key,txt=entry[1],entry[2]
    local wd=(key=='Main') and 33 or (key=='Target') and 73 or
        (key=='Actions') and 74 or (key=='RyTools') and 72 or (key=='Status') and 68 or
        (key=='Steal') and 65 or (key=='Utility') and 62 or 65
    local b=plainButton(dock,txt,{
        Size=UDim2.fromOffset(wd,28),LayoutOrder=idx,
        TextSize=8,BackgroundColor3=COLORS.row
    })
    dockButtons[key]=b
    track(b.Activated,function()
        local isVisible
        if key=='Main' then isVisible=root.Visible
        elseif key=='Actions' then isVisible=actions.Visible
        else isVisible=floatingWindows[key] and floatingWindows[key].Visible end
        miniSetVisible(key,not isVisible)
    end)
end
local function refreshMiniStatus()
    miniSlotText.Text=string.format('SLOT  %02d / 18',settings.selectedSlot)
    miniModeBtn.Text='MODE  •  '..tostring(settings.semiMode)
    miniTool.Text='TOOL  •  '..tostring(settings.mount)
    miniTargetName.Text=targetPlayer and ('TARGET  •  @'..targetPlayer.Name)
        or 'TARGET  •  nearest occupied base'
    slotRow.Text=string.format('SELECTED SLOT  •  %02d',settings.selectedSlot)
    stateRow.Text=tpActive and 'SEMI TP  •  MOVING' or 'SEMI TP  •  READY'
    stateRow.TextColor3=tpActive and COLORS.purple or COLORS.green
    monitorPerf.Text=fpsText.Text..'   /   '..pingText.Text
    monitorText.Text=tostring(lastTpStatus):sub(1,37)
    local ignoredCount=0
    for _ in pairs(ignoredInMini)do ignoredCount=ignoredCount+1 end
    ignoreInfo.Text='Ignored players: '..ignoredCount
    miniRefreshDock()
end
miniRefreshDock()
local miniSeconds=0
track(Run.Heartbeat,function(dt)
    if stopped then return end
    miniSeconds=miniSeconds+dt
    if miniSeconds<.6 then return end
    miniSeconds=0
    refreshMiniStatus()
end)
track(Players.PlayerAdded,adminRefreshPlayers)
track(Players.PlayerRemoving,function()task.defer(adminRefreshPlayers)end)
track(UIS.InputBegan,function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.RightAlt then
        dock.Visible=not dock.Visible
    end
end)
miniReady=true


env.NeptuneMiniWindowControls={show=function(name)miniSetVisible(name,true)end,hide=function(name)miniSetVisible(name,false)end}
end
initializeFloatingWindows()
track(UIS.InputBegan,function(input,processed)
    if processed or not settings.ryHotkeys or UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.Q and setters.ryCarpetSpeed then
        setters.ryCarpetSpeed(not settings.ryCarpetSpeed)
    elseif input.KeyCode==Enum.KeyCode.B and setters.ryFloat then
        setters.ryFloat(not settings.ryFloat)
    elseif input.KeyCode==Enum.KeyCode.H and setters.speed then
        setters.speed(not settings.speed)
    elseif input.KeyCode==Enum.KeyCode.T then
        runSemiTP()
    end
end)
track(me.CharacterAdded,function()
    oldHumanoid=nil;tpCancel=true;noclipOriginal=setmetatable({}, {__mode='k'})
    task.wait(.5)
    if not stopped then applyMovement();if spectating then updateSpectate() end
        if settings.headlessLook then pcall(setHeadlessLook,true) end
    end
end)
track(Players.PlayerRemoving,function(p)
    if p==targetPlayer then targetPlayer=nil;updateTargetDisplay();refreshSelectedHighlight();cameraNormal() end
    task.defer(refreshESP)
end)
track(Players.PlayerAdded,function(p)
    track(p.CharacterAdded,function()
        task.wait(.2);if not stopped then refreshESP();refreshSelectedHighlight()end
    end)
    task.defer(refreshESP)
end)
for _,p in ipairs(Players:GetPlayers()) do
    if p~=me then
        track(p.CharacterAdded,function()
            task.wait(.2);if not stopped then refreshESP();refreshSelectedHighlight()end
        end)
    end
end
-- Real-time display: FPS measured from rendered frames; ping from Roblox network metrics.
-- If one metric is not exposed, display "--" rather than a fabricated 0 ms.
local Stats=game:GetService('Stats')
local function readPingMilliseconds()
    local ok,value=pcall(function()return me:GetNetworkPing()end)
    if ok and type(value)=='number' and value>=0 and value<60 then
        return math.floor(value*1000+0.5)
    end
    local okStats,statsValue=pcall(function()
        local network=Stats:FindFirstChild('Network')
        local serverStats=network and network:FindFirstChild('ServerStatsItem')
        local dataPing=serverStats and serverStats:FindFirstChild('Data Ping')
        if not dataPing then return nil end
        local okNum,n=pcall(function()return dataPing:GetValue()end)
        if okNum and type(n)=='number' then return n end
        local readout=dataPing:GetValueString()
        return tonumber((readout or ''):match('[%d%.]+'))
    end)
    if okStats and type(statsValue)=='number' and statsValue>=0 then
        return math.floor(statsValue+0.5)
    end
    return nil
end
local frameCount,frameSeconds=0,0
track(Run.RenderStepped,function(dt)
    if stopped then return end
    if type(dt)~='number' or dt<=0 then return end
    frameCount=frameCount+1
    frameSeconds=frameSeconds+dt
    if frameSeconds>=.65 then
        local fps=math.floor(frameCount/frameSeconds+0.5)
        fpsText.Text='FPS  '..tostring(fps)
        fpsText.TextColor3=fps>=45 and COLORS.cyan or (fps>=25 and COLORS.green or COLORS.red)
        local ping=readPingMilliseconds()
        pingText.Text=ping and (tostring(ping)..' ms') or '-- ms'
        pingText.TextColor3=not ping and COLORS.muted
            or (ping<120 and COLORS.purple or (ping<250 and COLORS.cyan or COLORS.red))
        frameCount=0
        frameSeconds=0
    end
end)
local _distanceTimer=0
track(Run.Heartbeat,function(dt)
    if stopped then return end
    _distanceTimer=_distanceTimer+dt
    if _distanceTimer<.5 then return end
    _distanceTimer=0
    if settings.distanceTags then updateDistanceTags() end
    if targetPlayer then
        local _,_,mine=characterParts()
        local theirs=targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')
        if mine and theirs then
            targetDistanceText.Text='Target distance: '..math.floor((mine.Position-theirs.Position).Magnitude+.5)..' studs'
        else targetDistanceText.Text='Target distance: unavailable' end
    else targetDistanceText.Text='Target distance: --' end
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
    cameraNormal();clearESP();clearDistanceTags();settings.noclip=false;pcall(updateNoclip)
    settings.lowGraphics=false;pcall(function()setLowGraphics(false)end)
    pcall(ryPlus.stop)
    settings.targetHighlight=false;pcall(refreshSelectedHighlight);pcall(function()setFullbright(false)end)
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
status('Neptune v1.9  •  Rymogs-style Semi TP available')
gui.Enabled=true
root.Visible=true
print('[Neptune v1.9] Added Rymogs-style flight from readable source; game-specific autosteal/clone remains separate.')

-- User-accessible local menu state. No protected Headless code is executed.
env.NeptuneNMenu = {version='1.9',show=function()visible(true);gui.Enabled=true end,hide=function()visible(false)end,features={'Adaptive Semi TP','Slot Selector','Mount Picker','Player ESP','Base ESP','Podium ESP','Speed','Jump','Spectate','Fullbright','FOV','Headless Look','No Fog','Noclip','Target Highlight','Low Graphics','Equip Carpet','Sit/Stand','Player Coordinates','Profiles','Portable Config Import/Export','Distance Tags','Target Distance','Crosshair','Recenter Windows','Draggable Mini Windows','Close/Reopen Windows','Local Admin Player List','Floating Steal Controls','Live Status','Rymogs FPS Boost','Rymogs Carpet Speed','Float Platform','Anti Ragdoll','UI Size','Keyboard Hotkeys','Rymogs Mini Window','Rymogs-style Semi TP','Rymogs Waypoint Smoothing','Ping-aware Speed','Lagback Recovery'},getStatus=function()return lastTpStatus end,showWindow=function(name)if env.NeptuneMiniWindowControls then env.NeptuneMiniWindowControls.show(name)end end,hideWindow=function(name)if env.NeptuneMiniWindowControls then env.NeptuneMiniWindowControls.hide(name)end end,stop=stopHub}

end,function(err)
    local detail=tostring(err)
    warn('[Neptune N] Startup failed: '..detail)
    return detail
end)
if ok then
    if notice then pcall(function()notice:Destroy()end)end
else
    if noticeText then
        noticeText.Text='NEPTUNE N COULD NOT START\n'..tostring(result):sub(1,180)
        noticeText.TextColor3=Color3.fromRGB(255,130,170)
    end
end

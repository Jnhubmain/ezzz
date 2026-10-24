-- Neptune Compact / Aurora-inspired UI
-- Client-side interface with selectable target podium slot. Reinjecting closes the previous copy.
-- Uses ordinary Roblox APIs; executor compatibility varies and is not guaranteed.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local me=Players.LocalPlayer or Players.PlayerAdded:Wait()
local environment=_G
pcall(function() if type(getgenv)=='function' then environment=getgenv() end end)
if type(environment.NeptuneCompactStop)=='function' then pcall(environment.NeptuneCompactStop) end
local connections,highlights={},{}
local function connect(signal,callback)
    local c=signal:Connect(callback);table.insert(connections,c);return c
end
local C={bg=Color3.fromRGB(21,22,27),surface=Color3.fromRGB(29,30,37),row=Color3.fromRGB(33,34,42),purple=Color3.fromRGB(155,85,255),orange=Color3.fromRGB(255,93,18),text=Color3.fromRGB(229,230,239),muted=Color3.fromRGB(146,148,162),off=Color3.fromRGB(62,65,77)}
local function make(class,props,parent)
    local object=Instance.new(class)
    for k,v in pairs(props or {}) do object[k]=v end
    object.Parent=parent
    return object
end
local function round(item,n) make('UICorner',{CornerRadius=UDim.new(0,n or 7)},item)end
local function outline(item,col,thickness)
    return make('UIStroke',{Color=col or C.purple,Thickness=thickness or 1,Transparency=.04},item)
end
local function text(parent,string,size,bold,color)
    return make('TextLabel',{BackgroundTransparency=1,Text=string,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=size or 11,TextColor3=color or C.text,TextXAlignment=Enum.TextXAlignment.Left},parent)
end
local guiParent=me:WaitForChild('PlayerGui')
pcall(function() if type(gethui)=='function' then local obj=gethui();if typeof(obj)=='Instance' then guiParent=obj end end end)
for _,p in ipairs({guiParent,me:FindFirstChild('PlayerGui')}) do
    if p then local existing=p:FindFirstChild('NeptuneCompactAurora');if existing then existing:Destroy()end end
end
local gui=make('ScreenGui',{Name='NeptuneCompactAurora',ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},guiParent)
local root=make('Frame',{Name='Hub',Size=UDim2.fromOffset(365,384),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.48),BackgroundColor3=C.bg,BorderSizePixel=0,Active=true,ClipsDescendants=true},gui)
round(root,13);outline(root,C.purple,1.3)
local rootStroke=make('UIGradient',{Color=ColorSequence.new(C.orange,C.purple),Rotation=15},root:FindFirstChildOfClass('UIStroke'))
local uiScale=make('UIScale',{Scale=1},root)
local function rescale()
    local cam=workspace.CurrentCamera
    local size=cam and cam.ViewportSize or Vector2.new(1280,720)
    uiScale.Scale=math.min(1,(size.X-20)/365,(size.Y-30)/384)
end
rescale();if workspace.CurrentCamera then connect(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),rescale) end
local title=text(root,'NEPTUNE',14,true,C.orange)
title.Position=UDim2.fromOffset(14,9);title.Size=UDim2.fromOffset(190,28)
local version=text(root,'COMPACT',9,true,C.muted)
version.Position=UDim2.fromOffset(15,31);version.Size=UDim2.fromOffset(95,13)
local minimize=make('TextButton',{Position=UDim2.fromOffset(305,10),Size=UDim2.fromOffset(23,25),Text='–',TextColor3=C.muted,TextSize=19,Font=Enum.Font.GothamBold,BackgroundTransparency=1},root)
local close=make('TextButton',{Position=UDim2.fromOffset(334,10),Size=UDim2.fromOffset(23,25),Text='×',TextColor3=C.muted,TextSize=19,Font=Enum.Font.GothamBold,BackgroundTransparency=1},root)
local nav=make('Frame',{BackgroundTransparency=1,Position=UDim2.fromOffset(12,51),Size=UDim2.fromOffset(341,29)},root)
make('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},nav)
local pageNames={'Stealing','Player','Visuals','Admin','Misc','Configs'}
local pages,buttons={},{}
local body=make('Frame',{Position=UDim2.fromOffset(11,89),Size=UDim2.fromOffset(343,283),BackgroundTransparency=1},root)
for i,name in ipairs(pageNames) do
    local btn=make('TextButton',{Size=UDim2.fromOffset(i==1 and 58 or i==6 and 53 or 54,27),LayoutOrder=i,BackgroundTransparency=1,Text=name,TextColor3=C.muted,TextSize=10,Font=Enum.Font.Gotham,AutoButtonColor=false},nav)
    local under=make('Frame',{Name='Underline',Visible=false,Position=UDim2.new(0,5,1,-2),Size=UDim2.new(1,-10,0,2),BackgroundColor3=C.orange,BorderSizePixel=0},btn)
    buttons[name]=btn
    local pg=make('ScrollingFrame',{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.purple,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ScrollingDirection=Enum.ScrollingDirection.Y},body)
    make('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,7)},pg)
    make('UIPadding',{PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,8)},pg)
    pages[name]=pg
end
local function showPage(name)
    for id,p in pairs(pages) do p.Visible=(id==name) end
    for id,b in pairs(buttons) do b.TextColor3=id==name and C.text or C.muted;b.Underline.Visible=(id==name) end
end
for _,name in ipairs(pageNames) do connect(buttons[name].Activated,function()showPage(name)end)end
local function group(page,heading)
    local container=make('Frame',{Size=UDim2.new(1,-2,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.surface,BorderSizePixel=0},pages[page])
    round(container,9);outline(container,C.purple)
    make('UIPadding',{PaddingTop=UDim.new(0,27),PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,9)},container)
    make('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},container)
    local caption=text(container,heading:upper(),10,true,C.orange)
    caption.Position=UDim2.fromOffset(10,5);caption.Size=UDim2.new(1,-20,0,18)
    caption.ZIndex=2;caption.LayoutOrder=-100
    -- Layout treats section caption as a normal row; remove top padding duplication.
    container:FindFirstChildOfClass('UIPadding').PaddingTop=UDim.new(0,8)
    return container
end
local function row(parent,label,order)
    local frame=make('Frame',{LayoutOrder=order or 1,Size=UDim2.new(1,0,0,35),BackgroundColor3=C.row,BorderSizePixel=0},parent)
    round(frame,7);outline(frame,C.purple,.8)
    local t=text(frame,label,11,false,C.text);t.Position=UDim2.fromOffset(9,0);t.Size=UDim2.new(1,-85,1,0)
    return frame
end
local function toggle(parent,label,callback)
    local frame=row(parent,label)
    local switch=make('TextButton',{Size=UDim2.fromOffset(42,21),Position=UDim2.new(1,-49,.5,-10),BackgroundColor3=C.off,Text='',AutoButtonColor=false},frame)
    round(switch,12)
    local knob=make('Frame',{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(3,2),BackgroundColor3=C.text,BorderSizePixel=0},switch);round(knob,9)
    local enabled=false
    local function set(v)
        enabled=v
        switch.BackgroundColor3=v and C.orange or C.off
        knob.Position=v and UDim2.fromOffset(23,2) or UDim2.fromOffset(3,2)
        local ok,err=pcall(callback,v)
        if not ok then warn('Neptune '..label..': '..tostring(err)) end
    end
    connect(switch.Activated,function()set(not enabled)end)
    return set
end
local function button(parent,label,callback)
    local frame=row(parent,label)
    local b=make('TextButton',{Size=UDim2.fromOffset(68,24),Position=UDim2.new(1,-74,.5,-12),BackgroundColor3=C.bg,Text='RUN',TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.orange},frame)
    round(b,6);outline(b,C.orange,.8)
    connect(b.Activated,callback)
    return b
end
local function note(parent,message)
    local frame=make('Frame',{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.row,BorderSizePixel=0},parent);round(frame,7)
    local l=text(frame,message,10,false,C.muted);l.TextWrapped=true;l.Position=UDim2.fromOffset(9,4);l.Size=UDim2.new(1,-18,1,-8)
end
local movement={speed=false,jump=false,infinite=false}
local oldHumanoid,oldSpeed,oldJump,oldJumpMode
local function currentHumanoid()
    local ch=me.Character
    return ch and ch:FindFirstChildOfClass('Humanoid')
end
local function applyMovement()
    local h=currentHumanoid();if not h then return end
    if h~=oldHumanoid then oldHumanoid=h;oldSpeed=h.WalkSpeed;oldJump=h.JumpPower;oldJumpMode=h.UseJumpPower end
    h.WalkSpeed=movement.speed and 24 or oldSpeed
    h.UseJumpPower=movement.jump and true or oldJumpMode
    h.JumpPower=movement.jump and 75 or oldJump
end
local g=group('Player','Movement')
toggle(g,'Speed (24)',function(v)movement.speed=v;applyMovement()end)
toggle(g,'High Jump (75)',function(v)movement.jump=v;applyMovement()end)
connect(UIS.JumpRequest,function()
    if movement.infinite then local h=currentHumanoid();if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end end
end)
toggle(g,'Infinite Jump',function(v)movement.infinite=v end)
local playerTarget=nil;local spectate=false
local function restoreCamera()
    spectate=false
    local h=currentHumanoid();if h and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject=h end
end
local function updateCamera()
    if spectate and playerTarget and workspace.CurrentCamera then
        local target=playerTarget.Character and playerTarget.Character:FindFirstChildOfClass('Humanoid')
        if target then workspace.CurrentCamera.CameraSubject=target end
    end
end
local gp=group('Player','Spectator')
local picker=button(gp,'Select next player',function()
    local options={};for _,p in ipairs(Players:GetPlayers())do if p~=me then table.insert(options,p)end end
    if #options==0 then playerTarget=nil;return end
    local index=table.find(options,playerTarget) or 0
    playerTarget=options[index%#options+1]
    picker.Text=string.sub(playerTarget.Name,1,10)
    updateCamera()
end)
toggle(gp,'Spectate selected',function(v)spectate=v;if v then updateCamera()else restoreCamera()end end)
button(gp,'Restore camera',restoreCamera)
local gv=group('Visuals','ESP')
local visualOn=false
local function clearHighlights()for p,h in pairs(highlights) do if h then pcall(function()h:Destroy()end)end;highlights[p]=nil end end
local function refreshHighlights()
    clearHighlights();if not visualOn then return end
    for _,p in ipairs(Players:GetPlayers())do
        if p~=me and p.Character then
            local h=make('Highlight',{Name='NeptuneHighlight',FillColor=C.purple,OutlineColor=C.orange,FillTransparency=.84,OutlineTransparency=.1,DepthMode=Enum.HighlightDepthMode.Occluded},p.Character)
            highlights[p]=h
        end
    end
end
toggle(gv,'Player Highlights',function(v)visualOn=v;refreshHighlights()end)
button(gv,'Refresh Highlights',refreshHighlights)
local gm=group('Misc','Actions')
button(gm,'Reset character',function()local h=currentHumanoid();if h then h.Health=0 end end)
button(gm,'Rejoin game',function()
    local service=game:GetService('TeleportService')
    pcall(function()service:Teleport(game.PlaceId,me)end)
end)
local ga=group('Admin','Information')
note(ga,'Game-specific admin or defense features from the original script have not been recreated. This compact build contains only implemented controls.')
local gs=group('Stealing','Information')
note(gs,'Select a player on the Player tab, choose slot 1–18 below, then press Semi TP once. The target base must expose the chosen slot.')
local tpInProgress=false
local tpStatusLabel
local function tpStatus(message)
    if tpStatusLabel and tpStatusLabel.Parent then tpStatusLabel.Text='Status: '..message end
end
local function getRoot()
    local character=me.Character
    return character and character:FindFirstChild('HumanoidRootPart')
end
-- Resolve the selected numbered podium in the selected player's base.
-- This uses visible Workspace plot/podium objects and does not invent coordinates.
local selectedSlot=1
local function getSlotDestination()
    if not playerTarget then return nil,'Select a player on Player tab' end
    local plots=workspace:FindFirstChild('Plots')
    if not plots then return nil,'Plots folder not found' end
    local wantedName=playerTarget.Name:lower()
    local displayName=playerTarget.DisplayName:lower()
    local targetPlot
    for _,plot in ipairs(plots:GetChildren()) do
        local sign=plot:FindFirstChild('PlotSign')
        local surface=sign and sign:FindFirstChild('SurfaceGui')
        local frame=surface and surface:FindFirstChild('Frame')
        local label=frame and frame:FindFirstChild('TextLabel')
        local ownerText=label and label.Text:lower() or ''
        local rawOwner=ownerText:match('^(.-)\'s base$')
        if rawOwner and (rawOwner==wantedName or rawOwner==displayName) then
            targetPlot=plot
            break
        end
    end
    if not targetPlot then return nil,'Selected player base not found' end
    local podiums=targetPlot:FindFirstChild('AnimalPodiums')
    if not podiums then return nil,'Base has no AnimalPodiums' end
    local podium=podiums:FindFirstChild(tostring(selectedSlot))
    if not podium then return nil,'Slot '..selectedSlot..' not found' end
    local part
    if podium:IsA('BasePart') then
        part=podium
    else
        local claim=podium:FindFirstChild('Claim')
        part=claim and claim:FindFirstChild('Main')
        if part and not part:IsA('BasePart') then part=nil end
        part=part or podium:FindFirstChildWhichIsA('BasePart',true)
    end
    if not part then return nil,'Slot has no position' end
    return CFrame.new(part.Position+Vector3.new(0,4,0)),nil
end
local function safePivot(destination)
    local character=me.Character
    local root=getRoot()
    if not character or not root then tpStatus('Character not ready');return false end
    if typeof(destination)~='CFrame' then tpStatus('Invalid destination');return false end
    local ok,err=pcall(function()
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        character:PivotTo(destination)
    end)
    if not ok then tpStatus('Movement blocked: '..tostring(err):sub(1,45)) end
    return ok
end
local semiGroup=group('Stealing','Semi Teleport')
local tpInfo=row(semiGroup,'Slot: 1 / 18')
local slotLabel=tpInfo:FindFirstChildOfClass('TextLabel')
slotLabel.Size=UDim2.new(1,-102,1,0)
local previousSlot=make('TextButton',{Size=UDim2.fromOffset(40,25),Position=UDim2.new(1,-91,.5,-12),BackgroundColor3=C.bg,Text='<',TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.orange},tpInfo)
local nextSlot=make('TextButton',{Size=UDim2.fromOffset(40,25),Position=UDim2.new(1,-46,.5,-12),BackgroundColor3=C.bg,Text='>',TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.orange},tpInfo)
round(previousSlot,6);round(nextSlot,6)
outline(previousSlot,C.orange,.8);outline(nextSlot,C.orange,.8)
local function chooseSlot(offset)
    selectedSlot=((selectedSlot-1+offset)%18)+1
    slotLabel.Text='Slot: '..selectedSlot..' / 18'
    tpStatus('Selected slot '..selectedSlot)
end
connect(previousSlot.Activated,function()chooseSlot(-1)end)
connect(nextSlot.Activated,function()chooseSlot(1)end)
tpStatusLabel=text(semiGroup,'Status: Ready',10,false,C.muted)
tpStatusLabel.Size=UDim2.new(1,0,0,24)
button(semiGroup,'Semi TP',function()
    if tpInProgress then tpStatus('Semi TP is already running');return end
    local rootPart=getRoot()
    if not rootPart then tpStatus('Your character is not ready');return end
    local destination,err=getSlotDestination()
    if not destination then tpStatus(err);return end
    tpInProgress=true
    local startCFrame=rootPart.CFrame
    local halfway=startCFrame.Position:Lerp(destination.Position,0.5)
    tpStatus('Moving to slot '..selectedSlot..' (step 1/2)')
    task.spawn(function()
        local success=safePivot(CFrame.new(halfway)*startCFrame.Rotation)
        if success then
            task.wait(0.2)
            if not getRoot() then
                tpStatus('Character changed; cancelled')
            else
                tpStatus('Moving to slot '..selectedSlot..' (step 2/2)')
                if safePivot(destination) then tpStatus('Reached slot '..selectedSlot) end
            end
        end
        tpInProgress=false
    end)
end)

local config=group('Configs','Interface')
local uiVisible=true
local floating=make('TextButton',{Name='OpenHub',Size=UDim2.fromOffset(44,44),Position=UDim2.fromOffset(15,180),BackgroundColor3=C.bg,Text='N',TextSize=18,Font=Enum.Font.GothamBold,TextColor3=C.orange,Visible=false,Active=true},gui)
round(floating,12);outline(floating,C.purple)
local function setVisible(v)uiVisible=v;root.Visible=v;floating.Visible=not v end
button(config,'Hide menu',function()setVisible(false)end)
note(config,'RightShift toggles the window on desktop. Use the floating N button on mobile. Drag the header to move the window.')
connect(close.Activated,function()setVisible(false)end)
connect(minimize.Activated,function()setVisible(false)end)
connect(floating.Activated,function()setVisible(true)end)
connect(UIS.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then setVisible(not uiVisible)end
end)
local dragging,dragStart,startPos,touchPointer=false,nil,nil,nil
local function beginDrag(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true;touchPointer=input;dragStart=input.Position;startPos=root.Position
    end
end
connect(title.InputBegan,beginDrag)
local dragRegion=make('Frame',{Position=UDim2.fromOffset(103,2),Size=UDim2.fromOffset(196,44),BackgroundTransparency=1,Active=true},root)
connect(dragRegion.InputBegan,beginDrag)
connect(UIS.InputChanged,function(input)
    if not dragging then return end
    if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
    if touchPointer and touchPointer.UserInputType==Enum.UserInputType.Touch and input~=touchPointer then return end
    local delta=(input.Position-dragStart)/uiScale.Scale
    root.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
end)
connect(UIS.InputEnded,function(input)
    if input==touchPointer or (touchPointer and touchPointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)then dragging=false;touchPointer=nil end
end)
connect(me.CharacterAdded,function()oldHumanoid=nil;tpOrigin=nil;tpDestination=nil;tpInProgress=false;tpStatus('Respawned — reset');task.wait(.25);applyMovement();if spectate then updateCamera()end end)
connect(Players.PlayerAdded,function(p)
    connect(p.CharacterAdded,function()task.wait(.3);if visualOn then refreshHighlights()end end)
end)
connect(Players.PlayerRemoving,function(p)
    if p==playerTarget then playerTarget=nil;restoreCamera();picker.Text='RUN' end
    if visualOn then task.defer(refreshHighlights)end
end)
for _,p in ipairs(Players:GetPlayers())do
    if p~=me then connect(p.CharacterAdded,function()task.wait(.3);if visualOn then refreshHighlights()end end)end
end
local stopped=false
environment.NeptuneCompactStop=function()
    if stopped then return end;stopped=true
    restoreCamera();movement.speed=false;movement.jump=false;movement.infinite=false;pcall(applyMovement)
    clearHighlights()
    for _,c in ipairs(connections)do pcall(function()c:Disconnect()end)end
    pcall(function()gui:Destroy()end)
end
showPage('Player')
print('Neptune Compact loaded. RightShift / N button to toggle.')

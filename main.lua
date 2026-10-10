-- [[ Da Hood | main.lua ]]

local cfg  = getgenv()['DaHood'] or {}
local ESP  = cfg.ESP      or {}
local AIM  = cfg.Aimbot   or {}
local MOV  = cfg.Movement or {}
local MISC = cfg.Misc     or {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Camera     = WS.CurrentCamera

-- ── ESP ──────────────────────────────────────
if ESP.Enabled then
    local function makeESP(player)
        if player == LP then return end
        local box  = ESP.Box       and Drawing.new("Square") or nil
        local lbl  = ESP.Name      and Drawing.new("Text")   or nil
        local dtxt = ESP.Distance  and Drawing.new("Text")   or nil
        local hbar = ESP.HealthBar and Drawing.new("Square") or nil
        if box  then box.Thickness=1;box.Filled=false;box.Color=ESP.Color or Color3.new(0,0.91,0.47);box.Visible=false end
        if lbl  then lbl.Size=13;lbl.Center=true;lbl.Color=Color3.new(1,1,1);lbl.Outline=true;lbl.Visible=false end
        if dtxt then dtxt.Size=11;dtxt.Center=true;dtxt.Color=Color3.new(.6,.6,.6);dtxt.Outline=true;dtxt.Visible=false end
        if hbar then hbar.Thickness=1;hbar.Filled=true;hbar.Visible=false end
        local function hide()
            if box  then box.Visible=false  end
            if lbl  then lbl.Visible=false  end
            if dtxt then dtxt.Visible=false end
            if hbar then hbar.Visible=false end
        end
        RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then hide(); return end
            if ESP.TeamCheck and player.Team == LP.Team then hide(); return end
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local d = (hrp.Position - Camera.CFrame.Position).Magnitude
            if not onScreen or d > (ESP.MaxDistance or 500) then hide(); return end
            local scale = 1/(pos.Z*math.tan(math.rad(Camera.FieldOfView/2))*2/Camera.ViewportSize.Y)
            local w, h = scale*3.5, scale*6
            if box  then box.Size=Vector2.new(w,h);box.Position=Vector2.new(pos.X-w/2,pos.Y-h/2);box.Visible=true end
            if lbl  then lbl.Text=player.DisplayName;lbl.Position=Vector2.new(pos.X,pos.Y-h/2-14);lbl.Visible=true end
            if dtxt then dtxt.Text=math.floor(d).."m";dtxt.Position=Vector2.new(pos.X,pos.Y+h/2+3);dtxt.Visible=true end
            if hbar then
                local hp=hum.Health/hum.MaxHealth
                hbar.Size=Vector2.new(4,h*hp);hbar.Position=Vector2.new(pos.X-w/2-7,pos.Y-h/2)
                hbar.Color=Color3.new(1-hp,hp,0);hbar.Visible=true
            end
        end)
        player.CharacterRemoving:Connect(hide)
    end
    for _,p in Players:GetPlayers() do makeESP(p) end
    Players.PlayerAdded:Connect(makeESP)
end

-- ── AIMBOT ───────────────────────────────────
if AIM.Enabled then
    if AIM.FOVCircle then
        local c=Drawing.new("Circle")
        c.Radius=AIM.FOV or 120;c.Thickness=1
        c.Color=Color3.new(1,1,1);c.Filled=false;c.Visible=true
        RunService.RenderStepped:Connect(function()
            c.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        end)
    end
    local function getTarget()
        local best,bestDist=nil,AIM.FOV or 120
        local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        for _,p in Players:GetPlayers() do
            if p==LP then continue end
            if AIM.TeamCheck and p.Team==LP.Team then continue end
            local char=p.Character
            local part=char and char:FindFirstChild(AIM.TargetPart or "Head")
            if not part then continue end
            if AIM.VisibleCheck then
                local res=WS:Raycast(Camera.CFrame.Position,(part.Position-Camera.CFrame.Position).Unit*1000,RaycastParams.new())
                if not res or not res.Instance or not res.Instance:IsDescendantOf(char) then continue end
            end
            local pos,onScreen=Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
            if d<bestDist then bestDist=d;best=part end
        end
        return best
    end
    if AIM.SilentAim then
        local mt=getrawmetatable(game);local old=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            if getnamecallmethod()=="FireServer" then
                local args={...};local target=getTarget()
                if target then
                    for i,v in ipairs(args) do
                        if typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=target;break end
                    end
                end
                return old(self,table.unpack(args))
            end
            return old(self,...)
        end)
        setreadonly(mt,true)
    else
        local AIM_KEY=Enum.KeyCode[("Key"..(AIM.HoldKey or "Q"))] or Enum.KeyCode.KeyQ
        RunService.RenderStepped:Connect(function()
            if not UIS:IsKeyDown(AIM_KEY) then return end
            local target=getTarget();if not target then return end
            local pos=Camera:WorldToViewportPoint(target.Position)
            local smooth=math.max(AIM.Smoothing or 10,1)
            local cx,cy=Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2
            mousemoverel((pos.X-cx)/smooth,(pos.Y-cy)/smooth)
        end)
    end
end

-- ── MOVEMENT ─────────────────────────────────
local function onCharSpawn(char)
    local hum=char:WaitForChild("Humanoid",10)
    if not hum then return end
    if MISC.GodMode then
        hum.BreakJointsOnDeath=false
        hum.Died:Connect(function() hum.Health=hum.MaxHealth end)
    end
end
LP.CharacterAdded:Connect(onCharSpawn)
if LP.Character then onCharSpawn(LP.Character) end

if MOV.SpeedHack then
    local SPD_KEY=Enum.KeyCode[("Key"..(MOV.SpeedKey or "E"))] or Enum.KeyCode.KeyE
    RunService.Heartbeat:Connect(function()
        local c=LP.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        h.WalkSpeed=UIS:IsKeyDown(SPD_KEY) and (MOV.WalkSpeed or 60) or 16
    end)
end

if MOV.InfJump then
    UIS.JumpRequest:Connect(function()
        local c=LP.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

if MOV.InfStamina then
    RunService.Heartbeat:Connect(function()
        local c=LP.Character;if not c then return end
        for _,v in c:GetDescendants() do
            if (v.Name=="Stamina" or v.Name=="Sprint" or v.Name=="Energy") and v:IsA("NumberValue") then
                v.Value=100
            end
        end
    end)
end

if MOV.NoClip then
    RunService.Stepped:Connect(function()
        local c=LP.Character;if not c then return end
        for _,p in c:GetDescendants() do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end

if MOV.Fly then
    local flying=false;local bv,bg
    UIS.InputBegan:Connect(function(i,gp)
        if gp or i.KeyCode~=Enum.KeyCode.H then return end
        flying=not flying
        local c=LP.Character;local hrp=c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then flying=false;return end
        local hum=c:FindFirstChildOfClass("Humanoid")
        if flying then
            if hum then hum.PlatformStand=true end
            bv=Instance.new("BodyVelocity",hrp);bv.Velocity=Vector3.zero;bv.MaxForce=Vector3.new(1e5,1e5,1e5)
            bg=Instance.new("BodyGyro",hrp);bg.MaxTorque=Vector3.new(1e5,1e5,1e5);bg.P=1e4
        else
            if bv then bv:Destroy();bv=nil end
            if bg then bg:Destroy();bg=nil end
            if hum then hum.PlatformStand=false end
        end
    end)
    RunService.Heartbeat:Connect(function()
        if not flying or not bv then return end
        local c=LP.Character;local hrp=c and c:FindFirstChild("HumanoidRootPart");if not hrp then return end
        local speed=MOV.FlySpeed or 80;local cf=Camera.CFrame;local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        bv.Velocity=dir.Magnitude>0 and dir.Unit*speed or Vector3.zero;bg.CFrame=cf
    end)
end

-- ── MISC ─────────────────────────────────────
if MISC.NoRecoil then
    local mt=getrawmetatable(game);local old=mt.__newindex
    setreadonly(mt,false)
    mt.__newindex=newcclosure(function(self,k,v)
        if k=="CFrame" and self==Camera then return end
        return old(self,k,v)
    end)
    setreadonly(mt,true)
end

if MISC.ModDetector then
    Players.PlayerAdded:Connect(function(p)
        local n=p.Name:lower()
        if n:find("mod") or n:find("admin") or n:find("staff") then
            if MISC.ModAction=="Notify" or MISC.ModAction=="NotifyKick" then
                game:GetService("StarterGui"):SetCore("SendNotification",{Title="⚠ Mod Detected",Text=p.DisplayName.." joined.",Duration=6})
            end
            if MISC.ModAction=="Kick" or MISC.ModAction=="NotifyKick" then LP:Kick("Mod in server.") end
        end
    end)
end

if MISC.AutoFarm then
    RunService.Heartbeat:Connect(function()
        local c=LP.Character;local hrp=c and c:FindFirstChild("HumanoidRootPart");if not hrp then return end
        for _,obj in WS:GetDescendants() do
            if (obj.Name=="Cash" or obj.Name=="Money" or obj.Name=="Bill") and obj:IsA("BasePart") then
                if (obj.Position-hrp.Position).Magnitude<200 then hrp.CFrame=CFrame.new(obj.Position) end
            end
        end
    end)
end

if MISC.AutoReload then
    RunService.Heartbeat:Connect(function()
        local c=LP.Character;if not c then return end
        local tool=c:FindFirstChildOfClass("Tool");if not tool then return end
        local reload=tool:FindFirstChild("Reload") or tool:FindFirstChild("ReloadEvent")
        if reload and reload:IsA("RemoteEvent") then reload:FireServer() end
    end)
end

print("[DaHood] Loaded.")

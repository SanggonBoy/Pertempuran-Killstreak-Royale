-- PERTEMPURAN KILLSTREAK ROYALE v1 - Starter HUD
-- PlaceId: 104856666707760 | Shooter misi (kill SMG, buka peti, arena/royal)
-- Toggle: Insert / RightShift / tombol KR. Semua default OFF, tidak menulis
-- gerakan sebelum user menyentuh slider (pola anti-flicker + anti dobel-jalan).
-- GUARD: queue_on_teleport Xeno GLOBAL → file bisa dieksekusi di game lain.
-- PlaceId resmi 104856666707760 (atau universe 9705384247 bila pindah place).
if game.PlaceId~=104856666707760 and game.GameId~=9705384247 then
	warn('[KR] Dilewati: cheat ini untuk Killstreak Royale, bukan game lain (place '..tostring(game.PlaceId)..')')
	return
end

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local UIS=game:GetService('UserInputService')
local Workspace=game:GetService('Workspace')
local TeleportService=game:GetService('TeleportService')

local lp=Players.LocalPlayer
local pg=lp:WaitForChild('PlayerGui')

local old=pg:FindFirstChild('KKR_HUD')
if old then old:Destroy() end

-- Generasi anti dobel-jalan
local ENV=(function()
	local ok,g=pcall(function() return getgenv() end)
	if ok and g then return g end
	return _G
end)()
ENV.KKR_GEN=(ENV.KKR_GEN or 0)+1
local MYGEN=ENV.KKR_GEN
local function alive() return MYGEN==ENV.KKR_GEN end

-- ================= STATE (session-local, tidak otomatis) =================
local S={
	espP=false, espC=false, fb=false,
	fly=false, flySpd=70, nc=false, ij=false, afk=false,
}
local SavedWS, SavedJP = 16, 50
local SpeedDirty, JumpDirty = false, false
local SavedPos = nil
local function applyStats()
	local c=lp.Character
	if not c then return end
	local h=c:FindFirstChildOfClass('Humanoid')
	if not h then return end
	if SpeedDirty then pcall(function() h.WalkSpeed=SavedWS end) end
	if JumpDirty then pcall(function() if not h.UseJumpPower then h.UseJumpPower=true end h.JumpPower=SavedJP end) end
end
lp.CharacterAdded:Connect(function(c)
	pcall(function() c:WaitForChild('Humanoid',5) end)
	task.wait(0.5)
	pcall(applyStats)
end)
local oFB={Lighting.Brightness,Lighting.Ambient,Lighting.OutdoorAmbient,Lighting.ClockTime,Lighting.GlobalShadows}
local espReg={}

-- ================= UTIL =================
local function mk(c,pr,p)
	local o=Instance.new(c)
	for k,v in pairs(pr) do o[k]=v end
	o.Parent=p
	return o
end
local function cr(p,r)
	mk('UICorner',{CornerRadius=UDim.new(0,r or 8)},p)
	return p
end
local function log(t) print('[KKR] '..tostring(t)) end

-- ================= FRAME =================
local gui=mk('ScreenGui',{Name='KKR_HUD',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},pg)
local main=mk('Frame',{Name='Main',Size=UDim2.new(0,560,0,400),Position=UDim2.new(0.5,-280,0.5,-200),BackgroundColor3=Color3.fromRGB(20,16,14),BorderSizePixel=0,Active=true},gui)
cr(main,12)
mk('UIStroke',{Color=Color3.fromRGB(150,70,40),Thickness=1.2},main)

local float=mk('TextButton',{Text='KR',Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(255,255,255),Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,12,0.5,-26),BackgroundColor3=Color3.fromRGB(150,60,40),BorderSizePixel=0,Active=true,AutoButtonColor=true},gui)
cr(float,26)
mk('UIStroke',{Color=Color3.fromRGB(255,140,80),Thickness=2},float)
do
	local dg,sp,si,mvd=false,nil,nil,0
	float.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then
			dg=true mvd=0 sp=float.Position si=io.Position
		end
	end)
	float.InputEnded:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dg=false end
	end)
	UIS.InputChanged:Connect(function(io)
		if dg and sp and si and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then
			local d=io.Position-si
			mvd=mvd+math.abs(d.X)+math.abs(d.Y)
			float.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	float.MouseButton1Click:Connect(function() if mvd<8 and ENV.KKR_GEN==MYGEN then main.Visible=not main.Visible setCursorFree(main.Visible) end end)
end

local tb=mk('Frame',{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(30,24,20),BorderSizePixel=0},main)
cr(tb,12)
mk('TextLabel',{BackgroundTransparency=1,Position=UDim2.new(0,14,0,0),Size=UDim2.new(0.7,0,1,0),Text='⚔ KILLSTREAK ROYALE v1',Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,150,90),TextXAlignment=Enum.TextXAlignment.Left},tb)
local bHide=mk('TextButton',{Position=UDim2.new(1,-40,0,7),Size=UDim2.new(0,30,0,24),Text='–',Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.fromRGB(220,220,230),BackgroundColor3=Color3.fromRGB(50,40,35),BorderSizePixel=0},tb)
cr(bHide,6)
-- Buka HUD = cursor dibebaskan (game shooter mengunci mouse);
-- tutup HUD = kunci lagi. Plus tombol manual di tab Lain.
local CursorFree=false
local SavedBehavior=nil
local function setCursorFree(on)
	CursorFree=on
	pcall(function()
		if on then
			SavedBehavior=UIS.MouseBehavior
			UIS.MouseBehavior=Enum.MouseBehavior.Default
		elseif SavedBehavior then
			UIS.MouseBehavior=SavedBehavior
		else
			UIS.MouseBehavior=Enum.MouseBehavior.LockedCenter
		end
	end)
end
bHide.MouseButton1Click:Connect(function() main.Visible=false setCursorFree(false) end)
do
	local dg,sp,si=false,nil,nil
	tb.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then
			dg=true sp=main.Position si=io.Position
		end
	end)
	tb.InputEnded:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dg=false end
	end)
	UIS.InputChanged:Connect(function(io)
		if dg and sp and si and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then
			local d=io.Position-si
			main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end

-- ================= WIDGETS =================
local ord=0
local togPainters={}
local slideRegs={}
local function sect(page,txt)
	ord=ord+1
	mk('TextLabel',{Size=UDim2.new(1,-4,0,20),BackgroundTransparency=1,Text=txt,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,150,90),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=ord},page)
end
local function tog(page,txt,key,cb)
	ord=ord+1
	local b=mk('TextButton',{Size=UDim2.new(1,-4,0,34),BackgroundColor3=Color3.fromRGB(35,28,24),Text='',Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(215,210,205),TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,LayoutOrder=ord},page)
	mk('UIPadding',{PaddingLeft=UDim.new(0,12)},b)
	cr(b,8)
	local function paint()
		local on=S[key]
		b.Text=txt..'      '..(on and '● ON' or '○ OFF')
		b.BackgroundColor3=on and Color3.fromRGB(120,60,30) or Color3.fromRGB(35,28,24)
	end
	paint()
	togPainters[key]=togPainters[key] or {}
	table.insert(togPainters[key],paint)
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		paint()
		if cb then cb(S[key]) end
	end)
	return b
end
local function btn(page,txt,cb)
	ord=ord+1
	local b=mk('TextButton',{Size=UDim2.new(1,-4,0,34),BackgroundColor3=Color3.fromRGB(60,45,30),Text=txt,Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(235,230,225),BorderSizePixel=0,LayoutOrder=ord},page)
	cr(b,8)
	b.MouseButton1Click:Connect(function()
		task.spawn(function() pcall(cb) end)
	end)
	return b
end
local function slide(page,txt,min,max,def,cb)
	ord=ord+1
	local f=mk('Frame',{Size=UDim2.new(1,-4,0,48),BackgroundColor3=Color3.fromRGB(30,25,22),BorderSizePixel=0,LayoutOrder=ord},page)
	cr(f,8)
	mk('TextLabel',{BackgroundTransparency=1,Position=UDim2.new(0,12,0,4),Size=UDim2.new(0.6,0,0,16),Text=txt,Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(205,200,195),TextXAlignment=Enum.TextXAlignment.Left},f)
	local val=mk('TextLabel',{BackgroundTransparency=1,Position=UDim2.new(1,-62,0,4),Size=UDim2.new(0,50,0,16),Text=tostring(def),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,170,100),TextXAlignment=Enum.TextXAlignment.Right},f)
	local bar=mk('Frame',{Position=UDim2.new(0,12,0,28),Size=UDim2.new(1,-24,0,6),BackgroundColor3=Color3.fromRGB(55,45,40),BorderSizePixel=0},f)
	cr(bar,3)
	local fill=mk('Frame',{Size=UDim2.new((def-min)/math.max(max-min,1),0,1,0),BackgroundColor3=Color3.fromRGB(255,130,60),BorderSizePixel=0},bar)
	cr(fill,3)
	local hold=false
	local function set(x)
		local rel=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
		local v=math.floor(min+(max-min)*rel+0.5)
		val.Text=tostring(v)
		fill.Size=UDim2.new(rel,0,1,0)
		cb(v)
	end
	local function setVal(v)
		v=math.clamp(math.floor(v+0.5),min,max)
		local rel=(v-min)/math.max(max-min,1)
		val.Text=tostring(v)
		fill.Size=UDim2.new(rel,0,1,0)
		cb(v)
	end
	table.insert(slideRegs,{def=def,set=setVal})
	bar.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then hold=true set(io.Position.X) end
	end)
	UIS.InputEnded:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then hold=false end
	end)
	UIS.InputChanged:Connect(function(io)
		if hold and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then set(io.Position.X) end
	end)
	return f
end

-- ================= TABS =================
local side=mk('Frame',{Position=UDim2.new(0,10,0,46),Size=UDim2.new(0,128,1,-56),BackgroundColor3=Color3.fromRGB(25,20,17),BorderSizePixel=0},main)
cr(side,10)
local body=mk('Frame',{Position=UDim2.new(0,146,0,46),Size=UDim2.new(1,-156,1,-56),BackgroundTransparency=1},main)
local pages={}
local tabBtns={}
local tabDefs={'Gerak','Lihat','Lain'}
for i,nm in ipairs(tabDefs) do
	local b=mk('TextButton',{Size=UDim2.new(1,-12,0,36),Position=UDim2.new(0,6,0,(i-1)*42+8),Text=nm,Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(200,195,190),BackgroundColor3=Color3.fromRGB(32,27,24),BorderSizePixel=0,AutoButtonColor=true},side)
	cr(b,8)
	tabBtns[nm]=b
	local f=mk('ScrollingFrame',{Name=nm,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=Color3.fromRGB(150,90,50),CanvasSize=UDim2.new(0,0,0,700),Visible=false},body)
	mk('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},f)
	mk('UIPadding',{PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,2)},f)
	pages[nm]=f
	b.MouseButton1Click:Connect(function()
		for n,fr in pairs(pages) do fr.Visible=(n==nm) end
		for n,bt in pairs(tabBtns) do
			bt.BackgroundColor3=(n==nm) and Color3.fromRGB(150,70,35) or Color3.fromRGB(32,27,24)
		end
	end)
end
pages['Gerak'].Visible=true
tabBtns['Gerak'].BackgroundColor3=Color3.fromRGB(150,70,35)

-- ================= ISI =================
sect(pages['Gerak'],'KECEPATAN (tulis hanya saat digeser)')
slide(pages['Gerak'],'WalkSpeed',16,300,16,function(v) SavedWS=v SpeedDirty=true local c=lp.Character local h=c and c:FindFirstChildOfClass('Humanoid') if h then h.WalkSpeed=v end end)
slide(pages['Gerak'],'JumpPower',50,300,50,function(v) SavedJP=v JumpDirty=true local c=lp.Character local h=c and c:FindFirstChildOfClass('Humanoid') if h then if not h.UseJumpPower then h.UseJumpPower=true end h.JumpPower=v end end)
sect(pages['Gerak'],'TERBANG')
slide(pages['Gerak'],'Fly Speed',20,200,70,function(v) S.flySpd=v end)
tog(pages['Gerak'],'Fly (WASD + Spasi)','fly',function(on) setFly(on) end)
tog(pages['Gerak'],'Noclip','nc')
tog(pages['Gerak'],'Infinite Jump','ij')
sect(pages['Gerak'],'TELEPORT')
btn(pages['Gerak'],'📍 Simpan Posisi',function()
	local hrp=lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
	if hrp then SavedPos=hrp.CFrame log('Posisi disimpan.') end
end)
btn(pages['Gerak'],'🚀 Ke Posisi Tersimpan',function()
	local hrp=lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
	if hrp and SavedPos then hrp.CFrame=SavedPos log('Teleport OK.') else log('Belum ada posisi.') end
end)

sect(pages['Lihat'],'ESP')
tog(pages['Lihat'],'ESP Pemain','espP')
tog(pages['Lihat'],'ESP Chest / Supply','espC')
sect(pages['Lihat'],'LAYAR')
tog(pages['Lihat'],'Fullbright','fb',function(on)
	if not on then
		pcall(function()
			Lighting.Brightness=oFB[1]
			Lighting.Ambient=oFB[2]
			Lighting.OutdoorAmbient=oFB[3]
			Lighting.ClockTime=oFB[4]
			Lighting.GlobalShadows=oFB[5]
		end)
	end
end)
btn(pages['Lihat'],'⚡ FPS Boost',function()
	for _,v in pairs(Workspace:GetDescendants()) do
		if v:IsA('BasePart') then v.Material=Enum.Material.SmoothPlastic v.Reflectance=0
		elseif v:IsA('Decal') or v:IsA('Texture') then v.Transparency=1
		elseif v:IsA('ParticleEmitter') or v:IsA('Trail') then v.Enabled=false end
	end
	Lighting.GlobalShadows=false
	log('FPS Boost OK (rejoin untuk pulihkan).')
end)

sect(pages['Lain'],'UTILITAS')
tog(pages['Lain'],'Anti AFK','afk')
btn(pages['Lain'],'🖱 Cursor Bebas / Kunci',function()
	setCursorFree(not CursorFree)
	log(CursorFree and 'Cursor bebas.' or 'Cursor dikunci.')
end)
btn(pages['Lain'],'🧹 Reset Total',function() resetAll() end)
btn(pages['Lain'],'🔄 Respawn',function()
	local h=lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')
	if h then h.Health=0 end
end)
btn(pages['Lain'],'🔁 Rejoin',function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,lp)
end)

-- ================= LOGIKA =================
local flyConn=nil
function setFly(on)
	if on then
		local c=lp.Character
		local hum=c and c:FindFirstChildOfClass('Humanoid')
		if hum then hum.PlatformStand=true end
		if flyConn then flyConn:Disconnect() end
		flyConn=RunService.Heartbeat:Connect(function(dt)
			if ENV.KKR_GEN~=MYGEN then return end
			dt=math.min(dt or 0.016,0.05)
			local cc=lp.Character
			local hh=cc and cc:FindFirstChild('HumanoidRootPart')
			local hu=cc and cc:FindFirstChildOfClass('Humanoid')
			if not S.fly or not hh then return end
			local cam=Workspace.CurrentCamera
			if not cam then return end
			local d=Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then d+=cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then d-=cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then d-=cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then d+=cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then d+=Vector3.new(0,1,0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d-=Vector3.new(0,1,0) end
			if d.Magnitude>0.01 then
				hh.CFrame=hh.CFrame+(d.Unit*S.flySpd*dt)
			end
			pcall(function() hh.AssemblyLinearVelocity=Vector3.zero end)
			if hu then hu.PlatformStand=true end
		end)
	else
		if flyConn then flyConn:Disconnect() flyConn=nil end
		local c=lp.Character
		local hum=c and c:FindFirstChildOfClass('Humanoid')
		if hum then hum.PlatformStand=false end
	end
end

function resetAll()
	S.espP=false S.espC=false S.fb=false
	S.fly=false S.nc=false S.ij=false S.afk=false
	setFly(false)
	setCursorFree(false)
	pcall(function()
		Lighting.Brightness=oFB[1]
		Lighting.Ambient=oFB[2]
		Lighting.OutdoorAmbient=oFB[3]
		Lighting.ClockTime=oFB[4]
		Lighting.GlobalShadows=oFB[5]
	end)
	pcall(function()
		local c=lp.Character
		if c then
			for _,p in ipairs(c:GetDescendants()) do
				if p:IsA('BasePart') then p.CanCollide=(p.Name~='HumanoidRootPart') end
			end
			local h=c:FindFirstChildOfClass('Humanoid')
			if h then h.WalkSpeed=16 h.JumpPower=50 end
		end
	end)
	for _,h in pairs(espReg) do pcall(function() h:Destroy() end) end
	espReg={}
	pcall(function()
		for _,v in pairs(Workspace:GetDescendants()) do
			if v:IsA('Highlight') and (v.Name=='KKR_P' or v.Name=='KKR_C') then
				pcall(function() v:Destroy() end)
			end
		end
	end)
	ENV.KKR_GEN=(ENV.KKR_GEN or 0)+1
	MYGEN=ENV.KKR_GEN
	for _,s in ipairs(slideRegs) do pcall(function() s.set(s.def) end) end
	SavedWS,SavedJP=16,50
	SpeedDirty,JumpDirty=false,false
	for _,ps in pairs(togPainters) do for _,p in ipairs(ps) do pcall(p) end end
	log('Reset total: normal lagi (FPS Boost butuh rejoin).')
end

-- noclip halus
task.spawn(function()
	while alive() do
		if S.nc then
			local c=lp.Character
			if c then
				for _,p in ipairs(c:GetDescendants()) do
					if p:IsA('BasePart') and p.CanCollide then p.CanCollide=false end
				end
			end
		end
		task.wait(0.3)
	end
end)
UIS.JumpRequest:Connect(function()
	if ENV.KKR_GEN~=MYGEN then return end
	if S.ij and lp.Character then
		local h=lp.Character:FindFirstChildOfClass('Humanoid')
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
lp.Idled:Connect(function()
	if S.afk then
		pcall(function()
			game:GetService('VirtualUser'):CaptureController()
			game:GetService('VirtualUser'):ClickButton2(Vector2.new())
		end)
	end
end)

-- ESP pemain (humanoid, bukan diri sendiri) + chest
local function clearTag(tag)
	for _,v in pairs(Workspace:GetDescendants()) do
		if v:IsA('Highlight') and v.Name==tag then pcall(function() v:Destroy() end) end
	end
end
local function anchorOf(m)
	return m:FindFirstChild('Head') or m:FindFirstChild('HumanoidRootPart') or m:FindFirstChildWhichIsA('BasePart',true)
end
local function isPlayerChar(m)
	if m==lp.Character then return false end
	if not m:FindFirstChildOfClass('Humanoid') then return false end
	if not m:FindFirstChild('HumanoidRootPart') then return false end
	if not Players:GetPlayerFromCharacter(m) then return false end
	return true
end
local function isChest(m)
	if not m:IsA('Model') then return false end
	local n=m.Name:lower()
	return n:find('chest',1,true) or n:find('crate',1,true) or n:find('supply',1,true)
		or n:find('drop',1,true) or n:find('loot',1,true) or n:find('peti',1,true)
end
task.spawn(function()
	while alive() do
		if S.espP then
			for _,m in ipairs(Workspace:GetChildren()) do
				if m:IsA('Model') and isPlayerChar(m) and not m:FindFirstChild('KKR_P') then
					local h=Instance.new('Highlight')
					h.Name='KKR_P' h.FillColor=Color3.fromRGB(255,70,70)
					h.FillTransparency=0.6 h.Adornee=m h.Parent=m
				end
			end
		else
			clearTag('KKR_P')
		end
		if S.espC then
			for _,m in ipairs(Workspace:GetDescendants()) do
				if isChest(m) and not m:FindFirstChild('KKR_C') then
					local h=Instance.new('Highlight')
					h.Name='KKR_C' h.FillColor=Color3.fromRGB(255,200,60)
					h.FillTransparency=0.5 h.Adornee=m h.Parent=m
					local an=anchorOf(m)
					if an then
						local bb=Instance.new('BillboardGui')
						bb.Name='KKR_CBB' bb.Size=UDim2.new(0,130,0,26)
						bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.Parent=an
						local tx=Instance.new('TextLabel')
						tx.Size=UDim2.new(1,0,1,0) tx.BackgroundColor3=Color3.fromRGB(10,10,15)
						tx.BackgroundTransparency=0.3 tx.Font=Enum.Font.GothamBold tx.TextSize=12
						tx.TextColor3=Color3.fromRGB(255,210,100) tx.TextStrokeTransparency=0.2
						tx.Text=m.Name tx.Parent=bb
						mk('UICorner',{CornerRadius=UDim.new(0,6)},tx)
					end
				end
			end
		else
			clearTag('KKR_C')
			for _,v in pairs(Workspace:GetDescendants()) do
				if v:IsA('BillboardGui') and v.Name=='KKR_CBB' then pcall(function() v:Destroy() end) end
			end
		end
		task.wait(2)
	end
end)

-- fullbright saat ON (snapshot dipulihkan saat OFF/reset)
task.spawn(function()
	while alive() do
		if S.fb then
			Lighting.Brightness=2 Lighting.ClockTime=14
			Lighting.FogEnd=100000 Lighting.GlobalShadows=false
		end
		task.wait(1)
	end
end)

UIS.InputBegan:Connect(function(io,gp)
	if gp then return end
	if ENV.KKR_GEN~=MYGEN then return end
	if io.KeyCode==Enum.KeyCode.Insert or io.KeyCode==Enum.KeyCode.RightShift then
		main.Visible=not main.Visible
		setCursorFree(main.Visible)
	end
end)

-- Jalan otomatis lagi setelah pindah lobby <-> match (teleport antar place)
pcall(function()
	if queue_on_teleport then
		queue_on_teleport("loadstring(readfile('D:/New Downloads/RobloxForFun/Pertempuran Killstreak Royale/Pertempuran Killstreak Royale.lua'))()")
	end
end)

print('[KKR] v1 Loaded! Insert / RightShift = tampil/sembunyi.')

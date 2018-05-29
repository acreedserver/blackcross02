
wsel = wsel or {}

local key = CreateClientConVar("wep_select_key",wsel.DefaultKey,true,false)
local closedelay = CreateClientConVar("wep_select_auto_close_delay",2.0,true,false)
local autopick = CreateClientConVar("wep_select_auto_close_select",0,true,false)
local selectpack = CreateClientConVar("wep_select_sounds",1,true,false)
local use = CreateClientConVar("wep_select_use",1,true,false)

local function shoulduse()
	return use:GetBool() or wsel.ForceUse
end

for i=12,48 do
	surface.CreateFont("wselRoboto"..i,{
		weight=510 + 48 - i%48,
		font="Roboto",
		size=i
	})
end


//Hotkey opens menu
local hotkeydown = false
hook.Add("Think","OpenWepSelectGTA",function()
	-- if not shoulduse() then return end
	if not IsValid(vgui.GetKeyboardFocus()) and not gui.IsConsoleVisible() then
		
		if input.IsKeyDown(_G["KEY_"..key:GetString():upper()]) then
			if !hotkeydown then
				wsel.OpenWepSelect()
				hotkeydown = true
			end
		elseif hotkeydown then
			wsel.CloseWepSelect()
			hotkeydown = false
		end
	end
end)

//Weapon Selection Code
local function PickWeapon( class )
	if not class then return end
	if ( !LocalPlayer():HasWeapon( class ) ) then return end
	LocalPlayer().SwitchWeaponTo = LocalPlayer():GetWeapon( class )
	LocalPlayer().WepSwitchTime = CurTime()
	LocalPlayer().LastInv = LocalPlayer():GetActiveWeapon()
end
hook.Add( "CreateMove", "WeaponSwitch", function( cmd )
	if IsValid( LocalPlayer().SwitchWeaponTo ) then
		cmd:SelectWeapon( LocalPlayer().SwitchWeaponTo )

		if ( LocalPlayer():GetActiveWeapon() == LocalPlayer().SwitchWeaponTo ) or CurTime() - LocalPlayer().WepSwitchTime > 2 then
			LocalPlayer().SwitchWeaponTo = nil
		end
	end
end )

//Scrolling, slotnums, lastinv, and clicking.
hook.Add("PlayerBindPress","aWeaponSelect",function(ply,bind,down)
	if not down then return end
	if not shoulduse() then return end
	
	//Ignore scrolling with physgun
	if ply:IsValid() and ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
		if (bind == "invnext" or bind == "invprev") and input.IsMouseDown(MOUSE_LEFT) then
			return
		end
	end
	
	//Lastinv switching
	if bind == "lastinv" and IsValid(ply.LastInv) then
		PickWeapon(ply.LastInv:GetClass())
		return true
	end
	
	//Open menu send command
	if bind == "invnext" or bind == "invprev" or bind:sub(1,4) == "slot" or bind == "+attack" then
		if !hotkeydown and (!IsValid(g_WepSelect) or g_WepSelect.invert) and bind != "+attack" then
			wsel.OpenWepSelect()
			
			if not(bind == "invnext" or bind == "invprev") then
				if IsValid(g_WepSelect) and not g_WepSelect.invert then
					g_WepSelect:RunCommand(bind)
				end
			end
			return true
		else
			if IsValid(g_WepSelect) and not g_WepSelect.invert then
				g_WepSelect:RunCommand(bind)
				return true
			end
		end
		
	end
end)

//Update menu on pickup
hook.Add("HUDWeaponPickedUp","WeaponGrab",function( weapon )
	if IsValid(g_WepSelect) and !g_WepSelect.invert then
		g_WepSelect:Update()
	end
end)

//Hide Weaponselect
hook.Add("HUDShouldDraw","NoWepSelect",function(e)
	if e == "CHudWeaponSelection" then return not shoulduse() end
end)



local function getmat(swep)
	if wsel.PreviewIcons[swep:GetClass()] then
		return Material(wsel.PreviewIcons[swep:GetClass()], "smooth")
	end
	if swep.Icon then
		return Material(swep.Icon)
	end
	
	local name = "entities/"..swep:GetClass()..".png"
	local mat = Material(name, "smooth")
	if ( !mat || mat:IsError() ) then

		name = name:Replace( "entities/", "VGUI/entities/" )
		name = name:Replace( ".png", "" )
		mat = Material( name, "smooth" )

	end
	if ( mat and  !mat:IsError() ) then
		return mat
	else
		return Material("vgui/avatar_default")
	end
end

//This function is called several times per frame while the inventory is open:
local badnums = {
	[7]=true,
	[8]=true,
	[11]=true
}
local function drawSegments(pnl,sections,w,h,thicker)
	sections = math.max(sections,1)
	local dtime = RealTime()-pnl.ctime
	local animtime = .1
	
	local lerp = !pnl.invert and Lerp(dtime/animtime, 10, thicker and 291 or 288) or Lerp(dtime/animtime, 288, 0)
	
	local hover = pnl.selected
	
	local iter
	if badnums[sections] or sections > 15 then
		iter = 1
	else
		iter = thicker and 1 or 2
	end
	
	for i=0, sections-1 do
		local col = (i==hover and thicker) and Color(0,200,0, 255) or Color(0,0,0, 240)
		local spacer = sections > 1 and (thicker and 1 or 3) or 0
		local starta = i*360/sections + spacer/2 + (thicker and .5 or 0)
		local enda = starta+360/sections - spacer/2
		local thick = thicker and math.min(95.5,lerp) or math.min(90,lerp)
		
		
		render.SetStencilReferenceValue(i+1)
		draw.Arc(w/2,h/2,lerp,thick, starta, enda, iter, col)
		
		
	end
end

//Create ordered weapon select tables and find out where the current selection is.
local function generateWeaponTables(ply)
	local weps = table.Copy(ply:GetWeapons()) or {}
	local slotted = {{},{},{},{},{},{},{},{},{},{},{},{}}
	local curwep = ply:GetActiveWeapon()
	local slot = 0
	
	table.sort(weps, function(a,b)
		if a:GetSlot() == b:GetSlot() then
			if a:GetSlotPos() == b:GetSlotPos() then
				return a:GetClass() < b:GetClass()
			else
				return a:GetSlotPos() < b:GetSlotPos()
			end
		else
			return a:GetSlot() < b:GetSlot()
		end
		
	end)
	
	for k,v in ipairs(weps)do
		local s = v:GetSlot()+1
		slotted[s] = slotted[s] or {}
		table.insert(slotted[s], v)
		
		//Also do this right here because why not
		if IsValid(curwep) then
			if curwep == v then
				slot=k
			end
		end
	end
	
	return weps or {}, slotted or {{},{},{},{},{},{},{},{},{},{},{},{}}, slot
end

-- local blur = Material("pp/blurscreen")


//Here's some shitty and complicated code! :D
function wsel.OpenWepSelect(bind)
	if not LocalPlayer():Alive() then return end
	if LocalPlayer():GetObserverMode() != OBS_MODE_NONE then return end
	
	if IsValid(g_WepSelect) and not g_WepSelect.invert then return end
	
	
	if wsel.premium then
		net.Start("inv_open")
			net.WriteBit(01)
		net.SendToServer()
		
		wsel.slow_out:Pause()
		wsel.slow_out:SetTime(0)
		wsel.slow_in:Play()
		wsel.heartbeat:Play()
	end
	
	if g_WepSelect then g_WepSelect:Remove() end
	local sw,sh = ScrW(),ScrH()
	
	gui.SetMousePos(ScrW()/2,ScrH()/2)
	
	//Create frame
	local radial = vgui.Create("EditablePanel")
	radial.ctime = RealTime()
	radial.lastact = RealTime()
	radial:SetSize(sw,sh)
	-- radial:SetCursor("blank")
	radial:Center()
	radial:MakePopup()
	radial:SetKeyboardInputEnabled(false)
	
	
	//Set global variable
	g_WepSelect = radial
	
	//Create settings button:
	radial.settings = vgui.Create("DButton",radial)
	radial.settings:SetSize(250,100)
	radial.settings:SetText("Quickdraw by Bobblehead")
	radial.settings:CenterHorizontal()
	radial.settings:AlignBottom(10)
	radial.settings:SetTextColor(Color(255,255,255))
	function radial.settings:Paint(w,h)
		draw.RoundedBox(8,0,0,w,h,Color(0,0,0,200))
	end
	
	//Create centerpieces:
	radial.selectedMdl = vgui.Create("DImage",radial)
	radial.selectedMdl:SetSize(400,400)
	radial.selectedMdl:Center()
	radial.selectedMdl:SetPaintedManually(true)
	-- radial.selectedMdl:SetFOV(60)
	-- function radial.selectedMdl:LayoutEntity(ent)
		-- if ( self.bAnimated ) then
			-- self:RunAnimation()
		-- end
		
		-- self:SetCamPos( Vector( 50, 50, 50 ) )
		-- self:SetLookAt( Vector( 0, 0, 40 ) )
		-- ent:SetModelScale(1.8*(radial.weapons[radial.selected+1].ModelScale or 1),0)
		-- ent:SetAngles( Angle( self.pitch, RealTime()*20,  0) )
		-- ent:SetPos(Vector(0,0,48))
		
		-- -- if isfunction(ent.DrawWorldModel) then
			-- //todo: Draw like the model.
		-- -- end
	-- end
	function radial.selectedMdl:OnMousePressed(mc)
		radial:OnMousePressed(mc)
	end
	
	radial.selectedName = vgui.Create("DLabel",radial)
	radial.selectedName:SetText("")
	radial.selectedName:SetPos(sw/2,sh/2+50)
	radial.selectedName:SetFont("wselRoboto28")
	radial.selectedName:SetTextColor(Color(255,255,255,200))
	radial.selectedName:SetExpensiveShadow(2,Color(0,0,0))
	
	radial.selectedDesc = vgui.Create("DLabel",radial)
	radial.selectedDesc:SetText("")
	radial.selectedDesc:SetPos(sw/2,sh/2+80)
	radial.selectedDesc:SetFont("wselRoboto20")
	radial.selectedDesc:SetTextColor(Color(255,255,255,200))
	radial.selectedDesc:SetExpensiveShadow(1,Color(0,0,0))
	
	function radial.selectedDesc:Update(item)
		local clip = item:Clip1()
		local max = item:GetMaxClip1()
		local ammotype = item:GetPrimaryAmmoType()
		local extra = LocalPlayer():GetAmmoCount(ammotype)
		
		clip = clip > -1 and (max > 0 and clip or "") or ""
		max = max > 0 and "  /  " .. max .. " " or ""
		extra = ammotype != -1 and " ( +" .. extra .. " )" or ""
		
		self:SetText(clip .. max .. extra)
		self:SizeToContents()
		self:CenterHorizontal()
	end
	
	//Paint the wheels.
	function radial:Paint(w,h) 
		
		local dtime = RealTime()-self.ctime
		local animtime = .1
		
		if self.invert and dtime>animtime then return end //Don't draw anything once it's closed.
		
		//Draw rotation
		local m = Matrix()
		local ang = math.cos(RealTime())/2
		local rad = -math.rad( ang )
		local x = w/2 - ( math.cos( rad ) * w / 2 + math.sin( rad ) * h / 2 )
		local y = -h/2 + ( math.sin( rad ) * w / 2 + math.cos( rad ) * h / 2 )
		local m = Matrix()
		m:SetAngles( Angle( 0, ang, 0 ) )
		m:SetTranslation( Vector( x, y, 0 ) )
		cam.PushModelMatrix( m )
		
		//Draw the bars.
		local sections = #self.weapons

		local x, y = self:LocalToScreen(0, 0);
		render.SetStencilEnable(true)
		render.ClearStencil()
		render.SetStencilTestMask(255)
		render.SetStencilWriteMask(255)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_NEVER)
		render.SetStencilFailOperation(STENCIL_REPLACE)
		render.SetStencilZFailOperation(STENCIL_REPLACE)
		render.SetStencilPassOperation(STENCIL_KEEP)

		draw.NoTexture()
		
		//Define bars
		drawSegments(self,sections,w,h)
		
		//Draw bar fill
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		for i=0, sections do
			
			render.SetStencilReferenceValue(i+1)
			-- local col = (i==self.selected and Color(0,200,0, 100) or Color(0,0,0,200))
			local col = Color(0,0,0,200)
			surface.SetDrawColor(col)
			surface.DrawRect(0,0,w,h)
			
		end
		
		//Reposition and draw previews
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		
		local spacer = sections > 1 and 3 or 0
		local lerp = !self.invert and Lerp(dtime/animtime, 10, 288) or Lerp(dtime/animtime, 288, 0)
		for id=1, sections do
			
			render.SetStencilReferenceValue(id)
			
			local starta = (id-1)*360/sections + spacer/2
			local enda = starta+360/sections - spacer/2
			if IsValid(self.previews[id]) then
				local x,y = math.cos(math.rad(enda-(enda-starta)/2-0))*(lerp-48), -math.sin(math.rad(enda-(enda-starta)/2-0))*(lerp-48)
				local pw = !self.invert and Lerp(dtime/animtime, 10, 180) or Lerp(dtime/animtime, 180, 0)
				if sections > 12 then
					pw = math.min(pw - sections*2, pw)
				end
				self.previews[id]:SetPos(x+w/2-pw/2,y+h/2-pw/2)
				self.previews[id]:SetSize(pw,pw)
				self.previews[id]:PaintManual()
			end
		end
		
		
		//Draw outlines
		draw.NoTexture()
		render.SetStencilCompareFunction(STENCIL_GREATER)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		drawSegments(self,sections,w,h,true)
		// surface.DrawRect(x * -1, y * -1, ScrW(), ScrH());
		
		
		//Draw center circle
		local dtime = RealTime() - self.ctime
		local lerp = !self.invert and Lerp(dtime/.1, 10, 199) or Lerp(dtime/.1, 199, 0)
		
		if !self.invert or dtime < .1 then
			render.ClearStencil()
			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCIL_NEVER)
			render.SetStencilPassOperation(STENCIL_KEEP)
			render.SetStencilFailOperation(STENCIL_REPLACE)
			render.SetStencilZFailOperation(STENCIL_REPLACE)
			
			//Define circle
			draw.Arc(w/2,h/2,lerp-2,lerp-2,0,360,10,Color(255,255,255))
			
		end
		
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		
		-- self.selectedMdl:PaintManual()
		
		-- //Update Description
		if self.selected then 
			local item = self.weapons[self.selected+1]
			if item then
				self.selectedDesc:Update(item)
			end
		end
		
		//Change cursor type
		local mx,my = gui.MousePos()
		local cw,ch = sw/2,sh/2
		local dist = math.sqrt((mx-ScrW()/2)^2 + (my-ScrH()/2)^2)
		if dist > 196 then //Mouse in outer ring
			self:SetCursor("hand")
		else
			self:SetCursor("arrow")
		end
		
		render.SetStencilEnable(false)
		
		cam.PopModelMatrix()
		
	end
	
	
	function radial:GetHovered()
		local sections = #self.weapons
		local mx,my = gui.MousePos()
		local hover = 0
		mx = ScrW()/2 - mx
		my = ScrH()/2 - my
		
		local ang = 180 - math.deg(math.atan2(my,mx))
		hover = math.floor(math.Remap(ang, 0, 360, 0, sections))
		
		return hover
	end
	
	function radial:OnMousePressed(mc)
		local mx,my = gui.MousePos()
		
		local hover = self:GetHovered()
		local dist = math.sqrt((mx-ScrW()/2)^2 + (my-ScrH()/2)^2)
		
		if dist > 196 and mc==MOUSE_LEFT then
			local old = self.selected 
			
			self:SelectItem(hover+1)
			if old == hover then 
				self:Close()
				return
			end
			self.noauto = true
			
		else
			self:Close()
		end
		
	end
	
	function radial:SelectItem(num)
		
		surface.PlaySound(wsel.selectSounds[selectpack:GetInt()][2])
		
		local item = self.weapons[num]
		self.lastact = RealTime()
		
		if IsValid(item) then
			self.selected = num-1
			
			-- self.selectedMdl:SetModel(item:GetModel() or "")
			-- if self.selectedMdl.Entity then
				-- self.selectedMdl.Entity:SetSkin(item:GetSkin())
			
				-- self.selectedMdl.Entity:SetMaterial(item:GetMaterial())
				-- self.selectedMdl.Entity:SetColor(item:GetColor())
			-- end
			
			self.selectedMdl:SetMaterial(getmat(item))
			
			self.selectedMdl:SetSize(400,400)
			self.selectedMdl:Center()
			-- self.selectedMdl.pitch = math.random(-35,35)
			
			self.selectedName:SetText(item.PrintName and language.GetPhrase(item.PrintName) or language.GetPhrase(item:GetClass()))
			self.selectedName:SizeToContents()
			self.selectedName:CenterHorizontal()
			
			self.selectedDesc:Update(item)
		end
		
	end
	
	function radial:OnMouseWheeled(delta)
		if delta < 0 then
			self:RunCommand("invprev")
		else
			self:RunCommand("invnext")
		end
	end
	
	local curslot,curslotpos = 0,0
	function radial:RunCommand(bind)
		local max = #self.weapons
		if max < 0 then return end
		
		if bind == "invnext" then
			local cur = self.selected or 0
			if cur < 1 then
				cur = max
			end
			self:SelectItem(cur)
			
		elseif bind == "invprev" then
			local cur = self.selected or 0
			if cur >= max-1 then
				cur = -1
			end
			self:SelectItem(cur+2)
			
		elseif bind:find("slot") then
			local slot = tonumber(bind:sub(5))
			local tbl = self.slotted[slot]
			local max = #tbl
			
			//Get offset of this slot
			local offset = 0
			for i=1, slot-1 do
				offset = offset + #self.slotted[i]
			end
			
			//Change slots
			if slot != curslot then
				curslot = slot
				curslotpos=0
			end
			
			//Loop around
			curslotpos = curslotpos + 1
			if curslotpos > max then
				curslotpos = 1
			end
			
			self:SelectItem(offset + curslotpos)
			
		elseif bind == "+attack" then
			self:Close()
		end
	end
	
	function radial:Close( auto )
		
		if self.selected and IsValid(self.weapons[self.selected+1]) then
			if (auto and autopick:GetBool()) or !auto then
				PickWeapon(self.weapons[self.selected+1]:GetClass())
			end
		end
		
		//Sounds
		if wsel.premium then
			wsel.slow_in:Pause()
			wsel.slow_in:SetTime(0)
			timer.Simple(1,function()
				wsel.heartbeat:Pause()
				wsel.heartbeat:SetTime(0)
			end)
			wsel.slow_out:Play()
		end
		
		//Remove elements
		self.invert = true
		self.ctime = RealTime()
		timer.Simple(.1,function()
			if IsValid(self) then
				for k,v in pairs(self.previews)do
					v:Remove()
				end
			end
		end)
		self.selectedMdl:SetVisible(false)
		self.selectedName:SetVisible(false)
		self.selectedDesc:SetVisible(false)
		self.settings:SetVisible(false)
		
		timer.Simple(.8, function() if IsValid(self) then self:Remove() end end)
		if wsel.premium then
			net.Start("inv_open")
				net.WriteBit(00)
			net.SendToServer()
		end
	end
	
	
	//Set cursor of all children too
	radial.oldsetcur = radial.SetCursor
	function radial:SetCursor(new) 
		if self.cursor == new then return end
		self.cursor = new
		self:oldsetcur(new)
		for k,v in pairs(self:GetChildren())do
			v:SetCursor(new)
		end
	end
	
	function radial:Think()
		local delay = closedelay:GetFloat()
		if delay > 0 then
			if not input.IsKeyDown(_G["KEY_"..key:GetString():upper()]) and not self.invert then
				if RealTime() > self.lastact + delay then
					self:Close(!self.noauto)
				end
			end
		end
		
		//Fade in/out heartbeat
		if wsel.premium then
			local animtime = 1
			local dtime = RealTime() - self.ctime
			local lerp = self.invert and Lerp(dtime/animtime,1,0) or Lerp(dtime/animtime,0,1)
			wsel.heartbeat:SetVolume( lerp )
		end
		
		self:SetMouseInputEnabled(!self.invert and input.IsKeyDown(_G["KEY_"..key:GetString():upper()]))
	end
	
	//Create model previews on slices
	radial.previews = {}
	function radial:Update()
		//Clear old
		-- self.selected = nil
		for k,v in pairs(self.previews) do v:Remove() end
		
		//Generate weapons tables.
		local weps, slotted, held = generateWeaponTables(LocalPlayer())
		self.weapons = weps or {}
		self.slotted = slotted
		
		self:SelectItem(held)
		
		//Create new
		for id, item in ipairs(self.weapons) do
			if item:GetModel() then
				local model = vgui.Create("DImage",self)
				-- model:SetModel(item:GetModel())
				-- if model.Entity then
					-- model.Entity:SetSkin(item:GetSkin())
				
					-- model.Entity:SetMaterial(item:GetMaterial())
					-- model.Entity:SetColor(item:GetColor())
				-- end
				
				model:SetMaterial(getmat(item))
				
				local pw,ph = 5,5
				model:SetPos(ScrW()/2-pw/2,ScrH()/2-ph/2)
				model:SetSize(pw,ph)
				-- model.pitch = math.random(-35,35)
				model:SetPaintedManually(true)
				
				-- function model:LayoutEntity(ent)
					-- ent:SetModelScale(1*(item.ModelScale or 1),0)
					-- if ( self.bAnimated ) then
						-- self:RunAnimation()
					-- end
					-- ent:SetAngles( Angle( self.pitch, (RealTime()+id)*10,  0) )
					-- ent:SetPos( Vector(0,0,34) )
				-- end
				function model:OnMousePressed(mc)
					radial:OnMousePressed(mc)
				end
				model.item = item
				
				self.previews[id] = model
			end
		end
	end
	radial:Update()
	
end

function wsel.CloseWepSelect()
	if IsValid(g_WepSelect) and !g_WepSelect.invert then
		g_WepSelect:Close()
	end
end


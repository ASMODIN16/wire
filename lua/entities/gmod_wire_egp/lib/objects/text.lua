-- Author: Divran
local Obj = EGP:NewObject( "Text" )
Obj.h = nil
Obj.w = nil
Obj.text = ""
Obj.fontid = 1
Obj.size = 18
Obj.valign = 0
Obj.halign = 0
Obj.angle = 0

local surface_SetTextPos
local surface_DrawText
local surface_SetTextColor
local surface_CreateFont
local surface_SetFont
local surface_GetTextSize
local cam_PushModelMatrix
local cam_PopModelMatrix
local mat = Matrix()
local matAng = Angle(0, 0, 0)
local matTrans = Vector(0, 0, 0)
local matScale = Vector(0, 0, 0)

if CLIENT then
	surface_SetTextPos = surface.SetTextPos
	surface_DrawText = surface.DrawText
	surface_SetTextColor = surface.SetTextColor
	surface_CreateFont = surface.CreateFont
	surface_SetFont = surface.SetFont
	surface_GetTextSize = surface.GetTextSize


	-- Thanks to Wizard for this rotateable text code
	cam_PushModelMatrix = cam.PushModelMatrix
	cam_PopModelMatrix = cam.PopModelMatrix
	mat = Matrix()
	mat:Scale(Vector(1, 1, 1))
	matAng = Angle(0, 0, 0)
	matTrans = Vector(0, 0, 0)
end

Obj.Draw = function( self )
	if (self.text and #self.text>0) then
		surface_SetTextColor( self.r, self.g, self.b, self.a )

		if (!EGP.ValidFonts[self.fontid]) then self.fontid = 1 end
		local font = "WireEGP_" .. self.size .. "_" .. self.fontid
		if (!EGP.ValidFonts_Lookup[font]) then
			surface_CreateFont( EGP.ValidFonts[self.fontid], self.size, 800, true, false, font )
			EGP.ValidFonts[#EGP.ValidFonts+1]= font
			EGP.ValidFonts_Lookup[font] = true
		end
		surface_SetFont( font )

		if self.angle == 0 then
			local w,h
			local x, y = self.x, self.y
			if (self.halign != 0) then
				w,h = surface_GetTextSize( self.text )
				x = x - (w * ((self.halign%10)/2))
			end
			if (self.valign) then
				if (!h) then _,h = surface_GetTextSize( self.text ) end
				y = y - (h * ((self.valign%10)/2))
			end

			surface_SetTextPos( x, y )
			surface_DrawText( self.text )
		else
			local w,h
			local x, y = 0,0
			if (self.halign != 0) then
				w,h = surface_GetTextSize( self.text )
				x = (w * ((self.halign%10)/2))
			end
			if (self.valign) then
				if (!h) then _,h = surface_GetTextSize( self.text ) end
				y = (h * ((self.valign%10)/2))
			end

			-- Thanks to Wizard for the base to this rotateable text code. I edited it a bit to properly support alignment
			matAng.y = self.angle
			mat:SetAngle(matAng)
			matTrans.x = x
			matTrans.y = y
			matTrans:Rotate(matAng)
			mat:SetTranslation(Vector(self.x,self.y,0)-matTrans)
			surface_SetTextPos(0, 0)
			cam_PushModelMatrix(mat)
				surface_DrawText( self.text )
			cam_PopModelMatrix()
		end
	end
end
Obj.Transmit = function( self, Ent, ply )
	EGP.umsg.Short( self.x )
	EGP.umsg.Short( self.y )
	EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", self.index, self.text )
	EGP.umsg.Char( self.fontid-128 )
	EGP.umsg.Char( math.Clamp(self.size,0,128)-128 )
	EGP.umsg.Char( math.Clamp(self.valign,0,2) )
	EGP.umsg.Char( math.Clamp(self.halign,0,2) )
	EGP.umsg.Short( self.parent )
	EGP:SendColor( self )
	EGP.umsg.Short((self.angle%360)*20)
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.x = um:ReadShort()
	tbl.y = um:ReadShort()
	tbl.fontid = um:ReadChar()+128
	tbl.size = um:ReadChar()+128
	tbl.valign = um:ReadChar()
	tbl.halign = um:ReadChar()
	tbl.parent = um:ReadShort()
	EGP:ReceiveColor( tbl, self, um )
	tbl.angle = um:ReadShort()/20
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, valign = self.valign, halign = self.halign, size = self.size, r = self.r, g = self.g, b = self.b, a = self.a, text = self.text, fontid = self.fontid, parent = self.parent, angle = self.angle }
end

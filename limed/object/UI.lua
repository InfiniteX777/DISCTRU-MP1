local min,floor,ceil = math.min,math.floor,math.ceil

local game = Instance:service"GameInterface"
local content = Instance:service"ContentService"
local graphics = Instance:service"GraphicsInterface"
local input = Instance:service"UserInput"

local function setAbs(self,rect)
	local a = self.offset.position+self.scale.position*self.__abs.size+self.__abs.position
	local b = self.offset.size+self.scale.size*self.__abs.size
	local r = self.offset.rotation-self.scale.rotation+self.__abs.rotation

	rect:set(
		a.x,
		a.y,
		b.x,
		b.y,
		r
	)
end

local function doScissor(self)
	local d = self.abs.rotation == 0 and self.wrap

	if d then
		local a,b = self.abs.position,self.abs.size
		graphics:pushScissor(a.x,a.y,b.x,b.y)
	end

	return d
end

local function drawUI(self,...)
	local d = doScissor(self)

	for _,v in self.layer:ipairs() do
		for _,v in v:ipairs() do
			v:draw(...)
		end
	end

	if d then
		graphics:popScissor()
	end
end

local UI = Instance:class("UI",3){
	parent = nil,
	selected = nil,
	layer = SkipList:new(),
	offset = Rect:new(),
	scale = Rect:new(),
	abs = Rect:new(),
	__abs = Rect:new(0,0,love.graphics.getDimensions()),
	visible = true,
	__visible = true,
	active = true,
	__active = true,
	wrap = false,
	hover = false,
	drag = false,
	draggable = false,
	new = function(self,super)
		game.gameResize:connect(function(w,h)
			if not self.parent then
				self.__abs:set(0,0,w,h)
				setAbs(self,self.abs)
			end
		end)

		input.mouseMoved:connect(function(x,y,dx,dy,...)
			local selected = self:getSelected()

			if self:isActive() then
				local layer = self:getLayer()
				local a,b = self.abs.position,self.abs.size

				if self.drag then
					self:setOffset(self.offset.x+dx,self.offset.y+dy)
				end

				if x >= a.x and x <= a.x+b.x and y >= a.y and y <= a.y+b.y and
				   (not selected or
				    selected == self or
					self:descendantOf(selected) or
					(layer and selected:getLayer() < layer)) then
					self:setSelected(self)

					if self.hover then
						self.mouseMoved:fire(x,y,dx,dy,...)
					else self.hover = true
						self.mouseEntered:fire(x,y,dx,dy,...)
					end

					return
				end
			end

			if self.hover then
				self.hover = false
				self.mouseLeave:fire(x,y,...)

				if selected == self then
					self:setSelected()
				end
			end
		end)
		input.mouseDown:connect(function(...)
			if self.hover and self:getSelected() == self then
				if self.draggable then
					self.drag = true
				end

				self.mouseDown:fire(...)
			end
		end)
		input.mouseUp:connect(function(...)
			self.drag = false

			if self.hover and self:getSelected() == self then
				self.mouseUp:fire(...)
			end
		end)
		input.mouseWheel:connect(function(...)
			if self.hover and self:getSelected() == self then
				self.mouseWheel:fire(...)
			end
		end)
	end,
	getSelected = function(self,super)
		return self.parent and self.parent:getSelected() or self.selected
	end,
	setSelected = function(self,super,ui)
		if self.parent then
			self.parent:setSelected(ui)
		else self.selected = ui
		end
	end,
	getLayer = function() return end,
	setLayer = function(self,super,layer)
		local parent = self.parent

		if not parent then return end
		-- Not in a group.

		local prev = self:getLayer()
		if prev then
			parent.layer[prev].value:remove(self)
		end

		if not parent.layer[layer] then
			parent.layer:insert(SkipList:new(),layer)
		end

		parent.layer[layer].value:insert(self)

		self.getLayer = function()
			return layer
		end
	end,
	add = function(self,super,ui,layer,up,down,left,right)
		if ui:is("UI") then
			local layer = layer or 1

			ui.parent = self
			ui.up = up
			ui.down = down
			ui.left = left
			ui.right = right

			ui:setLayer(layer)
			setAbs(ui,ui.abs)
		end
	end,
	rem = function(self,super,ui)
		if ui:descendantOf(self) then
			self.layer[ui:getLayer()].value:remove(ui)

			ui.parent = nil
			ui.getLayer = nil
		end
	end,
	isActive = function(self,super)
		if not self.__active then
			return false
		end

		return self.active
	end,
	isVisible = function(self,super)
		if not self.__visible then
			return false
		end

		return self.visible
	end,
	setOffset = function(self,super,...)
		self.offset:set(...)
		setAbs(self,self.abs)
	end,
	setScale = function(self,super,...)
		self.scale:set(...)
		setAbs(self,self.abs)
	end,
	descendantOf = function(self,super,ui)
		return self.parent and (self.parent == ui or self.parent:descendantOf(ui))
	end,
	ancestorOf = function(self,super,ui)
		return ui.parent and (ui.parent == self or self:ancestorOf(ui.parent))
	end,
	update = function(self,super,dt)
		local parent = self.parent
		if parent then
			if self.__abs ~= parent.abs then
				self.__abs = parent.abs:clone()
				setAbs(self,self.abs)
			end

			self.__active = self.parent:isActive()
		end

		for _,v in self.layer:ipairs() do
			for _,v in v:ipairs() do
				v:update(dt)
			end
		end
	end,
	draw = function(self,super,...)
		if not self.visible then return end

		drawUI(self,...)
	end,
	destroy = function(self,super)
		local selected = self:getSelected()
		if selected and (selected == self or selected:descendantOf(self)) then
			self:setSelected()
		end

		if self.parent then
			self.parent:rem(self)
		end

		for _,v in self.layer:ipairs() do
			for _,v in v:ipairs() do
				self:rem(v)
				v:destroy()
			end
		end

		super.destroy(self)
	end,
	mouseEntered = Instance:event(),
	mouseMoved = Instance:event(),
	mouseLeave = Instance:event(),
	mouseDown = Instance:event(),
	mouseUp = Instance:event(),
	mouseWheel = Instance:event()
}

local function drawFrame(self,x,y,angle,sx,sy,...)
	local x,y,angle,sx,sy = x or 0, y or 0,angle or 0,sx or 1,sy or 1
	local a,b,r = self.abs.position,self.abs.size,self.abs.rotation+angle
	local image = self.image

	love.graphics.push()
	love.graphics.translate(x+a.x+b.x/2,y+a.y+b.y/2)
	love.graphics.rotate(r)
	love.graphics.translate(-b.x/2,-b.y/2)
	love.graphics.scale(sx,sy)

	if self.fillColor.a > 0 then
		graphics:pushColor(self.fillColor:components())

		love.graphics.rectangle("fill",0,0,b.x,b.y)

		graphics:popColor()
	end

	if self.lineColor.a > 0 then
		graphics:pushColor(self.lineColor:components())

		love.graphics.rectangle("line",0,0,b.x,b.y)

		graphics:popColor()
	end

	if image then
		image:draw(
			0,
			0,
			0,
			b.x/image.width,
			b.y/image.height
		)
	end

	love.graphics.pop()
end

local Frame = UI:class("Frame",3){
	fillColor = Color:new(255,255,255),
	lineColor = Color:new(),
	image = nil,
	update = function(self,super,dt)
		local image = self.image

		if image then
			image:update(dt)
		end

		super.update(self,dt)
	end,
	draw = function(self,super,...)
		if not self.visible then return end

		drawFrame(self,...)
		drawUI(self,...)
	end
}

local function drawBorderedFrame(self,x,y,angle,sx,sy,...)
	local atlas = self.borderAtlas
	if atlas then
		local x,y,angle,sx,sy,ox,oy = x or 0,y or 0,angle or 0,sx or 1,sy or 1,ox or 0,oy or 0
		local a,b,r = self.abs.position,self.abs.size,self.abs.rotation+angle
		x,y,ox,oy = x+a.x+b.x/2*sx,y+a.y+b.y/2*sy,ox+b.x/2,oy+b.y/2

		love.graphics.draw(atlas,x,y,r,sx,sy,ox,oy,...)
	end
end

local BorderedFrame = Frame:class("BorderedFrame",3){
	borderImage = nil,
	borderAtlas = nil,
	borderSize = nil,
	borderEdgeSize = 8,
	borderEdgeStyle = "stretch",
	borderBodyStyle = "stretch",
	update = function(self,super,dt)
		super.update(self,dt)

		local image = self.borderImage

		if image then
			if not self.borderAtlas then
				self.borderAtlas = love.graphics.newSpriteBatch(image.image)
			end

			local atlas = self.borderAtlas
			if atlas:getTexture() ~= image.image then
				atlas:setTexture(image.image)
			end

			local b = self.abs.size
			local size = self.borderEdgeSize
			if not self.borderSize or self.borderSize ~= b then
				self.borderSize = b
				atlas:clear()

				-- Corners (Topleft, Topright, Bottomleft, Bottomright)
				atlas:add(
					image:get(0,0,size,size),
					0,0
				)
				atlas:add(
					image:get(image.width-size,0,size,size),
					b.x-size,0
				)
				atlas:add(
					image:get(0,image.height-size,size,size),
					0,b.y-size
				)
				atlas:add(
					image:get(image.width-size,image.height-size,size,size),
					b.x-size,b.y-size
				)

				-- Edges (Top, Bottom, Left, Right)
				local edge = Vector2:new(image.height,image.width)-size*2
				if self.borderEdgeStyle == "stretch" then
					atlas:add(
						image:get(size,0,edge.x,size),
						size,0,0,(b.x-size*2)/edge.x,1
					)
					atlas:add(
						image:get(size,image.height-size,edge.x,size),
						size,b.y-size,0,(b.x-size*2)/edge.x,1
					)
					atlas:add(
						image:get(0,size,size,edge.y),
						0,size,0,1,(b.y-size*2)/edge.y
					)
					atlas:add(
						image:get(image.width-size,size,size,edge.y),
						b.x-size,size,0,1,(b.y-size*2)/edge.y
					)
				elseif self.borderEdgeStyle == "tile" then
					local len = b-size*2
					for i=0,ceil(len.x/edge.x)-1 do
						local width = min(edge.x,len.x)

						atlas:add(
							image:get(size,0,width,size),
							size+i*edge.x,0,0,1,1
						)
						atlas:add(
							image:get(size,image.height-size,width,size),
							size+i*edge.x,b.y-size,0,1,1
						)

						len.x = len.x-edge.x
					end

					for i=0,ceil(len.y/edge.y)-1 do
						local height = min(edge.y,len.y)

						atlas:add(
							image:get(0,size,size,height),
							0,size+i*edge.y,0,1,1
						)
						atlas:add(
							image:get(image.width-size,size,size,height),
							b.x-size,size+i*edge.y,0,1,1
						)

						len.y = len.y-edge.y
					end
				end

				-- Center
				if self.borderBodyStyle == "stretch" then
					atlas:add(
						image:get(size,size,edge.x,edge.y),
						size,
						size,
						0,
						(b.x-size*2)/(image.width-size*2),
						(b.y-size*2)/(image.height-size*2)
					)
				elseif self.borderBodyStyle == "tile" then
					local len = b-size*2
					local mx,my = ceil(len.x/edge.x)-1,ceil(len.y/edge.y)-1

					for y=0,my do
						for x=0,mx do
							atlas:add(
								image:get(
									size,
									size,
									min(edge.x,len.x-x*edge.x),
									min(edge.y,len.y-y*edge.y)
								),
								size+x*edge.x,
								size+y*edge.y,
								0,
								1,
								1
							)
						end
					end
				end

				atlas:flush()
			end
		end
	end,
	draw = function(self,super,...)
		if not self.visible then return end

		drawFrame(self,...)
		drawBorderedFrame(self,...)
		drawUI(self,...)
	end
}

local function drawBorderedIcon(self,image,x,y,angle,sx,sy,...)
	if image then
		image:draw(x,y,r,sx,sy,...)
	end
end

local BorderedIcon = Frame:class("BorderedIcon",3){
	backgroundImage = nil,
	maskImage = nil,
	update = function(self,super,dt)
		for _,v in pairs{"background","mask"} do
			local image = self[v.."Image"]

			if image then
				image:update(dt)
			end
		end

		super.update(self,dt)
	end,
	draw = function(self,super,x,y,angle,sx,sy,...)
		if not self.visible then return end

		local image = self.backgroundImage

		local angle,sx,sy = angle or 0,sx or 1,sy or 1
		local a,b,r = self.abs.position,self.abs.size,self.abs.rotation+angle
		a = a:rotate(-b/2,-r)

		drawBorderedIcon(self.backgroundImage,x+a.x,y+a.y,r,sx,sy,...)
		drawFrame(self,...)
		drawBorderedIcon(self.maskImage,x+a.x,y+a.y,r,sx,sy,...)
		drawUI(self,...)
	end,
}

local function drawLabel(self,text,x,y,angle,sx,sy,...)
	local angle,sx,sy = angle or 0,sx or 1,sy or 1
	local a,b,r = self.abs.position,self.abs.size,self.abs.rotation+angle

	self.font.text = text
	self.font.align = self.textAlign
	self.font.wrap = self.textWrap and b.x or nil

	local ox,oy = unpack(content.fontAlignment[self.textAlign])
	local pos = (a+b*Vector2:new(self.textWrap and 0 or ox,oy)):rotate(a+b/2,r)

	local d = doScissor(self)

	self.font:draw(x+pos.x*sx,y+pos.y*sy,r,sx,sy,...)

	if d then
		graphics:popScissor()
	end
end

local Label = Frame:class("Label",3){
	text = ColoredText:new(),
	textSpeed = 0,
	textIndex = 0,
	textAlign = "topleft",
	textWrap = false,
	font = content:loadFont(),
	setText = function(self,super,text,speed)
		self.text:set(text)
		self.textSpeed = speed
		self.textIndex = 0
	end,
	getVisibleText = function(self,super)
		return self.textSpeed > 0 and self.text:cut(1,floor(self.textIndex)) or self.text
	end,
	update = function(self,super,dt)
		if self.textSpeed > 0 then
			self.textIndex = min(self.textIndex+self.textSpeed*dt,self.text.abs:len())
		end

		super.update(self,dt)
	end,
	draw = function(self,super,...)
		if not self.visible then return end

		drawFrame(self,...)
		drawLabel(self,self:getVisibleText(),...)
		drawUI(self,...)
	end
}

local TextBox = Frame:class("TextBox",3){
	text = "",
	textColor = Color:new(),
	textAlign = "topleft",
	textWrap = false,
	font = content:loadFont(),
	focusPosition = 0,
	focusBlink = 1,
	focusBlinkTimer = 0,
	focusColor = Color:new(0,0,0),
	resetOnFocus = true,
	multiLine = false,
	emptyText = "",
	new = function(self,super)
		super.constructor(self)

		self.mouseDown:connect(function()
			if not self:isFocused() then
				self:setFocus()
			end
		end)
	end,
	isFocused = function(self,super)
		return game.focus == self
	end,
	setFocus = function(self,super)
		if self.resetOnFocus then
			self.focusPosition = 0
			self.focusBlinkTimer = 0
			self.text = ""
		end

		game:setFocus(self)
	end,
	releaseFocus = function(self,super)
		if self:isFocused() then
			game:releaseFocus()
		end
	end,
	update = function(self,super,dt)
		super.update(self,dt)

		if self:isFocused() then
			self.focusPosition = math.max(0,math.min(self.focusPosition,self.text:len()))
			self.focusBlinkTimer = (self.focusBlinkTimer+dt)%self.focusBlink
		end
	end,
	draw = function(self,super,...)
		if not self.visible then return end
		local txt = self.text

		if self:isFocused() then
			if self.focusBlinkTimer <= self.focusBlink/2 then
				txt = txt:sub(1,txt:len()-self.focusPosition).."|"..
					txt:sub(txt:len()-self.focusPosition+1,txt:len())
			end
		elseif txt:len() == 0 then
			txt = self.emptyText
		end

		local c = self.textColor

		drawFrame(self,...)
		drawLabel(
			self,
			ColoredText:new(string.format("#%02X%02X%02X ",c.r,c.g,c.b)..txt),
			...
		)
		drawUI(self,...)
	end,
	textBoxFocused = Instance:event(),
	textBoxReleased = Instance:event(),
}

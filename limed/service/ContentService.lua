local ceil,floor,rad = math.ceil,math.floor,math.rad
local insert = table.insert

local cache = {
	Image = {},
	Font = {}
}

local ContentService = Instance:class("ContentService",2){
	fontAlignment = {
		topleft = {0,0,"left"},
		middleleft = {0,0.5,"left"},
		bottomleft = {0,1,"left"},
		topcenter = {0.5,0,"center"},
		middlecenter = {0.5,0.5,"center"},
		bottomcenter = {0.5,1,"center"},
		topright = {1,0,"right"},
		middleright = {1,0.5,"right"},
		bottomright = {1,1,"right"}
	},
	loadImage = function(self,super,source)
		if not cache.Image[source] then
			local image = love.graphics.newImage(source)

			if not image then return end

			cache.Image[source] = self:new("Image",function(self)
				self.image = image
				self.width = self.image:getWidth()
				self.height = self.image:getHeight()
			end)
		end

		return cache.Image[source]
	end,
	loadFont = function(self,super,source,size)
		local source = source or "default"
		local size = size or 12
		local t = lemon.table.init(cache,"Font",size)
		if not t[source] then
			if source == "default" then
				t[source] = self:new("FontAsset",function(self)
					self.font = love.graphics.newFont(size)
				end)
			else t[source] = self:new("FontAsset",function(self)
					self.font = love.graphics.newFont(source,size)
				end)
			end
		end

		return t[source]
	end,
	resetFont = function(self,super,size)
		love.graphics.setFont(self:loadFont().font)
	end
}

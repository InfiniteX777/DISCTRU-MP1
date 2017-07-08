local game = Instance:class("GameInterface",2){
	scale = 1,
	angle = 0,
	ui = nil,
	focus = nil,
	window = Vector2:new(love.graphics.getDimensions()),
	showStats = false,
	time = 0,
	quitCallback = function() end,
	setQuitCallback = function(self,super,callback)
		self.quitCallback = callback
	end,
	releaseFocus = function(self,super,enterPressed)
		local focus = self.focus

		if focus then
			self.focus = nil

			love.keyboard.setKeyRepeat(false)
			focus.textBoxReleased:fire(enterPressed or false)
		end
	end,
	setFocus = function(self,super,textBox)
		self:releaseFocus()
		self.focus = textBox

		if textBox and textBox:is("TextBox") then
			love.keyboard.setKeyRepeat(true)
			textBox.textBoxFocused:fire()
		end
	end,
	gameResize = Instance:event(),
	gameUpdate = Instance:event(),
	gameDraw = Instance:event(),
	gameQuit = Instance:event()
}

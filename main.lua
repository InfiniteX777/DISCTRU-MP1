require "conf"
require "limed.init"

-- Variables
local floor,max,min = math.floor,math.max,math.min
local insert,concat,sort = table.insert,table.concat,table.sort

local game = Instance:service"GameInterface"
local input = Instance:service"UserInput"
local graphics = Instance:service"GraphicsInterface"
local content = Instance:service"ContentService"

local sets = {}
local setCount = 0
local chat = {}
local chatOffset = 0
local chatSize = 21
local scrollOffset = 0
local scrollAbsOffset = 0
local chatFont = content:loadFont("assets/segoe-ui-light.ttf",16)
local boxFont = content:loadFont("assets/segoe-ui-light.ttf",18)
local root,frame
local hash

--[[
Converts string into table. This only captures integers and will still continue even with ugly syntax.

@param	String txt Reference.
@param	Boolean strict=false If true, returns nil if the reference has ugly syntax or contains non-integers.
@return A table if valid syntax, otherwise nil.
]]
function convert(txt,strict)
	local t = {}
	local hash = {} -- Debounce.

	if txt == "{}" then
		return t -- Return the table already if just empty.
	end

	if strict and not (txt:sub(1,1) == "{" and txt:sub(txt:len()) == "}") then
		return -- Ugly syntax (not in eclosed curly braces).
	end

	if txt:sub(1,1) == "{" then
		txt = txt:sub(2) -- Get rid of the first curly brace.
	end

	-- For each regex capture (All characters before a comma or a closing curly brace).
	for v in txt:gmatch(".-[,}]") do
	    v = tonumber(v:sub(1,v:len()-1))
	    -- Get the number value and remove the preceding character (comma or curly brace).

	    if v and floor(v) == v then
	    	if not hash[v] then
	    		hash[v] = true -- Store to hash.

	        	table.insert(t,v)
			end
	    elseif strict then
	    	return -- Ugly syntax (Not an integer).
	    end
	end

	pcall(sort,t)

	return t -- Success.
end

--[[
Combines two sets. Only 1 per element will be added.

@param	Table a First table.
@param	Table b Second table.
@return a and b combined.
]]
function union(a,b)
	local t = {}
	local hash = {} -- Debounce.

	-- Hacky shortening.
	local function push(v)
	    if v and not hash[v] then
	    	table.insert(t,v)
	    	hash[v] = true
		end
	end

	for i=1,#a > #b and #a or #b do
	    push(a[i])
	    push(b[i])
	end

	pcall(sort,t)

	return t
end

--[[
Returns all the elements existing both on two sets.

@param	Table a First table.
@param	Table b Second table.
@return Set of intersected elements.
]]
function intersect(a,b)
	local t = {}

	for _,k in pairs(a) do
	    for _,v in pairs(b) do
	    	if k == v then
	        	table.insert(t,k)
	        	break
	    	end
		end
	end

	return t
end

--[[
Returns all the elements in table a that cannot be found in table b.

@param	Table a First table.
@param	Table b Second table.
@return Table a-b.
]]
function difference(a,b)
	local t = {unpack(a)} -- Get a clone of the table.

	for _,k in pairs(b) do
    	for i,v in pairs(t) do
    		if k == v then
	    		table.remove(t,i)
	        	break
	    	end
		end
	end

	return t
end

--[[
Returns all possible combinations between a and b through cartesian product.

@param	Table a First table.
@param	Table b Second table.
@return a x b.
]]
function product(a,b)
    local t = {}

    for _,k in pairs(a) do
    	for _,v in pairs(b) do
        	table.insert(t,{k,v})
    	end
    end

    return t
end

--[[
Returns all possible subsets that the table can create. Does not include the null terminator.

@param	Table a The table.
@return A table of subsets.
]]
function power(a)
    local set = {}

    for i=0,2^#a-1 do
        local step = #a
        local subset = {}
        while i > 0 do
            local d = i%2
            if d == 1 then
                table.insert(subset,1,a[step])
            end
            i = (i-d)/2
            step = step-1
        end

        table.insert(set,subset)
    end

    return set
end

function write(...)
	for _,txt in pairs({...}) do
		local _,length = chatFont.font:getWrap(txt:gsub("#%x%x%x%x%x%x%s",""),340)
		length = #length

		local label = Instance:new("Label",function(self)
			self.font = chatFont
			self.fillColor.a = 0
			self.lineColor.a = 0
			self.textAlign = "topleft"
			self.textWrap = true

			self:setText(txt,math.max(64,math.floor(txt:len()/2)))
			self:setOffset(10,chatOffset,340,length*chatSize)

			insert(chat,self)
			frame:add(self)
		end)

		chatOffset = chatOffset+length*chatSize

		if chatOffset-560 > 0 and -scrollOffset >= chatOffset-560-length*chatSize then
			scrollOffset = 560-chatOffset
		end
	end
end

function readTable(t,colored)
	colored = (colored == nil or colored) and #t <= 256
	local txt = colored and "#FF0000 { #000000 " or "{ "

	for i,v in pairs(t) do
		if type(v) == "table" then
			txt = txt..readTable(v,colored)
		else txt = txt..v
		end

		if t[i+1] then
			txt = txt..(colored and "#FF0000 , #000000 " or ", ")
		end
	end

	txt = txt..(colored and " #FF0000 }" or " }")

	return colored and txt or "#000000 "..txt
end

function getSets(txt,operator)
	local _,_,a,b = txt:find(operator.."%((.-),%s?(.-)%)")

	if sets[a] then
		if sets[b] then
			return a,b
		else write("#000000 I'm sorry, #FF0000 "..b.." #000000 doesn't exist...")
		end
	else write("#000000 I'm sorry, #FF0000 "..a.." #000000 doesn't exist...")
	end
end

function response(txt)
	if txt:lower() == "/stats" then
		game.showStats = not game.showStats
	elseif txt:lower() == "/about" then
		write(
			"#000000 Author: #FF0000 Michael Edmund Wong",
			"#000000 Created: #FF0000 7/4/17",
			"#000000 Last Modified: #FF0000 7/8/17",
			"#000000 Engine: #FF0000 Love2D",
			"#000000 Modules:",
			"	#FF0000 limed #000000 by #FF0000 Michael Edmund Wong",
			"#000000 Update Log:",
			"	#FF0000 7/8",
			"		#000000 - Added #FF0000 /about #000000 command.",
			"		#000000 - Added scroll functionality.",
			"		#000000 - Added #FF0000 /stats #000000 command.",
			"		#000000 - Added #FF0000 /about #000000 command.",
			"		#000000 - Added #FF0000 /delete #000000 command.",
			"		#000000 - Fixed typos in #FF0000 /help #000000 and #FF0000 /save #000000 .",
			"		#000000 - function #FF0000 readTable #000000 now only adds colors if the total length does not exceed 256 elements.",
			"	#FF0000 7/7",
			"		#000000 - Added #FF0000 /save #000000 command.",
			"		#000000 - You can now call existing sets to display their elements.",
			"		#000000 - Typing #FF0000 # #000000 before the variable name will show their total number of elements.",
			"		#000000 - Added all operators.",
			"		#000000 - Added #FF0000 readTable #000000 function.",
			"		#000000 - Added commands.",
			"	#FF0000 7/6",
			"		#000000 - You can now create sets by typing #0000FF myVar #FF0000 = {}#000000 .",
			"	#FF0000 7/4",
			"		#000000 - Created."
		)
	elseif txt:lower() == "/help" then
		write(
			"#000000 Create sets by typing #0000FF variable #FF0000 = {#000000 1#FF0000 ,#000000 2#FF0000 ,#000000 3#FF0000 }",
			"#000000 Type #FF0000 /sets #000000 to list down all created sets.",
			"#000000 Type #FF0000 /clear #000000 to clear the chat box. This does not clear all your sets!",
			"#000000 Type in your set variable name like #0000FF myVar #000000 to check its contents.",
			"#000000 Type #FF0000 U(#0000FF SetA#FF0000 ,#0000FF SetB#FF0000 ) #000000 to use the union operator.",
			"#000000 Type #FF0000 I(#0000FF SetA#FF0000 ,#0000FF SetB#FF0000 ) #000000 to use the intersect operator.",
			"#000000 Type #FF0000 D(#0000FF SetA#FF0000 ,#0000FF SetB#FF0000 ) #000000 to use the difference operator.",
			"#000000 Type #FF0000 C(#0000FF SetA#FF0000 ,#0000FF SetB#FF0000 ) #000000 to use the cartesian product operator.",
			"#000000 Type #FF0000 P(#0000FF SetA#FF0000 ) #000000 to use the power operator.",
			"#000000 If you've used one of the operators, you can save the table by typing #FF0000 /save #0000FF myVar#000000 ."
		)
	elseif txt:lower() == "/sets" then
		if setCount > 0 then
			for k,v in pairs(sets) do
				write(readTable(v))
			end
		else write(
				"#000000 You have no sets!",
				"#000000 Start creating one by typing #0000FF variable #FF0000 = {}#000000 ."
			)
		end
	elseif txt:lower() == "/clear" then
		for _,v in pairs(chat) do
			v:destroy()
		end

		chatOffset = 0
		scrollOffset = 0
		scrollAbsOffset = 0

		write("#000000 Type #FF0000 /help #000000 for info.")
	elseif txt:lower():match("^/save") then
		if hash then
			local var = txt:match("%s(.-)$")

			if var then
				if not sets[var] then
					sets[var] = hash
					hash = nil

					write("#000000 Set successfully saved as #0000FF "..var.."#000000 .")
				else write("#000000 Whoops! It looks like that variable name is already being used!")
				end
			else write("#000000 You need to type in a variable name to save it. Maybe try typing #FF0000 /save #0000FF myVar#000000 .")
			end
		else write("#000000 I'm sorry, it looks like there's nothing to save... Try using the operators on existing sets!")
		end
	elseif txt:lower():match("^/delete") then
		local var = txt:match("%s(.-)$")

		if var then
			if sets[var] then
				sets[var] = nil
				setCount = setCount-1

				write("#FF0000 "..var.." #000000 has been deleted.")
			else write("#000000 It doesn't seem like that variable name exists...")
			end
		else write("#000000 You need to at least type in the variable name to delete a set!")
		end
	elseif txt:match("U%(.-,.-%)") then
		local a,b = getSets(txt,"U")

		if a then
			local t = union(sets[a],sets[b])

			hash = t

			write(readTable(t))
		end
	elseif txt:match("I%(.-,.-%)") then
		local a,b = getSets(txt,"I")

		if a then
			local t = intersect(sets[a],sets[b])

			hash = t

			write(readTable(t))
		end
	elseif txt:match("D%(.-,.-%)") then
		local a,b = getSets(txt,"D")

		if a then
			local t = difference(sets[a],sets[b])

			hash = t

			write(readTable(t))
		end
	elseif txt:match("C%(.-,.-%)") then
		local a,b = getSets(txt,"C")

		if a then
			local t = product(sets[a],sets[b])

			hash = t

			write(readTable(t))
		end
	elseif txt:match("P%(.-%)") then
		local _,_,a = txt:find("P%((.-)%)")

		if sets[a] then
			local t = power(sets[a])

			hash = t

			write(readTable(t))
		else write("#000000 I'm sorry, #FF0000 "..a.." #000000 doesn't exist...")
		end
	elseif sets[txt] then
		write(readTable(sets[txt]))
	elseif txt:sub(1,1) == "#" and sets[txt:sub(2)] then
		write("#000000 There are #FF0000 "..#sets[txt:sub(2)].." #000000 element(s) in this set.")
	else local t = convert(txt,true)
		if t then
			write(
				"#000000 That's a nice set, but you need to state the variable first."..
				"Try typing #0000FF myVar #FF0000 = {#000000 "..concat(t,"#FF0000 ,#000000 ").."#FF0000 }#000000 ."
			)

			return
		end


		local var = txt:match("(.-) = {")
		if var then
			local t = convert(txt:sub(var:len()+4),true)
			if t then
				if not sets[var] then
					setCount = setCount+1
					sets[var] = t
					write("#000000 Set #FF0000 "..var.." #000000 created!")
				else write("#000000 Whoops! It looks like that variable name is already being used!")
				end
			end
		end
	end
end

--[[
Loaded once after executing the application.
]]
function love.load()
	-- Window Setup
	love.graphics.setDefaultFilter("nearest","nearest")
	love.graphics.setBackgroundColor(255,255,255)

	-- GUI Setup

	root = Instance:new("UI",function(self)
		self:setScale(0,0,1,1)
	end)
	local border = Instance:new("Frame",function(self)
		self.fillColor.a = 0
		self.lineColor.a = 0
		self.wrap = true
		self:setOffset(0,0,360,560)
		root:add(self)
	end)
	frame = Instance:new("Frame",function(self)
		self.fillColor.a = 0
		self.lineColor.a = 0
		border:add(self)
	end)

	game.ui = root

	local textBox = Instance:new("TextBox",function(self)
		self.font = boxFont
		self.textAlign = "middleleft"
		self.fillColor.a = 0
		self.lineColor.a = 0
		self.wrap = true
		self.emptyText = "Type something..."

		self:setOffset(10,560,340,30)
		root:add(self,2)

		self.textBoxReleased:connect(function(enter)
			if enter then
				write("#000000 > "..self.text)
				response(self.text)
				self:setFocus()
			else self.text = ""
			end
		end)
	end)

	-- Hook Setup

	input.mouseWheel:connect(function(_,y)
		scrollOffset = max(min(0,560-chatOffset),min(0,scrollOffset+y*chatSize))
	end)

	game.gameUpdate:connect(function(dt)
		scrollAbsOffset = (scrollAbsOffset+scrollOffset)/2
		frame:setOffset(0,scrollAbsOffset)
	end)

	-- Welcome

	write("#000000 Type #FF0000 /help #000000 for info.")
end

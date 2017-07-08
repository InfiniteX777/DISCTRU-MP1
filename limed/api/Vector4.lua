local max,min,cos,sin = math.max,math.min,math.cos,math.sin

local function convert(...)
	local l = {...}

	for k,v in pairs(l) do
		if type(v) == "number" then
			l[k] = Vector4:new(v,v,v,v)
		end
	end

	return unpack(l)
end

Vector4 = Instance:api{
	new = function(self,a,b,c,d)
		self:set(a or 0,b or 0,c or 0,d or 0)
	end,
	__add = function(a,b)
		local a,b = convert(a,b)

		return Vector4:new(
			a.a+b.a,
			a.b+b.b,
			a.c+b.c,
			a.d+b.d
		)
	end,
	__sub = function(a,b)
		local a,b = convert(a,b)

		return Vector4:new(
			a.a-b.a,
			a.b-b.b,
			a.c-b.c,
			a.d-b.d
		)
	end,
	__mul = function(a,b)
		local a,b = convert(a,b)

		return Vector4:new(
			a.a*b.a,
			a.b*b.b,
			a.c*b.c,
			a.d*b.d
		)
	end,
	__div = function(a,b)
		local a,b = convert(a,b)

		return Vector4:new(
			a.a/b.a,
			a.b/b.b,
			a.c/b.c,
			a.d/b.d
		)
	end,
	__pow = function(a,b)
		local a,b = convert(a,b)

		return Vector4:new(
			a.a^b.a,
			a.b^b.b,
			a.c^b.c,
			a.d^b.d
		)
	end,
	__unm = function(a)
		return Vector4:new(
			-a.a,
			-a.b,
			-a.c,
			-a.d
		)
	end,
	__eq = function(a,b)
		local a,b = convert(a,b)

		return a.a == b.a and a.b == b.b and a.c == b.c and a.d == b.d
	end,
	__tostring = function(self)
		return self.a..", "..self.b..", "..self.c..", "..self.d
	end,
	set = function(self,a,b,c,d)
		self.a = a or self.a
		self.b = b or self.b
		self.c = c or self.c
		self.d = d or self.d
	end,
	components = function(self)
		return self.a,self.b,self.c,self.d
	end,
	clone = function(self)
		return Vector4:new(self.a,self.b,self.c,self.d)
	end
}

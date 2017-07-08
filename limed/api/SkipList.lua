local insert,remove = table.insert,table.remove

local function newNode(self,value,index)
	return {
		list = self,
		value = value,
		index = index
	}
end

SkipList = Instance:api{
	new = function(self)
		self.size = 0
	end,
	insert = function(self,value,index)
		local index = index or self.size+1

		assert(index > 0,"Invalid index. Index must be a positive integer.")

		local node = newNode(self,value,index)

		if value and type(value) == "table" then
			self[value] = node
		end

		-- Set highest index.
		if index > self.size then
			self.size = index
		end

		-- Set head node.
		if not self.head or self.head.index >= index then
			self.head = node
		end

		-- Set next node.
		if self[index] then
			node.next = self[index].next
		elseif index < self.size then
			for i=index+1,self.size do
				if self[i] then
					node.next = self[i]
					break
				end
			end
		end

		-- Set previous node's next node to the new node.
		if index > 1 then
			for i=index-1,1,-1 do
				if self[i] then
					self[i].next = node
					break
				end
			end
		end

		self[index] = node
	end,
	remove = function(self,value)
		if not value then return end

		local node
		local prev

		if type(value) == "table" then
			node = self[value]

			if node then
				if node.index > 1 then
					for i=node.index-1,1,-1 do
						if self[i] then
							prev = self[i]
							break
						end
					end
				end
			end
		else local cur = self.head
			repeat
				if cur.value == value then
					node = cur
					break
				end

				prev = cur
				cur = cur.next
			until not cur
		end

		if node then
			if node.next then
				for i=node.index+1,self.size do
					local v = self[i]
					self[i-1] = v

					if v then
						v.index = i-1
					end
				end
			else self[node.index] = nil
			end

			if prev then
				prev.next = node.next
			end

			if self.head == node then
				self.head = node.next
			end
		end
	end,
	ipairs = function(self)
		local i = 0
		local node
		return function()
			i = i+1

			if not node then
				node = self.head
			else node = node.next
			end

			return node and node.index, node and node.value
		end
	end
}

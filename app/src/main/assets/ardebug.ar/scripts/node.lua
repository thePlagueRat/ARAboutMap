-- node.lua --
function LOAD_NODE()
	AR_NODE_CACHE = {}
	function GET_NODE(name)
		if(AR_NODE_CACHE[name] ~= nil)
		then
			return AR_NODE_CACHE[name]
		end

		local node = {}
		if(name == 'root')
		then
			node.entity = CURRENT_SCENE:get_root_node()
		else
			node.entity = CURRENT_SCENE:get_node_by_name(name)
		end

		if(node.entity == nil) then
			return nil
		end

		AR_NODE_CACHE[name] = node
		setmetatable(node, node)
		node.__index = function(node, key) 
			if(node.entity[key] == nil)
			then
				ARLOG('尝试调用ar_node的'..key..' 方法/属性, 该方法/属性不存在')
				return NOP_FUNC
			else
				__F_FUNC = function(node, ...)
					__BACK_FUNC = node.entity[key]
					return __BACK_FUNC(node.entity, ...)
				end
				return __F_FUNC
			end
		end

		node.on_click = function(self, handler)
			if(type(handler) == "string") then
				ARLOG("Register string click handler")
				local handler_id = LUA_HANDLER:register_handle(handler)
				self.entity:set_event_handler(0, handler_id)
			elseif(type(handler) == "function") then
				local RANDOM_NAME = RES_CLOSURE(handler)
				ARLOG("Register function click handler")
				self.entity:set_event_handler(0, LUA_HANDLER:register_handle(RANDOM_NAME))
			else
				ARLOG("invalid param in ar_node:on_click")
				ARLOG(type(handler))
			end
		end

		node.move_by = function(self)
			local anim = Anim('move_by', self)
			return anim
		end

		-- node.move_to = function(self)
		-- 	local anim = Anim('move_to', self)
		-- 	return anim
		-- end

		node.scale_by = function(self)
			local anim = Anim('scale_by', self)
			return anim
		end

		-- node.scale_to = function(self)
		-- 	local anim = Anim('scale_to', self)
		-- 	return anim
		-- end

		node.rotate_to = function(self)
			local anim = Anim('rotate_to', self)
			return anim
		end

		node.rotate_by = function(self)
			local anim = Anim('rotate_by', self)
			return anim
		end

		node.position_v = function(self)
			local str_pos = self.entity:get_position()
			local vec = Vector3(str_pos)
			return vec
		end

		node.set_position_v = function(self, vec)
			self.entity:set_position(vec.x, vec.y, vec.z)
		end

		node.scale_v = function(self)
			local str_scale = self.entity:get_scale()
			local vec = Vector3(str_scale)
			return vec
		end

		node.set_scale_v = function(self, vec)
			self.entity:set_scale(vec.x, vec.y, vec.z)
		end

		node.set_rotation_v = function(self, vec)
			self.entity:set_rotation_by_xyz(vec.x, vec.y, vec.z)
		end
		return node
	end

	ARLOG('load node')
end

LOAD_NODE(0)

-- node.lua end --


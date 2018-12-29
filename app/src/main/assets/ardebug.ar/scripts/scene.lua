-- scene.lua --
function LOAD_SCENE()
	scene = {}
	setmetatable(scene, scene)
	scene.__index = function(self, key)
		if(self.entity[key] == nil) then
			local node = GET_NODE(key)
			if (node == nil) then
				ARLOG('尝试调用ar_scene的'..key..' 方法/属性, 该方法/属性不存在')
				return NOP_FUNC
			else
				return node
			end
		else
			__F_FUNC = function(self, ...)
				__BACK_FUNC = self.entity[key]
				return __BACK_FUNC(self.entity, ...)
			end
			return __F_FUNC
		end
	end
	current_scene = scene
	ARLOG('load scene')
end

LOAD_SCENE()

-- scene.lua end --

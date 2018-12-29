-- application.lua --
function LOAD_APPLICATION()
	application = {}
	application.entity = nil
	setmetatable(application, application)
	application.__index = function(self, key)
		if(self.entity[key] == nil) then
			ARLOG('尝试调用application的'..key..' 方法/属性, 该方法/属性不存在')
			return NOP_FUNC
		else
			__F_FUNC = function(self, ...)
					__BACK_FUNC = self.entity[key]
					return __BACK_FUNC(self.entity, ...)
				end
			return __F_FUNC
		end
	end

	application.active_scene_by_name = function(self, name)
		self.entity:active_scene_by_name(name)
		CURRENT_SCENE = self:get_current_scene()
		scene.entity = CURRENT_SCENE
	end

	application.on_loading_finish = function(self, func_name)
		local handler_id =  LUA_HANDLER:register_handle(func_name)
		self:set_on_loading_finish_handler(handler_id)
	end

	application.on_target_lost = function(self, func_name)
		local handler_id =  LUA_HANDLER:register_handle(func_name)
		self:set_on_tracking_lost_handler(handler_id)
	end

	application.on_target_found = function (self, func_name)
		local handler_id =  LUA_HANDLER:register_handle(func_name)
		self:set_on_tracking_found_handler(handler_id)
	end

	application.on_device_to_landscape_left = function(self, func_name)
		local handler_id = LUA_HANDLER:register_handle(func_name)
		self:set_on_landscape_left_handler(handler_id)
	end

	application.on_device_to_landscape_right = function(self, func_name)
		local handler_id = LUA_HANDLER:register_handle(func_name)
		self:set_on_landscape_right_handler(handler_id)
	end

	application.on_device_to_portrait = function(self, func_name)
		local handler_id = LUA_HANDLER:register_handle(func_name)
		self:set_on_portrait_handler(handler_id)
	end

	-- open shake sensor 
	function application.open_shake_listener(self )
		local mapData = ae.MapData:new() 
   	 	mapData:put_int("id",MSG_TYPE_OPEN_SHAKE ) 
    	LUA_HANDLER:send_message_tosdk(mapData)
	end

	-- close shake sensor
	function application.stop_shake_listener( self )
		local mapData = ae.MapData:new() 
   	 	mapData:put_int("id", MSG_TYPE_STOP_SHAKE) 
    	LUA_HANDLER:send_message_tosdk(mapData)
	end

	--  set shake acc threshold
	function application.set_shake_threshold(self, threshold)
		if (type(threshold) == "number") then
	 		if (threshold > 5) then
				MAX_SHAKE_THRESHOLD = threshold
			else 
				ARLOG("gravity threshold is too small")
			end
		else 
			ARLOG("invalid number")
		end 
	end
	--  get gravity threshold
	function application.get_shake_threshold(self)
		return MAX_SHAKE_THRESHOLD
	end


	lua_handler = {}
	lua_handler.entity = nil
	setmetatable(lua_handler, lua_handler)
	lua_handler.__index = function(self, key)
		if(self.entity[key] == nil) then
			ARLOG('尝试调用lua_handler的'..key..' 方法/属性, 该方法/属性不存在')
			return NOP_FUNC
		else
			__F_FUNC = function(self, ...)
					__BACK_FUNC = self.entity[key]
					return __BACK_FUNC(self.entity, ...)
				end
			return __F_FUNC
		end
	end

	ARLOG('load application/lua_handler')
end

LOAD_APPLICATION()

-- application.lua end

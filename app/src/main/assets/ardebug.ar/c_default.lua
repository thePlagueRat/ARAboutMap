app_controller = ae.ARApplicationController:shared_instance()
-- 不要修改模块引入的顺序 --
-- utils.lua --
function LOAD_UTILS()
	function ARLOG(line)
		io.write('[LUA-LOG] '..line)
	end

	function NOP_FUNC(...)
		ARLOG('nop_func called')
	end

	function F_GENERATOR()
		FUNC_NAME_INDEX = 0
		return function()
			FUNC_NAME_INDEX = FUNC_NAME_INDEX+1
			return "BAR_ANONYMOUS_FUNC_"..FUNC_NAME_INDEX
		end
	end
	FNAME = F_GENERATOR()

	function RES_CLOSURE(func)
		RANDOM_NAME = FNAME()
		GLOBALFUNC = func
		loadstring(RANDOM_NAME.."=GLOBALFUNC")()
		return RANDOM_NAME
	end

	function string:split(sep)
	   local sep, fields = sep or ":", {}
	   local pattern = string.format("([^%s]+)", sep)
	   self:gsub(pattern, function(c) fields[#fields+1] = c end)
	   return fields
	end

	ARLOG('load util')
end

LOAD_UTILS()
--  utils.lua end -- 
-- utils.lua --
function LOAD_CONST()
	AR_TYPE_NONE = 0
	AR_TYPE_IMAGE_TRACK = 1
	AR_TYPE_IMU = 2
	AR_TYPE_IMAGE_TRACK_IMU = 3
	AR_TYPE_SLAM = 4

	-- Device Orientation -- 
	DeviceOrientation = {}
	DeviceOrientation.Portrait = 0
	DeviceOrientation.Left = 1
	DeviceOrientation.Right = 2

	-- SDK LUA MSG TYPE --
	-- shake --
	MSG_TYPE_SHAKE = 10000
	MSG_TYPE_OPEN_SHAKE = 10001
	MSG_TYPE_STOP_SHAKE = 10002
	MAX_SHAKE_THRESHOLD = 9.8
	
	-- voice api --
	MSG_TYPE_VOICE_START = 2001
	MSG_TYPE_VOICE_STOP = 2002
	
	ARLOG('load const')
end

LOAD_CONST()
--  utils.lua end -- 
-- frame.lua --
function LOAD_FRAME()
	LUA_HANDLER = nil
	CURRENT_SCENE = nil
	
	-- Init --
	function create_application(app_type, name)
		if(ae.ARApplicationController) ~= nil then
			APPLICATION = ae.ARApplicationController:shared_instance():add_application_with_type(app_type, name)
		else
			APPLICATION = ae.ARApplication:shared_application()
		end
		application.entity = APPLICATION
		LUA_HANDLER = APPLICATION:get_lua_handler()
		lua_handler.entity = LUA_HANDLER
		lua_handler:register_lua_sdk_bridge("HANDLE_SDK_MSG")

		application:on_device_to_landscape_right('DEVICE_TO_LANDSCAPE_RIGHT')
		application:on_device_to_landscape_left('DEVICE_TO_LANDSCAPE_LEFT')
		application:on_device_to_portrait('DEVICE_TO_PORTRAIT')
	end

	-- Lua/SDK Bridge -- 
	function HANDLE_SDK_MSG(mapData)
		msg_id = mapData['id']
		if (msg_id == MSG_TYPE_SHAKE) then
			if(onDeviceShake ~= nil) then
				onDeviceShake()
			else
				ARLOG("收到Shake消息，但onDeviceShake方法未定义")
			end
		elseif(msg_id == MSG_TYPE_VOICE_START) then
			if(Voice.callBack ~= nil) then
				Voice.callBack(mapData)
			end
		else
			ARLOG("收到未知消息类型: "..msg_id)
		end
	end

	-- C++ Handler Wrapper -- 
	function DEVICE_TO_LANDSCAPE_LEFT()
		if(onDeviceRotate ~= nil) then
			onDeviceRotate(DeviceOrientation.Left)
		end
	end

	function DEVICE_TO_LANDSCAPE_RIGHT()
		if(onDeviceRotate ~= nil) then
			onDeviceRotate(DeviceOrientation.Right)
		end
	end

	function DEVICE_TO_PORTRAIT()
		if(onDeviceRotate ~= nil) then
			onDeviceRotate(DeviceOrientation.Portrait)
		end
	end

	-- Loop --
	BAR_ON_LOOP = true
	LOOP_INTERVAL = 30
	LOOP_FUNC = nil

	Loop = {}
	Loop.fire_loop = function(self, loop_func, interval)
		if(type(loop_func) ~= 'function') then
			ARLOG("param error, param of function type needed");
			return
		end
		LOOP_FUNC = loop_func
		if(interval < 25) then
			ARLOG("param error, loop interval too short");
		end
		LOOP_INTERVAL = interval
		ae.LuaUtils:call_function_after_delay(LOOP_INTERVAL, "BAR_INNER_LOOP")
	end

	Loop.cancel_loop = function(self)
		BAR_ON_LOOP = false
		LOOP_FUNC = nil
	end

	function BAR_INNER_LOOP()
		if(type(LOOP_FUNC) == 'function') then
			LOOP_FUNC()
		end
		if BAR_ON_LOOP then
			ae.LuaUtils:call_function_after_delay(LOOP_INTERVAL, "BAR_INNER_LOOP")
		end
	end

	ARLOG('load frame')
end
LOAD_FRAME()

-- frame.lua end --
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
	function application.stop_shake_listner( self )
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

-- amath.lua -- 
function LOAD_MATH()
	Vector3 = {
		__add = function(self, other_vec3)
			local new_vec3 = Vector3("0,0,0")
			new_vec3.x = self.x + other_vec3.x
			new_vec3.y = self.y + other_vec3.y
			new_vec3.z = self.z + other_vec3.z
			return new_vec3
		end,
		__sub = function(self, other_vec3)
			local new_vec3 = Vector3("0,0,0")
			new_vec3.x = self.x - other_vec3.x
			new_vec3.y = self.y - other_vec3.y
			new_vec3.z = self.z - other_vec3.z
			return new_vec3
		end,
		__unm = function(self)
			local new_vec3 = Vector3("0,0,0")
			new_vec3.x = -self.x
			new_vec3.y = -self.y
			new_vec3.z = -self.z
			return new_vec3
		end,
		__mul = function(self, scalar)
			local new_vec3 = Vector3("0,0,0")
			new_vec3.x = self.x * scalar
			new_vec3.y = self.y * scalar
			new_vec3.z = self.z * scalar
			return new_vec3
		end,
		__div = function(self, scalar)
			local new_vec3 = Vector3("0,0,0")
			new_vec3.x = self.x / scalar
			new_vec3.y = self.y / scalar
			new_vec3.z = self.z / scalar
			return new_vec3
		end,
		__call = function(self,param)
			local vec3 = {}
			vec3.encode = function(self)
				return tostring(self.x)..','..tostring(self.y)..','..tostring(self.z)
			end
			setmetatable(vec3, self)
			if type(param) == 'table' then
				if #param ~= 3 then
					vec3.x = 0
					vec3.y = 0
					vec3.z = 0
					return vec3
				end
				vec3.x = param[1]
				vec3.y = param[2]
				vec3.z = param[3]
				return vec3
			end
			if type(param) == 'string' then
				local arr = param:split(',')
				if #arr ~= 3 then
					vec3.x = 0
					vec3.y = 0
					vec3.z = 0
					return vec3	
				end
				vec3.x = arr[1]
				vec3.y = arr[2]
				vec3.z = arr[3]
				return vec3
			end
		end,
		__tostring = function(self)
			return 'x:'..tostring(self.x)..', y:'..tostring(self.y)..', z:'..tostring(self.z)
		end
	}
	setmetatable(Vector3, Vector3)

	ARLOG('load amath')
end
LOAD_MATH()
-- amath.lua end --

-- anim.lua --
function LOAD_ANIM()
	Anim = {
		__call = function(self, anim_type, entity) 
			local anim = {
				_anim_type = nil,
				_entity = nil,
				_duration = 1000,
				_repeat_max_count = 0,
				_forward_direction = 1,
				_start_offset = 0,
				_delay = 0,
				_repeat_mode = 0,
				_interpolater_type = 0,
				_src_xyz = Vector3("0,0,0"),
				_dst_xyz = Vector3("0,0,0"),
				_curve0_xyz = '',
				_curve1_xyz = '',
				_curve2_xyz = '',
				_curve3_xyz = '',
				_forward_logic = 0,
				_backward_logic = 0,
				_source_degree = 0,
				_target_degree = 0,
				_axis_xyz = Vector3("0,1,0"),
				_on_complete = nil,
				get_meta_param = function(self)
					if self._anim_type == 'move_by' then
						local param = ae.TranslateMotionParam:new() 
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type
						param._curve0_xyz = self._curve0_xyz
						param._curve1_xyz = self._curve1_xyz
						param._curve2_xyz = self._curve2_xyz
						param._curve3_xyz = self._curve3_xyz

						param._dst_xyz = self._dst_xyz:encode()
						return param
					end
					if self._anim_type == 'move_to' then
						local param = ae.TranslateMotionParam:new() 
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type
						param._curve0_xyz = self._curve0_xyz
						param._curve1_xyz = self._curve1_xyz
						param._curve2_xyz = self._curve2_xyz
						param._curve3_xyz = self._curve3_xyz

						param._dst_xyz = self._dst_xyz:encode()
						param._src_xyz = self._src_xyz:encode()
						return param
					end
					if self._anim_type == 'scale_by' then
						local param = ae.ScaleMotionParam:new()
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type

						param._dst_xyz = self._dst_xyz:encode()
						return  param
					end
					if self._anim_type == 'scale_to' then
						local param = ae.ScaleMotionParam:new()
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type

						param._dst_xyz = self._dst_xyz:encode()
						param._src_xyz = self._src_xyz:encode()
						return param
					end
					if self._anim_type == 'rotate_to' then
						local param = ae.RotateMotionParam:new()
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type

						param._source_degree = self._source_degree
						param._target_degree = self._target_degree
						param._axis_xyz = self._axis_xyz:encode()
						return param
					end
					if self._anim_type == 'rotate_by' then
						local param = ae.RotateMotionParam:new()
						param._forward_direction = self._forward_direction
						param._repeat_mode = self._repeat_mode
						param._repeat_max_count = self._repeat_max_count
						param._duration = self._duration
						param._start_offset = self._start_offset
						param._delay = self._delay
						param._interpolater_type = self._interpolater_type

						param._target_degree = self._target_degree
						param._axis_xyz = self._axis_xyz:encode()
						return param
					end


				end,
				get_meta_action_priority_config = function(self)
					local action_config = ae.ActionPriorityConfig:new() 
					action_config.forward_logic = self._forward_logic
					action_config.backward_logic = self._backward_logic
					ARLOG("Get Action Config")
					return action_config
				end,

				start = function(self)
					local param = self:get_meta_param()
					local config = self:get_meta_action_priority_config()
					local anim_id = self._entity:play_rigid_anim(param, config)
					if self._on_complete ~= nil then
						if type(self._on_complete) == 'string' then
							local handler_id = LUA_HANDLER:register_handle(self._on_complete)
							self._entity:set_action_completion_handler(anim_id, handler_id)
						end
						if type(self._on_complete) == 'function' then
							local RANDOM_NAME = RES_CLOSURE(self._on_complete)
							local handler_id = LUA_HANDLER:register_handle(RANDOM_NAME)
							self._entity:set_action_completion_handler(anim_id, handler_id)	
						end
					end
					return anim_id
				end,

				duration = function(self, d)
					self._duration = d
					return self
				end,
				repeat_mode = function(self, mode)
					self._repeat_mode = mode
					return self
				end, 
				repeat_count = function(self, count)
					self._repeat_max_count = count
					return self
				end,
				forward_direction = function(self, d)
					self._forward_direction = d
					return self
				end,
				start_offset = function(self, offset)
					self._start_offset = offset
					return self
				end,
				delay = function(self, d)
					self._delay = d
					return self
				end,
				to = function(self, vec)
					self._dst_xyz = vec
					return self
				end,
				from = function(self, vec)
					self._src_xyz = vec
					return self
				end,
				backward_logic = function(self, value)
					self._backward_logic = value
					return self
				end,
				forward_logic = function(self, value)
					self._forward_logic = value
					return self
				end,
				interpolater_type = function(self, mode)
					self._interpolater_type = mode
					return self
				end,
				on_complete = function(self, handler)
					self._on_complete = handler
					return self
				end,
				curve0_xyz = function(self, vector)
					self._curve0_xyz = vector:encode()
					return self
				end,
				curve1_xyz = function(self, vector)
					self._curve1_xyz = vector:encode()
					return self
				end,
				curve2_xyz = function(self, vector)
					self._curve2_xyz = vector:encode()
					return self
				end,
				curve3_xyz = function(self, vector)
					self._curve3_xyz = vector:encode()
					return self
				end,
				from_degree = function(self, degree)
					self._source_degree = degree
					return self
				end,
				to_degree = function(self, degree)
					self._target_degree = degree
					return self
				end,
				axis_xyz = function(self, vec)
					self._axis_xyz = vec
					return self
				end
			}
			setmetatable(anim, self)
			anim._anim_type = anim_type
			anim._entity = entity
			return anim
		end
	}
	setmetatable(Anim, Anim)

	ARLOG('load anim')
end

LOAD_ANIM()
-- anim.lua end--

-- speech.lua -- 
function LOAD_VOICE()
	Speech = {}
	Speech.callBack = nil

	Speech.start_listen = function(self)
		local mapData = ae.MapData:new() 
		mapData:put_int("id", MSG_TYPE_VOICE_START) 
		lua_handler:send_message_tosdk(mapData)
	end

	Speech.stop_listen = function(self)
		local mapData = ae.MapData:new() 
		mapData:put_int("id", MSG_TYPE_VOICE_STOP) 
		lua_handler:send_message_tosdk(mapData)
	end
end

LOAD_VOICE()

-- speech.lua end --
create_application(AR_TYPE_IMAGE_TRACK_IMU , "bear demo")
--[[
	已创建全局变量 application, lua_handler, scene, current_scene等
]]
--  Case Logic --
application:add_scene_from_json("res/simple_scene.json","demo_scene")
application:active_scene_by_name("demo_scene")


application:on_loading_finish("onApplicationDidLoad")
function onApplicationDidLoad()
	-- on application did load --
	application:open_shake_listener()
	application:set_shake_threshold(10)
end

-- 手机摇一摇时间响应 -- 
function onDeviceShake()
	ARLOG("shake the device")
end


-- 循环方法 --
-- function loop() 
-- 	ARLOG('tic toc')

-- end

-- 2D 跟踪丢失 -- 
-- application:on_target_lost("onTargetLost")
-- function onTargetLost()
-- 	-- on target lost --
-- end

-- 2D 跟踪成功 --
-- application:on_target_found("onTargetFound")
-- function onTargetFound()
-- 	-- on target found --
-- end

-- 设备旋转响应 -- 
-- function onDeviceRotate(orientation)
-- 	if(orientation == DeviceOrientation.Left) then
-- 		ARLOG('Rotate to left')
-- 	elseif(orientation == DeviceOrientation.Right) then
-- 		ARLOG('Rotate to right')
-- 	elseif(orientation == DeviceOrientation.Portrait) then
-- 		ARLOG('Rotate to Portrait')
-- 	end
-- end



-- 语音回调响应 -- 
-- Voice.callBack = function(data)
	
-- end

-- Case逻辑代码 --

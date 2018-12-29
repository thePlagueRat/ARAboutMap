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
            max_acc = mapData['max_acc']
            ARLOG('got max acc '..max_acc)
            if(max_acc < MAX_SHAKE_THRESHOLD) then
                return
            end

			if(onDeviceShake ~= nil) then
				onDeviceShake()
			else
				ARLOG("收到Shake消息，但onDeviceShake方法未定义")
			end
		elseif(msg_id == MSG_TYPE_VOICE_START) then
			if(Speech.callBack ~= nil) then
				Speech.callBack(mapData)
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

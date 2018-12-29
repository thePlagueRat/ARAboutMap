app_controller = ae.ARApplicationController:shared_instance()
-- 不要修改模块引入的顺序 --
app_controller:require('./scripts/utils.lua')
app_controller:require('./scripts/const.lua')
app_controller:require('./scripts/frame.lua')
app_controller:require('./scripts/scene.lua')
app_controller:require('./scripts/application.lua')
app_controller:require('./scripts/node.lua')
app_controller:require('./scripts/amath.lua')
app_controller:require('./scripts/anim.lua')
app_controller:require('./scripts/speech.lua')

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
	
	-- init speech
	initSpeech()
	application:open_imu_service(1)
	setBirdEyeView()


  local startButtonClickHandler = lua_handler:register_handle("onSimpleButtonClick")
	local start_button = current_scene:get_node_by_name("StartButton")
	start_button:set_event_handler(0, startButtonClickHandler)
	
end


-- 2D 跟踪丢失 -- 
application:on_target_lost("onTargetLost")
function onTargetLost()
	-- on target lost --
	setBirdEyeView()
end



-- init voice
function initSpeech()
local voiceButtonClickHandler = lua_handler:register_handle("voiceStart");
local voiceNode = current_scene:get_node_by_name("voice")
voiceNode:set_event_handler(0, voiceButtonClickHandler)
end

--打开语音
function voiceStart()
  Speech.start_listen()
end

--关闭语音
function voiceStop()
  Speech.stop_listen()
end

-- 语音回调响应 -- 
Speech.callBack = function(data)
	voiceCallback(data)
end

-- 语音callback
function voiceCallback(mapData)
 
    local status = mapData['status']
    io.write(' lua voiceCallback status '..status)
    if(status ~= nil) then
        if(status == VOICE_STATUS_READYFORSPEECH) then
        	ARLOG('语音准备就绪')
        	voiceNode:set_visible(false)
        end
        if(status == VOICE_STATUS_BEGINNINGOFSPEECH) then
        	ARLOG('可以开始说话')
        end
        if(status == VOICE_STATUS_ENDOFSPEECH) then
        	ARLOG('说话结束')
        	voiceNode:set_visible(true)
        end
        if(status == VOICE_STATUS_ERROR) then
        	ARLOG('识别出错')
	        errorid = mapData['error_id']
	        errorId(errorid)
        end
        if(status == VOICE_STATUS_RESULT) then
	        str = mapData['voice_result']
	        ARLOG('识别最终结果 : '..str)
	        matchResult(str)
        end
        if(status == VOICE_STATUS_RESULT_NO_MATCH) then
        	ARLOG('识别结果不匹配')
        end
        if(status == VOICE_STATUS_PARTIALRESULT) then
       	 ARLOG('识别临时结果')
        end
        if(status == VOICE_STATUS_CANCLE) then
       	 ARLOG('取消识别')
       	 voiceNode:set_visible(true)
        end
    end
    
end

--结果匹配
function matchResult(str)
  io.write(' lua voiceCallback matchResult '..str)
	
	if( str == 'show')
	then
	showCaishen()
	end
	
	if( str == 'left')
	then
	--case 处理
	end
	
	if( str == 'right')
	then
	--case 处理
	end
end

function errorId(id)
  if( id == VOICE_ERROR_STATUS_NULL)
	then
	ARLOG('未知错误')
	end
	
	if( id == VOICE_ERROR_STATUS_SPEECH_TIMEOUT)
	then
	ARLOG('没有语音输入')
	end
	
	if( id == VOICE_ERROR_STATUS_NETWORK)
	then
	ARLOG('网络错误')
	end
	
	if( id == VOICE_ERROR_STATUS_INSUFFICIENT_PERMISSIONS)
	then
	ARLOG('权限错误')
	end
end

function setBirdEyeView()
    application:set_camera_look_at("0.0, 90.0, 800.0","0, 0, 0", "0, 2.0, 1.0")
end



function onSimpleButtonClick()
local current_scene1 = application:get_current_scene()
local root_node = current_scene1:get_root_node()
local contentPlane = current_scene1:get_node_by_name("ContentPlane")
local startButton = current_scene:get_node_by_name("StartButton")
contentPlane:set_visible(false)
startButton:set_visible(false)
hideNode("ContentPlane",application:get_current_scene())
hideNode("StartButton",application:get_current_scene())

Speech.show_mic_icon()
voiceStart()
end


--点击场景1按钮，加载财神
function showCaishen()
application:open_imu_service(1)

local current_scene1 = application:get_current_scene()
local root_node = current_scene1:get_root_node()
io.write("play music..")
root_node:play_audio("/res/media/sound.wav", 1, 0)
Speech.show_mic_icon()


if root_node then
end



showNode("s1_simplePod",application:get_current_scene())

root_node:play_pod_animation_all(1, false,1,55)
root_node:play_pod_animation_all(1,true,55,256)


end


willHideNodes = {}

function hideNode(nodeName,scene)
   local node = scene:get_node_by_name(nodeName)
   local scfg = ae.ActionPriorityConfig:new()
   scfg.forward_logic = 1
   local s = ae.ScaleMotionParam:new()
   s._src_xyz = "1,1,1"
   s._dst_xyz = "0.1,0.1,0.1"
   s._delay = 0
   s._duration = 500
   --s._repeat_mode = 1
   local animId = node:play_rigid_anim(s,scfg)
   willHideNodes[tostring(animId)] = nodeName
   node:set_action_completion_handler(animId, onHideAnimCompletedHandler)
   node:set_visible(false)
end

function onHideAnimCompleted(status, animId)
    local nodeName = willHideNodes[tostring(animId)]
    if nodeName then
    local node = application:get_current_scene():get_node_by_name(nodeName)
    node:set_visible(false)
    node:reset_rts()
    willHideNodes[tostring(animId)] = nil
    end
end

function showNode(nodeName,scene)
    local node = scene:get_node_by_name(nodeName)

    local scfg = ae.ActionPriorityConfig:new()
    scfg.forward_logic = 1
    local s = ae.ScaleMotionParam:new()
    s._src_xyz = "0.1, 0.1, 0.1"
    s._dst_xyz = "1,1,1"
    s._delay = 0
    s._duration = 500
    --s._repeat_mode = 1
    node:play_rigid_anim(s,scfg)
    node:set_visible(true)
end

function showNode2(nodeName,scene)
local node = scene:get_node_by_name(nodeName)

--node:get_sub_node_by_name("shu_shugan").set_scale(10.0, 10.0, 10.0)
local scfg = ae.ActionPriorityConfig:new()
scfg.forward_logic = 1
local s = ae.TranslateMotionParam:new()
s._src_xyz = "-100, -100, 0"
s._dst_xyz = "100,100,0"
s._delay = 500
s._duration = 500
--s._repeat_mode = 1
node:play_rigid_anim(s,scfg)
node:set_visible(true)
end


-- Case逻辑代码 --

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


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

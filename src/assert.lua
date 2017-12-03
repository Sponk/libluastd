local Assert = {}

function Assert.assertType(variable, typename)
	if type(variable) == "table" then
		assert(variable._type == typename._type, "Expected " .. typename._type .. " but got " .. variable._type)
	else
		assert(type(variable) == typename, "Expected '" .. typename .. "' but got '" .. type(variable) .. "'")
	end
end

function Assert.assertArgs(types, ...)
	local params = {...}
	for k,v in ipairs(types) do
		Assert.assertType(params[k], v) 
	end
end

return Assert

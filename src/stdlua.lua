
local std = nil
local function clone(tbl)
	local c = {}
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			c[k] = clone(v)
		else
			c[k] = v
		end
	end
	return c
end

local function dump(tbl)
	local c = {}
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			dump(v)
		else
			print(k,v)
		end
	end
end

-- RTTI implementation
function typeid(obj)
	if type(obj) == "table" and obj._type ~= nil then
		return obj._type
	end
	
	return type(obj)
end

-- Class implementation
function class(c)
	--[[local c = body {
		_type = body[1],
		public = body.public,
		static = body.static,
		extends = body.extends,
		base = {}
	}]]
	
	c._type = c[1]
	c.base = {}
	c[1] = nil
	
	local getField = function(objPub, objPriv, tbl, key)
	
		--print("ACCESS: ", key)
		local elem = objPub[key]
		if elem ~= nil then
			return elem
		else
			local elem = nil
			local currentClass = c
			while elem == nil and currentClass ~= nil do
				elem = currentClass.public[key]
				currentClass = currentClass.extends
			end
			
			-- Try custom [] overload
			if elem == nil and c.public.operator_idx then
				return c.public.operator_idx(tbl, key)
			end
			-- If no possible public interface satisfies has the value
			-- try to find a private one
			--if elem == nil then
			--	local calling = debug.getinfo(2)
				--print(calling.name, calling.func)
				--print(c._type)
				
				--assert(c.public[calling.name] == calling.func, "Public access to private member '" .. key .. "'")
				
			--	return objPriv[key]
			--end
			return elem
		end
	end
	
	setmetatable(c.base, {
		__index = function(tbl, key)  
				if c.extends then
					assert(c.extends ~= nil, "Trying to access base class field or method in a non child class!")
					return getField(c.extends.public or {}, {}, tbl, key)
				end
				
				return nil
			end
	})
	
	setmetatable(c, {
		__call = function(t, ...)
		
			local objPub = {}
			local objPriv = {}
			local obj = {
				public = objPub,
				private = objPriv,
				base = c.base
			}
			
			setmetatable(obj, {
				__index = function(tbl, key) return getField(objPub, objPriv, tbl, key) end,
				__add = c.public.operator_plus,
				__sub = c.public.operator_sub,
				__div = c.public.operator_div,
				__mul = c.public.operator_mul
			})
			
			if c.public.construct then
				obj:construct(...)
			end
			return obj
		end,
		
		__newindex = function(tbl, key, obj)
			c.public[key] = obj
		end
	})
	
	return c
end

-- Exception implementation
function throw(ex)
	error(ex)
end

function try(body)
	local status, err = pcall(body[1])
	if status == true then
		return err
	end
	
	-- Build exception from string, for example when Lua itself throws
	if typeid(err) == "string" then
		err = std.exception(err)
	end
	
	-- If no catch was found, rethrow
	if body.catch == nil then
		error(err)
	end
	
	return body.catch(err)
end

local function scriptPath()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

package.path = scriptPath() .. "?.lua;" .. package.path

std = {
	__FILE__ = scriptPath,
	exception = class {"exception",
		public = {
			message = "",
			what = function(self) return self.message end
		}
	}
}

function std.exception:construct(msg)
	self.message = msg 
end

function using(table)
	for k,v in pairs(table) do
		_G[k] = v;
	end
end

return std

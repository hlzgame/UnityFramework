require "clientDBBase"
local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local rawget = rawget

function TableLoader()
    for k, v in pairs(Table) do
        if type(v) == "table" and v.__meta ~= nil then
			local __m = {}
			__m.__index = function (self, field)
				local __meta
				if rawget(self,__meta)== nil then
					__meta = v.__meta
				else
					__meta =self.__meta
				end
				local index = __meta[field]
				if index == nil then
					return nil
				end
				
				if self[index] == nil then
					return nil;
				end

				self[field] = self[index]
				local fieldData = self[field]
				
				local __dict = __meta.__dict
				if __dict then
					if __dict[index] then
						fieldData.__meta = __dict[index]
						setmetatable(fieldData,__m)
					end
				end

				return fieldData
			end

            v.get = function(...)
                local arg = {...}
                if #arg == 0 then
                    return
                end

                -- splice key
                local key
                if #arg == 1 then
                    key = arg[1] 
                    if type(key) == "string" then
                        key = tostring(key)
                    end
                else
                    for i,v in ipairs(arg) do
                        if i == 1 then
                            key = tostring(v)
                        else
                            key = key .."_" .. tostring(v)
                        end
                    end
                end
                if key == nil or key == "__meta" or key == "get"  then
                    return nil
                end

                local row = v[key]
                if row ~= nil then
                    if getmetatable(row) == nil then
                        setmetatable(row, __m)
                    end
                end

                return row
            end
        end
    end
end

TableLoader();

--[[Writen by vic
日志输出接口, 多个参数，用逗号分隔

Exported API:

Example:
logDebug(1)
logTrace("222")
--]]

--日志输出级别
local logCurrentLevel = 5;

--日志定义级别
local log_debug =		5;
local log_trace =		4;
local log_info =		3;
local log_warn =		2;
local log_error =		1;


--[[
输出日志
接受可变参数
示例：
printLog(1, "222")
]]
local function printLog(level, msg)  
    print(level..""..msg)
end

function logDebug(...)
    local arg = {...}
    --过滤
    if logCurrentLevel < log_debug then
        return;
    end
    --输出
    local printResult = "";
    for i,v in ipairs(arg) do
        printResult = printResult .. tostring(v) .. "  ";
    end
    printLog("[DEBUG]", printResult);
end

function logTrace(...)
    local arg = {...}

    --过滤
    if logCurrentLevel < log_trace then
        return;
    end
    --输出
    local printResult = "";
    for i,v in ipairs(arg) do
        printResult = printResult .. tostring(v) .. "  ";
    end
    printLog("[TRACE]", printResult);
end

function logInfo(...)
    local arg = {...}

    --过滤
    if logCurrentLevel < log_info then
        return;
    end
    --输出
    local printResult = "";
    for i,v in ipairs(arg) do
        printResult = printResult .. tostring(v) .. "  ";
    end
    printLog("[INFO]", printResult);
end

function logWarn(...)
    local arg = {...}

    --过滤
    if logCurrentLevel < log_warn then
        return;
    end
    --输出
    local printResult = "";
    for i,v in ipairs(arg) do
        printResult = printResult .. tostring(v) .. "  ";
    end
    printLog("[WARN]", printResult);
end

function logError(...)
    local arg = {...}

    --过滤
    if logCurrentLevel < log_error then
        return;
    end
    --输出
    local printResult = "";
    for i,v in ipairs(arg) do
        printResult = printResult .. tostring(v) .. "  ";
    end
    printLog("[ERROR]", printResult);
end


--[[  打印table
@lua_table  表对象
@indent    缩进显示 数字
@tag   标签，说明打印的地方或者名称
]]
function printLuaTable (lua_table, indent, tag)
    if tag ~= "" and tag ~= nil then
        logInfo("-------------------------" .. tag .. "-------------------------")
    end

    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        local formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" and v ~= lua_table then
            logInfo(formatting)
            printLuaTable(v, indent + 1, "")
            logInfo(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            logInfo(formatting..szValue..",")
        end
    end
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end
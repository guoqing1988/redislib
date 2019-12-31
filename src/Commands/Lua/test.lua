local cjson = require "cjson"
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format

local unpack = unpack or table.unpack

local function is_callable(f)
  local tf = type(f)
  if tf == 'function' then return true end
  if tf == 'table' then
    local mt = getmetatable(f)
    return type(mt) == 'table' and is_callable(mt.__call)
  end
  return false
end

local function cache_get(cache, params)
  local node = cache
  for i=1, #params do
    node = node.children and node.children[params[i]]
    if not node then return nil end
  end
  return node.results
end

local function cache_put(cache, params, results)
  local node = cache
  local param
  for i=1, #params do
    param = params[i]
    node.children = node.children or {}
    node.children[param] = node.children[param] or {}
    node = node.children[param]
  end
  node.results = results
end

-- public function

local function memoize(f, cache)
  cache = cache or {}

  if not is_callable(f) then
    print(string.format(
            "Only functions and callable tables are memoizable. Received %s (a %s)",
             tostring(f), type(f)))
  end

  return function (...)
    local params = {...}

    local results = cache_get(cache, params)
    if not results then
      results = { f(...) }
      cache_put(cache, params, results)
      print("set","\n")
    end
    return unpack(results)
  end
end
local local_memoize = {}
setmetatable(local_memoize, { __call = function(_, ...) return memoize(...) end })



local M = {}
local function split(szFullString, szSeparator)  
    local nFindStartIndex = 1  
    local nSplitIndex = 1  
    local nSplitArray = {}
    while true do  
       local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
       if not nFindLastIndex then  
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
            break  
       end  
       nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
       nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
       nSplitIndex = nSplitIndex + 1  
    end
    return nSplitArray
end
function M.split(str, split)
    local list = {}
    local pos = 1
    if string.find("", split, 1) then -- this would result in endless loops
    error("split matches empty string!")
    end
    while true do
        local first, last = string.find(str, split, pos)
        if first then
            table_insert(list, string.sub(str, pos, first - 1))
            pos = last + 1
        else
            table_insert(list, string.sub(str, pos))
            break
        end
    end
    return list
end

local function splitToObj(str, split)
    local list = {}
    local pos = 1
    if string.find("", split, 1) then -- this would result in endless loops
    error("split matches empty string!")
    end
    while true do
        local first, last = string.find(str, split, pos)
        if first then
            local item = string.sub(str, pos, first - 1)
            if item~="" then list[item] = 1 end
            -- table_insert(list, string.sub(str, pos, first - 1))
            pos = last + 1
        else
            local item = string.sub(str, pos)
            if item~="" then list[item] = 1 end
            -- table_insert(list, string.sub(str, pos))
            break
        end
    end
    return list
end

-- 深拷贝
function M.copy(t, meta)
    local result = {}
    if meta then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = M.copy(v, nometa)
        else
            result[k] = v
        end
    end
    return result
end

-- 按哈希key排序
function M.spairs(t, cmp)
    local sort_keys = {}
    for k, v in pairs(t) do
        table.insert(sort_keys, {k, v})
    end
    local sf
    if cmp then
        sf = function (a, b) return cmp(a[1], b[1]) end
    else
        sf = function (a, b) return a[1] < b[1] end
    end
    table.sort(sort_keys, sf)

    return function (tb, index)
        local ni, v = next(tb, index)
        if ni then
            return ni, v[1], v[2]
        else
            return ni
        end
    end, sort_keys, nil
end

--反序列化
function M.unserialize(lua)
    local t = type(lua)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        --print("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = load(lua)
    if func == nil then
        return nil
    end
    return func()
end

--序列化
function M.serialize(obj, lvl)
    local lua = {}
    local t = type(obj)
    if t == "number" then
        table_insert(lua, obj)
    elseif t == "boolean" then
        table_insert(lua, tostring(obj))
    elseif t == "string" then
        table_insert(lua, string_format("%q", obj))
    elseif t == "table" then
        lvl = lvl or 0
        local lvls = ('  '):rep(lvl)
        local lvls2 = ('  '):rep(lvl + 1)
        table_insert(lua, "{\n")
        for k, v in pairs(obj) do
            table_insert(lua, lvls2)
            table_insert(lua, "[")
            table_insert(lua, M.serialize(k,lvl+1))
            table_insert(lua, "]=")
            table_insert(lua, M.serialize(v,lvl+1))
            table_insert(lua, ",\n")
        end
        local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
            for k, v in pairs(metatable.__index) do
                table_insert(lua, "[")
                table_insert(lua, M.serialize(k, lvl + 1))
                table_insert(lua, "]=")
                table_insert(lua, M.serialize(v, lvl + 1))
                table_insert(lua, ",\n")
            end
        end
        table_insert(lua, lvls)
        table_insert(lua, "}")
    elseif t == "nil" then
        return nil
    else
        --print("can not serialize a " .. t .. " type.")
    end
    return table_concat(lua, "")
end

function M.arr_concat(t1, t2)
    for i, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

function M.url_encode(s)
    s = string.gsub(s, "([^_^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
    return string.gsub(s, " ", "+")

--[[
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
]]
end

function M.url_decode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end  

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

-- 排序,
-- array:需要排序的数组，必须是连续的数字下标。
-- sortKeys :排序字段表  
local tableSort = function ( array, sortKeys )
    -- sortKeys = sortKeys
    if not sortKeys or not next(sortKeys) then
        print("no sortKey!")
        return array
    end
    local sortTime = #sortKeys
    local sortTypes = {[1]="ascending", [2]="descending"}   -- 1 升序， 2 降序

    local sortFunc = function(table1, table2)
        if not table1 or not table2 then 
            print("!!! can not sort array because have not element")
            return false
        end
        local sortContinue
        sortContinue = function ( index )
            if index > sortTime then return false end
            -- print("sortKeys........", sortKeys[index])
            local sortKey, sortType = sortKeys[index][1], sortKeys[index][2]
            sortType = sortType or 1
            sortType = sortTypes[sortType]

            local var1, var2 = table1[sortKey], table2[sortKey]
            if type(var1) ~= "boolean" and type(var2) ~= "boolean" then
                if sortType == "ascending" then
                    var1 = var1 or 9999999
                    var2 = var2 or 9999999
                else
                    var1 = var1 or -9999999
                    var2 = var2 or -9999999
                end
                if not var1 or not var2 then 
                    print("!!! can not sort array by key is", sortKey)
                    return false 
                end
            end
            local i = 1
            if type(var1) == "boolean" then var1 = var1 and i or -i end
            if type(var2) == "boolean" then var2 = var2 and i or -i end
            
            if type(var1) == "string" and  tonumber(var1) ~= nil and type(var2) == "string" and  tonumber(var2) ~= nil then
                var1 = tonumber(var1)
                var2 = tonumber(var2)
            end

            if var1 == var2 then
                index = index + 1
                return sortContinue(index)
            else
                if sortType == "ascending" then
                    return var1 < var2
                else
                    return var1 > var2
                end
            end
        end
        return sortContinue(1)
    end
    table.sort(array, sortFunc)
    return array
end

local function MergeTables(...)
    local tabs = {...}
    if not tabs then
        return {}
    end
    local origin = tabs[1]
    for i = 2,#tabs do
        if origin then
            if tabs[i] then
                for k,v in pairs(tabs[i]) do
                    table.insert(origin,v)
                end
            end
        else
            origin = tabs[i]
        end
    end
    return origin
end

-- Your code snippet

local tpl = {
	{["id"]=1,["name"]="123",["age"]="a"},
	{["id"]=2,["name"]="123",["age"]="ca"},
	{["id"]=0,["name"]="123",["age"]="db"},
	{["id"]=4,["name"]="123",["age"]="bb"},
    {["id"]=8,["name"]="123",["age"]="1"},
    {["id"]=5,["name"]="123",["age"]="100"},
    {["id"]=6,["name"]="123",["age"]="5"},
}

local memoize_splitToObj = local_memoize(splitToObj)

local begin =os.clock()
for i=1,100000 do
memoize_splitToObj("1,3,4,024,897,",",")
-- splitToObj("1,3,4,024,897,",",")
end
print(string.format("total time:%.2fms\n", ((os.clock() - begin) * 1000)))


local function add ( ... )
    print_r({...})
    -- for i, v in ipairs{...} do
    --     print(i, ' ',  v)
    -- end
end

local redisCacheExpire = '2'
local cache_expire = tonumber(redisCacheExpire) or 10

-- print_r(cache_expire)

local p = {1,2,3,4,5}
-- print_r(p)
-- add(222,unpack(p))
-- local a = {1,1,1,1,1,1,1}

-- a[1] = "test";
-- a[2] = "test";
-- a[3] = "test";
-- a["xxx"] = "test";
-- a["xx"] = "test";
-- a[6] = "test";
-- a[9] = "test";
-- print_r(a)
-- local orderBy = cjson.decode('[["age",1],["id",1]]')
-- tpl = tableSort(tpl,orderBy)

-- local x
-- local ok ,e = pcall(function()
--    x = cjson.decode('1231xxx')
-- end)
-- print(ok)
-- print(x)
-- print_r(tpl)
-- local a =xpcall(cjson.decode('{发的是放假了圣诞节}'))
-- print(a)
-- local a = "121321sb"
-- local b = "1"
-- print(tonumber(a))
-- print(tonumber(a)==b)

-- -- print_r(MergeTables({1,2,3,4},{1,2,3,4},{4,5,6,7}))
-- print(string.format("total time:%.2fms\n", ((os.clock() - begin) * 1000)))

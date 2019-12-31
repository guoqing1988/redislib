local table_insert = table.insert
local table_concat = table.concat
local string_find = string.find
local string_sub = string.sub
local string_len = string.len
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
  setmetatable(cache, {__mode = "kv"}) -- make it weak
  if not is_callable(f) then
    print(string.format("Only functions and callable tables are memoizable. Received %s (a %s)",tostring(f), type(f)))
  end

  return function (...)
    local params = {...}

    local results = cache_get(cache, params)
    if not results then
      results = { f(...) }
      cache_put(cache, params, results)
    end

    return unpack(results)
  end
end
local local_memoize = {}
setmetatable(local_memoize, { __call = function(_, ...) return memoize(...) end })


local function split(str, split)
    local list = {}
    local pos = 1
    if string_find("", split, 1) then -- this would result in endless loops
        return list
    end
    while true do
        local first, last = string_find(str, split, pos)
        if first then
            table_insert(list, string_sub(str, pos, first - 1))
            pos = last + 1
        else
            table_insert(list, string_sub(str, pos))
            break
        end
    end
    return list
end

local function splitToObj(str, split)
    local list = {}
    local pos = 1
    if string_find("", split, 1) then -- this would result in endless loops
        return list
    end
    while true do
        local first, last = string_find(str, split, pos)
        if first then
            local item = string_sub(str, pos, first - 1)
            if item~="" then list[item] = 1 end
            pos = last + 1
        else
            local item = string_sub(str, pos)
            if item~="" then list[item] = 1 end
            break
        end
    end
    return list
end

-- 筛选器
local COMPARATORS
COMPARATORS = {
    ['>'] = function (a, b)  return tonumber(a) > tonumber(b) end, 
    ['>='] = function (a, b) return tonumber(a) >= tonumber(b) end,
    ['<'] = function (a, b) return tonumber(a) < tonumber(b) end,
    ['<='] = function (a, b) return tonumber(a) <= tonumber(b) end,
    ['!='] = function (a, b) return tostring(a) ~= tostring(b) end,
    ['eq'] = function (a, b) return tostring(a) == tostring(b) end,
    ['gt'] = function (a, b) return COMPARATORS[">"](a,b) end,
    ['gte'] = function (a, b) return COMPARATORS[">="](a,b) end,
    ['lt'] = function (a, b) return COMPARATORS["<"](a,b) end,
    ['lte'] = function (a, b) return COMPARATORS["<="](a,b) end,
    ['ne'] = function (a, b) return COMPARATORS["!="](a,b) end,
    ['between'] = function (a, b) return COMPARATORS[">="](a,b[1]) and COMPARATORS["<="](a,b[2]) end,
    ['find'] = function (a, b) return string_find(tostring(a),tostring(b)) ~= nil end,
    ['isarray'] = function (a) return type(a) == "table" and next(a) ~= nil end,
    ['like'] = function (a, b) return COMPARATORS.find(a, b) end,
    ['nlike'] = function (a, b) return COMPARATORS.find(a, b) == false end,
    ['in'] = function (a, b) return  COMPARATORS.isarray(b) and COMPARATORS.inarray(a,b) end,
    ['nin'] = function(a, b) return COMPARATORS['in'](a,b) == false end,
    ['inarray'] = function (a, b) 
        for k,v in pairs(b) do
          if tostring(v) == tostring(a) then
              return true;
          end
        end
        return false;
    end,
    -- 判断变量为空
    ['empty'] = function (a)
        if a == nil then
            return true
        elseif type(a) == "string" and string_len(a) == 0 then
            return true
        elseif type(a) == "table" and next(a) == nil then
            return true
        end
        return false
    end,
    -- 用逗号拆分要查询的字段 然后进行inarray操作
    ['inset'] = local_memoize(function(a, b)
        local arr
        if type(a) == 'table' then
            arr = a
        else
            arr = splitToObj(a,",")
        end
        if type(b) == 'string' or type(b) == 'number' then
            return arr[tostring(b)]~=nil
        elseif COMPARATORS.isarray(b) then
            for k,v in pairs(b) do
                if arr[tostring(v)] then
                    return true
                end
            end
        end
        return false
    end),
    -- 过滤table 生成一个新的table t table fields 保留key
    ['filterkey'] = function(t, fields)
        if COMPARATORS.isarray(fields) then
            local rtable = {}
            for i,v in ipairs(fields) do
                if t[v] ~= nil then
                    rtable[v] = t[v]
                end
            end
            return rtable
        else
            return t
        end
    end
}

local function executionTime(start)
    local endtime = redis.call('time')
    local t = tostring(((endtime[1]-start[1])*1000000 +endtime[2]-start[2])/1000)
    -- redis.log(redis.LOG_NOTICE,"命令时间:"..cjson.encode({start,endtime}))
    return t
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
                    table_insert(origin,v)
                end
            end
        else
            origin = tabs[i]
        end
    end
    return origin
end

local function filterJsonData(sourcedata,where)
    if sourcedata ~= nil and sourcedata ~= ""  then
        if COMPARATORS.isarray(where) then
            local data = sourcedata
            if type(sourcedata) == "string" then
                data = cjson.decode(sourcedata) 
            end
            -- redis.log(redis.LOG_NOTICE,"filterJsonData:".. cjson.encode(data) )

            for k,v in pairs(where) do
                if data[k] ~= nil then
                    if type(v) == "table" and next(v) ~= nil and #v == 2 then
                        if COMPARATORS[v[1]](data[k],v[2]) == false then
                            return false
                        end

                    elseif type(v) ~= "table" then
                        if COMPARATORS['eq'](data[k],v) == false then
                            return false
                        end
                    else
                        return false
                    end
                end
            end
        elseif type(where) == "string" and where ~= "" then
            if COMPARATORS['like'](sourcedata,where) == false then
                return false
            end
        else
            return false
        end
        return true
    end
    return false
end

local function filterData(jsondata,where,orderBy,limit,fields)
    if COMPARATORS.isarray(jsondata) then
        -- 对数据进行排序操作 支持多维排序
        if COMPARATORS.isarray(orderBy) then
            jsondata = tableSort(jsondata,orderBy)
        end

        local item = {}
        local limit_num = 1
        local sstime = redis.call('time')
        local iswhere = COMPARATORS.empty(where)
        limit = tonumber(limit)
        for kkk,vvv in pairs(jsondata) do

            if limit_num > limit then
                break
            end
            -- 使用mongodb查询模式 进行数据赛选
            if not iswhere then
                if filterJsonData(vvv,where) then
                    vvv = COMPARATORS.filterkey(vvv,fields)
                    table_insert(item,vvv)
                    limit_num = limit_num+1
                end
            else
                vvv = COMPARATORS.filterkey(vvv,fields)
                table_insert(item,vvv)
                limit_num = limit_num+1
            end
        end
        return item
    end
    return {}
end
local function json_decode(jsondata)
    local newdata = {}
    local ok ,e = pcall(function()
       newdata = cjson.decode(jsondata)
    end)
    return newdata
end
local function json_encode(data)
    return cjson.encode(data)
end
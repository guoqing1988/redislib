-- local cjson = require "cjson"


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

-- 筛选器
local COMPARATORS = {
    ['>'] = function (a, b)  return tonumber(a) > tonumber(b) end, 
    ['>='] = function (a, b) return tonumber(a) >= tonumber(b) end,
    ['<'] = function (a, b) return tonumber(a) < tonumber(b) end,
    ['<='] = function (a, b) return tonumber(a) <= tonumber(b) end,
    ['!='] = function (a, b) return tostring(a) ~= tostring(b) end,
    ['eq'] = function (a, b) return tostring(a) == tostring(b) end,
    ['find'] = function (a, b) return string.find(tostring(a),tostring(b)) ~= nil end,
    ['isarray'] = function (a) return type(a) == "table" and next(a) ~= nil end,
    ['inarray'] = function (a, b) 
        for k,v in pairs(b) do
          if tostring(v) == tostring(a) then
              return true;
          end
        end
        return false;
    end,
    ['empty'] = function (a)
        if a == nil then
            return true
        elseif type(a) == "string" and string.len(a) == 0 then
            return true
        elseif type(a) == "table" and next(a) == nil then
            return true
        end
        return false
    end
}
COMPARATORS['gt'] = function (a, b) return COMPARATORS[">"](a,b) end
COMPARATORS['gte'] = function (a, b) return COMPARATORS[">="](a,b) end
COMPARATORS['lt'] = function (a, b) return COMPARATORS["<"](a,b) end
COMPARATORS['lte'] = function (a, b) return COMPARATORS["<="](a,b) end
COMPARATORS['like'] = function (a, b) return COMPARATORS.find(a, b) end
COMPARATORS['nlike'] = function (a, b) return COMPARATORS.find(a, b) == false end
COMPARATORS['in'] = function (a, b) return  COMPARATORS.isarray(b) and COMPARATORS.inarray(a,b) end
COMPARATORS['nin'] = function(a, b) return COMPARATORS['in'](a,b) == false end

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

local function filterJsonData(sourcedata,where)
    if sourcedata ~= nil and sourcedata ~= ""  then
        if COMPARATORS.isarray(where) then
            local data = sourcedata
            if type(sourcedata) == "string" then
                data = cjson.decode(sourcedata) 
            end
            -- redis.log(redis.LOG_NOTICE,"filterJsonData:".. cjson.encode(data) )
            for i,v in pairs(data) do
                if where[i] ~= nil then
                    if type(where[i]) == "table" and next(where[i]) ~= nil and #where[i] == 2 then
                        if COMPARATORS[where[i][1]](v,where[i][2]) == false then
                            return false
                        end

                    elseif type(where[i]) ~= "table" then
                        print(v,where[i])
                        if COMPARATORS['eq'](v,where[i]) == false then
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

redis.log(redis.LOG_NOTICE,"ARGV:".. cjson.encode(ARGV))
redis.log(redis.LOG_NOTICE,"KEYS:".. cjson.encode(KEYS))


local isdebug = '{$debug}'
local values = {}
local where = cjson.decode(ARGV[1]) or {}
if where == 'findall' then where = {} end
local orderBy = ARGV[2] and cjson.decode(ARGV[2]) or {}
local limit = ARGV[3] and ARGV[3] or 1000
local sstr = split(KEYS[1],"---")
local cmd = sstr[1]
KEYS[1] = sstr[2]

redis.log(redis.LOG_NOTICE,"ARGV:".. cjson.encode(ARGV))
redis.log(redis.LOG_NOTICE,"KEYS:".. cjson.encode(KEYS))

redis.log(redis.LOG_NOTICE,"DATA:".. cjson.encode({["where"]=where,["orderby"]=orderBy,["limit"]=limit,["cmd"]=cmd}))

-- redis.log(redis.LOG_NOTICE,"ARGV[1]:".. ARGV[1])
-- redis.log(redis.LOG_NOTICE,"KEYS[1]:".. KEYS[1])
-- return {KEYS[1],ARGV[1],cjson.decode(ARGV[1])['test']}
-- return {json.decode(ARGV[1]),ARGV[1]}
-- return redis.call('hgetall',KEYS[1])[2];
for i,v in ipairs(KEYS) do 
    local jsondata  = redis.call(cmd,v);

    redis.log(redis.LOG_NOTICE,"hgetall:".. cjson.encode(jsondata) )
    redis.log(redis.LOG_NOTICE,"where:".. cjson.encode(where) )
    if COMPARATORS.isarray(jsondata) then
        local newdata = {}
        for kk,vv in ipairs(jsondata) do
            if kk%2 == 0 then
                -- redis.log(redis.LOG_NOTICE,"for newdata:".. cjson.encode({kk,vv}) )
                -- newdata[jsondata[kk-1]] = vv

                local t = cjson.decode(vv)
                t["_field_key"]=jsondata[kk-1]
                -- newdata[jsondata[kk-1]] = cjson.decode(vv)
                table.insert(newdata,t)
            end 
        end
        redis.log(redis.LOG_NOTICE,"newdata:".. cjson.encode(newdata) )
        if COMPARATORS.isarray(orderBy) then
            redis.log(redis.LOG_NOTICE,"orderBy:".. cjson.encode(orderBy) )

            newdata = tableSort(newdata,orderBy)
        end
        local item = {}
        local limit_num = 1
        for kkk,vvv in pairs(newdata) do
            redis.log(redis.LOG_NOTICE,"for newdata:".. cjson.encode({vvv["_field_key"],vvv,where}) )

            if limit_num > tonumber(limit) then
                break
            end

            if not COMPARATORS.empty(where) then
                if filterJsonData(vvv,where) then
                    redis.log(redis.LOG_NOTICE,"selected newdata:".. cjson.encode({vvv["_field_key"],vvv,where}) )
                    -- item[#item+1] = {kkk,vvv}

                    local field_key = vvv["_field_key"]
                    vvv["_field_key"] = nil

                    -- item[field_key] = cjson.encode(vvv)
                    item[field_key] = vvv
                    -- table.insert(item,field_key)
                    -- table.insert(item,cjson.encode(vvv))
                    limit_num = limit_num+1
                end
            else
                local field_key = vvv["_field_key"]
                vvv["_field_key"] = nil
                -- item[field_key] = cjson.encode(vvv)
                item[field_key] = vvv
                -- table.insert(item,field_key)
                -- table.insert(item,cjson.encode(vvv))
                limit_num = limit_num+1
            end
        end
        values[#values+1] = cjson.encode(item)
    end
end
return {KEYS,values};
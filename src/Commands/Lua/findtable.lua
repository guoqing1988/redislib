-- local cjson = require "cjson"
local begintime = redis.call('time')
local isdebug = '{$debug}'
local isNoCache = '{$isNoCache}'
local redisCacheExpire = '{$redisCacheExpire}'
local values = {}
local timemap = {["total_time"]=0,["data_create_time"]=0,["cmd_time"]=0,["filter_time"]=0}
local where = cjson.decode(ARGV[1]) or {}
if where == 'findall' then where = {} end
local orderBy = ARGV[2] and cjson.decode(ARGV[2]) or {}
local limit = ARGV[3] and ARGV[3] or 1000
local fields = ARGV[4] and cjson.decode(ARGV[4]) or {}
local maxlen = 1000
local field_where = {}

-- redis.log(redis.LOG_NOTICE,"ARGV:".. cjson.encode(ARGV))
-- redis.log(redis.LOG_NOTICE,"KEYS:".. cjson.encode(KEYS))

local Params = {["field_where"]=field_where,["where"]=where,["orderby"]=orderBy,["limit"]=limit,["cmd"]=KEYS[1],['fields']=fields}
local sha1_key = redis.sha1hex(cjson.encode(Params))

if isdebug ~= "no" then
    redis.log(redis.LOG_NOTICE,"KEYS:"..cjson.encode(KEYS).." Params:".. cjson.encode(Params)..sha1_key)
end
local cache_key = "rdb:cache:"
local cache_expire = tonumber(redisCacheExpire) or 10
if isNoCache ~= "yes" then
    local res = redis.call('get',cache_key..sha1_key);
    if res ~= false then
        timemap["total_time"] = executionTime(begintime)
        do return {KEYS,{res},json_encode(timemap)} end 
    end
end
-- local fields_isarray = COMPARATORS.isarray(fields);
for i,v in ipairs(KEYS) do
    local listdata = {}
    local sstime = redis.call('time')
    local ids = redis.call('zrange', v, 0, -1)
    timemap["cmd_time"] = executionTime(sstime)

    sstime = redis.call('time')
    local limit_num = 1
    limit = tonumber(limit)
    for ii,vv in ipairs(ids) do
        if limit_num > limit then
            break
        end
        -- if fields_isarray then
        --     item = redis.call('hmget',v..":"..vv,unpack(fields))
        -- else
        local item = redis.call('hgetall',v..":"..vv)
        -- end
        -- redis.log(redis.LOG_NOTICE, json_encode(item))
        local iswhere = COMPARATORS.empty(where)
        if item ~= nil then 
            local itemarr = {}
            local j=1
            while j<#item do
                itemarr[item[j]] = item[j+1]
                j=j+2
            end

            -- 使用mongodb查询模式 进行数据赛选
            -- if not iswhere then
            --     if filterJsonData(itemarr,where) then
            --         itemarr = COMPARATORS.filterkey(itemarr,fields)
            --         table.insert(listdata,itemarr)
            --         limit_num = limit_num+1
            --     end
            -- else
            --     itemarr = COMPARATORS.filterkey(itemarr,fields)
            --     table.insert(listdata,itemarr)
            --     limit_num = limit_num+1
            -- end

            table.insert(listdata,itemarr)
        end
    end

    timemap["data_create_time"] = executionTime(sstime)

    sstime = redis.call('time')
    -- values[#values+1] = cjson.encode(listdata)
    values[#values+1] = cjson.encode(filterData(listdata,where,orderBy,limit,fields))
    redis.replicate_commands()
    redis.call('set',cache_key..sha1_key,values[1],"EX",cache_expire);
    timemap["filter_time"] = executionTime(sstime)
    -- redis.log(redis.LOG_NOTICE,"筛选时间:"..executionTime(sstime).."ms")
end
timemap["total_time"] = executionTime(begintime)
return {KEYS,values,json_encode(timemap)};
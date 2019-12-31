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
if COMPARATORS.isarray(where) and where['field_where'] ~= nil then
    field_where = where['field_where']
    where['field_where'] = nil
end

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

for i,v in ipairs(KEYS) do
    local len = redis.call('hlen',v);
    local jsondata = {}

    -- 如果hash中数据大于设置最大值 使用hscan 进行获取 数据,获取数量为 设置的最大值,否则使用 hgetall
    local sstime = redis.call('time')
    if COMPARATORS.isarray(field_where) then
        for ii,vv in ipairs(field_where) do
            local rdata = redis.call('hget',v,vv);
            if rdata then
                table.insert(jsondata,vv)
                table.insert(jsondata,rdata)
            end
        end
    elseif len > maxlen then
        local cursor = 0
        local is_break = 0
        repeat
            local rdata = redis.call('hscan',v,cursor);
            -- redis.log(redis.LOG_NOTICE,"rdata:".. cjson.encode(rdata) )
            cursor = tonumber(rdata[1])
            if not COMPARATORS.empty(rdata[2]) then
                for kkk,vvv in pairs(rdata[2]) do
                    table.insert(jsondata,vvv)
                    if #jsondata > 1000 then
                        is_break = 1
                        break
                    end
                end
            end
            if is_break == 1 then
                break
            end
        until( cursor <= 0 )
    else
        jsondata = redis.call('hgetall',v);
    end

    timemap["cmd_time"] = executionTime(sstime)
    sstime = redis.call('time')
    -- 数据重组 变成table 数组
    local newdata = {}
    local j=1
    while j<#jsondata do
        -- local t = 
        table.insert(newdata,json_decode(jsondata[j+1]))
        j=j+2
    end
    timemap["data_create_time"] = executionTime(sstime)
    sstime = redis.call('time')
    values[#values+1] = cjson.encode(filterData(newdata,where,orderBy,limit,fields))
    redis.replicate_commands()
    redis.call('set',cache_key..sha1_key,values[1],"EX",cache_expire);
    timemap["filter_time"] = executionTime(sstime)
end
timemap["total_time"] = executionTime(begintime)
return {KEYS,values,json_encode(timemap)};
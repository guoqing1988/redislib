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

for i,v in ipairs(KEYS) do
    local jsondata = {}
    local begincmdtime = redis.call('time')
    jsondata = redis.call('get',v)
    timemap["cmd_time"] = executionTime(begincmdtime)
    -- redis.log(redis.LOG_NOTICE,"命令执行时间:"..executionTime(begincmdtime).."ms")
    -- redis.log(redis.LOG_NOTICE,"jsondata:".. cjson.encode(jsondata) )
    local sstime = redis.call('time')
    local newdata = json_decode(jsondata)
    timemap["data_create_time"] = executionTime(sstime)
    -- redis.log(redis.LOG_NOTICE,"数据重组:"..executionTime(sstime).."ms")
    sstime = redis.call('time')
    values[#values+1] = cjson.encode(filterData(newdata,where,orderBy,limit,fields))
    redis.replicate_commands()
    redis.call('set',cache_key..sha1_key,values[1],"EX",cache_expire);
    timemap["filter_time"] = executionTime(sstime)
    -- redis.log(redis.LOG_NOTICE,"筛选时间:"..executionTime(sstime).."ms")
end
timemap["total_time"] = executionTime(begintime)
-- redis.log(redis.LOG_NOTICE,"脚本执行完成:"..executionTime(begintime).."ms")
return {KEYS,values,json_encode(timemap)};
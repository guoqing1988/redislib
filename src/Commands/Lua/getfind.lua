-- local cjson = require "cjson"
local begintime = redis.call('time')
-- redis.log(redis.LOG_NOTICE,"脚本开始执行"..cjson.encode(begintime))
local isdebug = '{$debug}'
local values = {}
local where = cjson.decode(ARGV[1]) or {}
if where == 'findall' then where = {} end
local orderBy = ARGV[2] and cjson.decode(ARGV[2]) or {}
local limit = ARGV[3] and ARGV[3] or 1000
local fields = ARGV[4] and cjson.decode(ARGV[4]) or {}
local maxlen = 1000

-- redis.log(redis.LOG_NOTICE,"ARGV:".. cjson.encode(ARGV))
-- redis.log(redis.LOG_NOTICE,"KEYS:".. cjson.encode(KEYS))

redis.log(redis.LOG_NOTICE,"KEYS:"..cjson.encode(KEYS).." Params:".. cjson.encode({["where"]=where,["orderby"]=orderBy,["limit"]=limit,["cmd"]=KEYS[1],['fields']=fields}))


for i,v in ipairs(KEYS) do
    local jsondata = {}
    local begincmdtime = redis.call('time')
    jsondata = redis.call('get',v)
    redis.log(redis.LOG_NOTICE,"命令执行时间:"..executionTime(begincmdtime).."ms")
    -- redis.log(redis.LOG_NOTICE,"jsondata:".. cjson.encode(jsondata) )
    local sstime = redis.call('time')
    local newdata = json_decode(jsondata)
    redis.log(redis.LOG_NOTICE,"数据重组:"..executionTime(sstime).."ms")

    values[#values+1] = cjson.encode(filterData(newdata,where,orderBy,limit,fields))
    redis.log(redis.LOG_NOTICE,"筛选时间:"..executionTime(sstime).."ms")
end
redis.log(redis.LOG_NOTICE,"脚本执行完成:"..executionTime(begintime).."ms")

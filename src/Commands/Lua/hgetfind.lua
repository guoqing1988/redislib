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
local field_where = {}
if COMPARATORS.isarray(where) and where['field_where'] ~= nil then
    field_where = where['field_where']
    where['field_where'] = nil
end

-- redis.log(redis.LOG_NOTICE,"ARGV:".. cjson.encode(ARGV))
-- redis.log(redis.LOG_NOTICE,"KEYS:".. cjson.encode(KEYS))

redis.log(redis.LOG_NOTICE,"KEYS:"..cjson.encode(KEYS).." Params:".. cjson.encode({["field_where"]=field_where,["where"]=where,["orderby"]=orderBy,["limit"]=limit,["cmd"]=KEYS[1],['fields']=fields}))

for i,v in ipairs(KEYS) do
    local len = redis.call('hlen',v);
    local jsondata = {}

    -- 如果hash中数据大于设置最大值 使用hscan 进行获取 数据,获取数量为 设置的最大值,否则使用 hgetall
    local begincmdtime = redis.call('time')
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
                    -- redis.log(redis.LOG_NOTICE,"jsondata count:".. cjson.encode(#jsondata) )
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
        -- values[#values+1] = cjson.encode(jsondata)
    else
        jsondata = redis.call('hgetall',v);
    end
    redis.log(redis.LOG_NOTICE,"命令执行时间:"..executionTime(begincmdtime).."ms")
    -- redis.log(redis.LOG_NOTICE,"jsondata:".. cjson.encode(jsondata) )
    local sstime = redis.call('time')
    -- 数据重组 变成table 数组
    local newdata = {}
    local j=1
    while j<#jsondata do
        -- local t = cjson.decode(jsondata[j+1])
        local t = json_decode(jsondata[j+1])
        t["_field_key"]=jsondata[j]
        table.insert(newdata,t)
        j=j+2
    end

    -- for kk,vv in ipairs(jsondata) do
    --     if kk%2 == 0 then
    --         local t = cjson.decode(vv)
    --         t["_field_key"]=jsondata[kk-1]
    --         table.insert(newdata,t)
    --     end 
    -- end
    redis.log(redis.LOG_NOTICE,"数据重组:"..executionTime(sstime).."ms")

    values[#values+1] = cjson.encode(filterData(newdata,where,orderBy,limit,fields))
    redis.log(redis.LOG_NOTICE,"筛选时间:"..executionTime(sstime).."ms")
end
redis.log(redis.LOG_NOTICE,"脚本执行完成:"..executionTime(begintime).."ms")
return {KEYS,values};
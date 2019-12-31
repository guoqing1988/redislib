<?php
namespace Wuhen\Redislib\Commands;

/**
 * Command for "hgetall"
 * Class HgetallCommand
 * @package Wuhen\Redislib\Commands
 */
class HgetallCommand extends Command
{
    public function getScript()
    {
        $script = <<<LUA
local function executionTime(start)
    local endtime = redis.call('time')
    local t = tostring(((endtime[1]-start[1])*1000000 +endtime[2]-start[2])/1000)
    redis.log(redis.LOG_NOTICE,"命令时间:"..cjson.encode({start,endtime}))
    return t
end
local begintime = redis.call('time')
local timemap = {}
local values = {}; 
for i,v in ipairs(KEYS) do 
    values[#values+1] = redis.call('hgetall',v); 
end 
timemap["total_time"] = executionTime(begintime)
return {KEYS,values,cjson.encode(timemap)};
LUA;
        return $script;
    }
}

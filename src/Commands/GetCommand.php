<?php
namespace Wuhen\Redislib\Commands;

class GetCommand extends Command
{
    public function getScript()
    {
        $script = <<<LUA
    local values = {}; 
    for i,v in ipairs(KEYS) do 
        values[#values+1] = redis.call('get',v); 
    end 
    return {KEYS,values};
LUA;
        return $script;
    }
}

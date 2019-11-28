<?php
namespace Wuhen\Redislib\Commands;

/**
 * Command for lrange
 * Class LrangeCommand
 * @package Wuhen\Redislib\Commands
 */
class LrangeCommand extends Command
{
    public function getScript()
    {
        $script = <<<LUA
    local values = {}; 
    for i,v in ipairs(KEYS) do 
        values[#values+1] = redis.call('lrange', v, 0, -1); 
    end 
    return {KEYS,values};
LUA;
        return $script;
    }
}

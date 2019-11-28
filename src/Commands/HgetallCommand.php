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
    local values = {}; 
    for i,v in ipairs(KEYS) do 
        values[#values+1] = redis.call('hgetall',v); 
    end 
    return {KEYS,values};
LUA;
        return $script;
    }
}

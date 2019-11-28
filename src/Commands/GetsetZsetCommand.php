<?php
namespace Wuhen\Redislib\Commands;

class GetsetZsetCommand extends Command
{
    public function getScript()
    {
        $luaSetTtl = $this->luaSetTtl($this->getTtl());
        $setTtl = $luaSetTtl ? 1 : 0;

        $script = <<<LUA
    local values = {}; 
    local setTtl = $setTtl;
    for i,v in ipairs(KEYS) do 
        local ttl = redis.call('ttl', v);
        values[#values+1] = redis.call('zrange', v, 0, -1); 
        redis.call('del',v);
        local j=1;
        while j<#ARGV do
            redis.call('zadd',v,ARGV[j],ARGV[j+1]);
            j=j+2
        end
        if setTtl == 1 then
            $luaSetTtl
        elseif ttl >= 0 then
            redis.call('expire',v,ttl)
        end
    end 
    return {KEYS,values};
LUA;
        return $script;
    }
}

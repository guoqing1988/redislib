<?php
namespace Wuhen\Redislib\Commands;

class HmsetCommand extends Command
{
    public function getScript()
    {
        $luaSetTtl = $this->luaSetTtl($this->getTtl());
        $setTtl = $luaSetTtl ? 1 : 0;
        $checkExist = $this->existenceScript;
        $delScript = $this->deleteScript;

        $script = <<<LUA
$checkExist
local values = {}; 
local setTtl = '$setTtl';
for i,v in ipairs(KEYS) do 
    local ttl = redis.call('ttl', v)
    $delScript
    local j=1
    while j<#ARGV do
        values[i]=redis.call('hset',v,ARGV[j],ARGV[j+1]); 
        j=j+2
    end
    if setTtl == '1' then
        $luaSetTtl
    elseif ttl > 0 then
        redis.call('expire', v, ttl);
    end
end
return {KEYS,values};
LUA;
        return $script;
    }
}

<?php
namespace Wuhen\Redislib\Commands;

/**
 * Command for "Hgetfind"
 * Class HgetallCommand
 * @package Wuhen\Redislib\Commands
 */
class HgetfindCommand extends Command
{
    public function getScript()
    {
        $script = file_get_contents(__DIR__."/Lua/".strtolower($this->getCommandName()).".lua");
        return $script;
    }
}

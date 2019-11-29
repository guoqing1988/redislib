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

    /**
     * @param array $data
     * @return array
     */
    public function parseResponse($data)
    {
    	$data = parent::parseResponse($data);
        if( $data ){
        	if( count($data) == 1 ){
        		$data = json_decode(current($data),1);
        	}else{
        		foreach ($data as &$value) {
        			$value = json_decode($value,1);
        		}
        	}
        }
    	
        return $data;
    }
}

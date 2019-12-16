<?php
namespace Wuhen\Redislib\Commands;

/**
 * Command for "getfind"
 * Class GetfindCommand
 * @package Wuhen\Redislib\Commands
 */
class GetfindCommand extends Command
{
    public function getScript()
    {
        $script = $this->luaUtils();
        $script .= $this->getLuaCode($this->getCommandName());
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

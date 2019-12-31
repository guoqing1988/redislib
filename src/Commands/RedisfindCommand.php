<?php
namespace Wuhen\Redislib\Commands;

/**
 * Command for "getfind"
 * Class GetfindCommand
 * @package Wuhen\Redislib\Commands
 */
class RedisfindCommand extends Command
{
    public function getScript()
    {
        $script = $this->luaUtils();
        $script .= $this->getLuaCode($this->getCommandName());
        foreach ($this->getRedisVariable() as $key => $value) {
            $script = str_replace('{$'.$key.'}',$value,$script);
        }
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

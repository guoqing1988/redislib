<?php
namespace Wuhen\Redislib\Commands;
use \Exception;
use Wuhen\Redislib\Commands\Traits\Existence;
use Wuhen\Redislib\Model;
use Predis\Command\ScriptCommand;

/**
 * Lua script command
 *
 * Class Command
 * @package Wuhen\Redislib\Commands
 */
abstract class Command
{
    use Existence;

    /**
     * Keys to manipulate
     * @var array
     */
    protected $keys;

    /**
     * Additional arguments
     * @var array
     */
    protected $arguments;

    /**
     * Lua script
     * @var string
     */
    protected $script;

    /**
     * Keys ttl in second
     * @var
     */
    protected $ttl;    

    /**
     * command name
     * @var string
     */
    protected $commandName;

    /**
     * Command constructor.
     * @param array $keys
     * @param array $args
     */
    public function __construct($keys = [], $args = [],$command = "")
    {
        $this->keys = $keys;
        $this->arguments = $args;
        $this->commandName = $command;
    }

    public function getCommandName()
    {
        return $this->commandName;
    }

    public function getArguments()
    {
        foreach ($this->arguments as &$value) {
            if( $value && is_array($value) ){
                $value = json_encode($value,256);
            }
        }
        return array_merge($this->keys, $this->arguments);
    }

    public function getKeysCount()
    {
        return count($this->keys);
    }

    /**
     * Set keys ttl
     * @param int $seconds
     * @return $this
     */
    public function setTtl($seconds)
    {
        $this->ttl = $seconds;

        return $this;
    }

    /**
     * @return mixed
     */
    public function getTtl()
    {
        return $this->ttl;
    }

    /**
     * Resolve data returned from "eval"
     *
     * @param $data
     * @return mixed
     * @throws Exception
     */
    function parseResponse($data)
    {
        if (empty($data)) {
            return [];
        }
        if (isset($data[0]) && count($data[0]) === $this->getKeysCount()) {
            $items = array_combine($data[0], $data[1]);
// print_r($items);
            return array_filter($items, [$this, 'notNil']);
        }

        throw new Exception('Error when evaluate lua script. Response is: ' . json_encode($data));
    }

    /**
     * @param $item
     * @return bool
     */
    protected function notNil($item)
    {
        return $item !== [] && $item !== null;
    }

    /**
     * @return string
     */
    protected function joinArguments()
    {
        $joined = '';

        for ($i = 1; $i <= count($this->arguments); $i++) {
            $joined .= "ARGV[$i],";
        }

        return rtrim($joined, ',');
    }

    protected function getTmpKey()
    {
        return uniqid('__wuhen__redilib__' . time() . '__' . rand(1, 1000) . '__');
    }

    protected function luaSetTtl($ttl)
    {
        if (!$ttl) {
            $script = '';
        } elseif ($ttl == Model::TTL_PERSIST) {
            $script = <<<LUA
redis.call('persist', v);
LUA;
        } else {
            $script = <<<LUA
redis.call('expire', v, $ttl);
LUA;
        }

        return $script;
    }
}

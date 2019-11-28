<?php
namespace Wuhen\Redislib;

use \Exception;

class RedisClient
{

    /**
     * @var \Redis
     */
    protected $_redis;

    public $config;


    function __construct($config)
    {
        $this->config = $config;
        $this->connect();
    }

    function connect()
    {
        try
        {
            $this->_redis = new \Redis();
            if (!empty($this->config['pconnect']))
            {
                $this->_redis->pconnect($this->config['host'], $this->config['port'], $this->config['timeout']);
            }
            else
            {
                $this->_redis->connect($this->config['host'], $this->config['port'], $this->config['timeout']);
            }
            
            if (!empty($this->config['password']))
            {
                $this->_redis->auth($this->config['password']);
            }
            if (!empty($this->config['database']))
            {
                $this->_redis->select($this->config['database']);
            }
        }
        catch (\RedisException $e)
        {
            throw new \RedisException(" Redis Exception, msg:".$e->getMessage()." code:".$e->getCode()." line :".__LINE__. " file: ".__FILE__, -1001);
            return false;
        }
    }

    function __call($method, $args = array())
    {
        $reConnect = false;
        while (1)
        {
            try
            {
                $result = call_user_func_array(array($this->_redis, $method), $args);
                $last_error = $this->_redis->getLastError();
                if( !$result &&  $last_error !== NULL ){
                    throw new \RedisException($last_error,-1002);
                }
            }
            catch (\RedisException $e)
            {
                if( $e->getCode() == -1002 ){
                    throw $e;
                }
                //已重连过，仍然报错
                if ($reConnect)
                {
                    throw $e;
                }

                if ($this->_redis->isConnected())
                {
                    $this->_redis->close();
                }
                $this->connect();
                $reConnect = true;
                continue;
            }
            return $result;
        }
    }

}
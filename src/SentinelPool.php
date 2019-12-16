<?php
namespace Wuhen\Redislib;
use Wuhen\Redislib\RedisClient;


/**
 * Class SentinelPool
 * @package Wuhen\Redislib\SentinelPool
 * @method sentinel getSentinel()
 * @method boolean addSentinel($host, $port)
 * @method
 */
class SentinelPool
{
    /**
     * @var Sentinel[]
     */
    protected $sentinels = array();

    protected $_redis_clients = [];

    protected $_config = [];
    /**
     * SentinelPool constructor.
     * @param array $sentinels [['host'=>'host', 'port'=>'port']]
     */
    public function __construct(array $config = array())
    {
        $this->_config = $config['sentinel'];
        foreach ($this->_config['list'] as $sentinel) {
            $this->addSentinel($sentinel['host'], $sentinel['port']);
        }
    }
    /**
     * add sentinel to sentinel pool
     *
     * @param string $host sentinel server host
     * @param int $port sentinel server port
     * @return bool
     */
    public function addSentinel($host, $port)
    {
        if ( $sentinel = new Sentinel(["host"=>$host,"port"=>$port,'pconnect'=>$this->_config['pconnect'],'timeout'=>$this->_config['timeout']]) ){
            $this->sentinels[] = $sentinel;
            return true;
        }
        return false;
    }

    public function getSentinel()
    {
        return array_rand($this->sentinels,1);
    }

    public function __call($name, $arguments)
    {
        foreach ($this->sentinels as $sentinel) {
            try {                
                $address = $sentinel->getMasterAddrByName($this->_config['name']);
                $redis_params = [
                    "host"=>$address['ip'],
                    "port"=>$address['port'],
                    'pconnect'=>$this->_config['pconnect'],
                    'timeout'=>$this->_config['timeout']
                ];
                $key = md5(print_r($redis_params,1));
                if( !isset($this->_redis_clients[$key]) ){
                    if ( !($this->_redis_clients[$key] = new RedisClient($redis_params)) ){
                        throw new \RedisException("connect to redis failed");
                    }
                }

                $sentinel = call_user_func_array(array($this->_redis_clients[$key], $name), $arguments);
                return $sentinel;
            } catch (\Exception $e) {
                if( $e->getCode() == -1002 ) throw new \Exception($e->getMessage(),-1002);
                $last_error_msg = $e->getMessage();
                $last_error_code = $e->getMessage();
                continue;
            }
        }
        throw new \Exception($last_error_msg?:'all sentinel failed',$last_error_code?:'-1009');
    }
}
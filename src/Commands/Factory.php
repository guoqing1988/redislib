<?php
namespace Wuhen\Redislib\Commands;

class Factory implements FactoryInterface
{
    /**
     * @param string $command redis command in lower case
     * @param array $keys KEYS for redis "eval" command
     * @param array $args ARGV for redis "eval" command
     * @return Command
     * @throws \Exception
     */
    public function getCommand($command, $keys = [], $args = [])
    {
        $instance = null;

        $className = __NAMESPACE__ . '\\' . ucfirst($command) . 'Command';

        if (class_exists($className)) {
            $instance = new $className($keys, $args ,$command);
            foreach ($this->redis_variable as $key => $value) {
                $instance->setRedisVariable($key,$value);
            }
            if (! $instance instanceof Command) {
                throw new \Exception("$className is not subclass of " . __NAMESPACE__ . '\\Command');
            }
        } else {
            throw new \Exception("$className not exists");
        }

        return $instance;
    }
    /**
     * [$redis_variable redis变量 ]
     * @var array ["debug"=>"0","isNoCache"=>"yes"]
     */
    protected $redis_variable = [];
    /**
     * [setRedisVariable 设置redis lua 变量]
     * @param [type] $key   [description]
     * @param [type] $value [description]
     */
    public function setRedisVariable($key,$value)
    {
        $this->redis_variable[$key] = $value;
        return $this;
    }


    /**
     * [getRedisVariable 获取设置的 redis lua 变量]
     * @param  string $key [description]
     * @return [type]      [description]
     */
    public function getRedisVariable($key='')
    {
        return $this->redis_variable[$key]??$this->redis_variable;
    }
}
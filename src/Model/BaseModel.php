<?php
namespace Wuhen\Redislib\Model;

use Wuhen\Redislib\Model;

class BaseModel extends Model
{
    protected function initRedisClient($parameters)
    {
        if (!isset($parameters['host'])) {
            $parameters['host'] = '127.0.0.1';
        }

        if (!isset($parameters['port'])) {
            $parameters['port'] = 6379;
        }

        if (!isset($parameters['database'])) {
            $parameters['database'] = 0;
        }

        if (!isset($parameters['timeout'])) {
            $parameters['timeout'] = 0.5;
        }

        parent::initRedisClient($parameters);
    }
}
<?php
namespace Wuhen\Redislib\Model;

class ZsetModel extends BaseModel
{
    protected $type = 'zset';

    protected $key = 'redisun:{id}:zset';
}
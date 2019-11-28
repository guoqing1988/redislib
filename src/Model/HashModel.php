<?php
namespace Wuhen\Redislib\Model;

class HashModel extends BaseModel
{
    protected $key = 'rdb:{name}:hash';

    protected $type = 'hash';
}
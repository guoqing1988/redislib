<?php
namespace Wuhen\Redislib\Model;

class HashModel extends BaseModel
{
    protected $key = 'redisun:{id}:hash';

    protected $type = 'hash';
}
<?php
namespace Wuhen\Redislib\Model;

class ListModel extends BaseModel
{
    protected $type = 'list';

    protected $key = 'redisun:{id}:list';
}
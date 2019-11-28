<?php

namespace Wuhen\Redislib\Model;


class SetModel extends BaseModel
{
    protected $type = 'set';

    protected $key = 'rdb:set:{id}:members';
}
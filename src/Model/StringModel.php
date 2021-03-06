<?php
namespace Wuhen\Redislib\Model;

class StringModel extends BaseModel
{
    protected $key = 'rdb:{name}:string';

    protected $type = 'string';

    protected $sortable = true;

    protected function compare($a, $b)
    {
        if ($a > $b) {
            return 1;
        } elseif ($a < $b) {
            return -1;
        } else {
            return 0;
        }
    }
}
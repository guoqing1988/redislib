<?php
namespace Wuhen\Redislib\Model;

class TableModel extends BaseModel
{
    protected $type = 'table';

    protected $primaryFieldName = "name";
    
    protected $key = 'rdb:{name}:table';

    public $sortField = "id";
}
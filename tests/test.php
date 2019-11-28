<?php
require 'bootstrap.php';


// $key = 'school:{schoolId}:class:{classId}:students';
// $builder = new Wuhen\Redislib\QueryBuilder($key);
// $builder->setFieldNeedle('schoolId', '{schoolId}');
// $builder->setFieldNeedle('classId', '{classId}');

// $keys = $builder->whereEqual('schoolId', 1)->whereEqual('classId', 2)->getQueryKeys();
// print_r($keys);
// exit;
// 
// 
// 
// if (!isset($parameters['host'])) {
//     $parameters['host'] = '127.0.0.1';
// }

// if (!isset($parameters['port'])) {
//     $parameters['port'] = 6379;
// }

// if (!isset($parameters['database'])) {
//     $parameters['database'] = 0;
// }

// if (!isset($parameters['timeout'])) {
//     $parameters['timeout'] = 0.5;
// }

// $redClient = new \Wuhen\Redislib\RedisClient($parameters);
// $a = $redClient->set('test','1232144555');
// var_dump($a);
// $a = $redClient->get('test');
// var_dump($a);
// exit;


$a = [
    'name' => 'martin',
    'age' => '22',
    'height' => '175',
    'nation' => 'China',
];
$b = [
    'name' => '刘嘻嘻嘻',
    'age' => '23',
    'height' => '176',
    'nation' => 'China',
];
$model = new \Wuhen\Redislib\Model\HashModel();
// $model->insert('test', $a);
for ($i=1; $i <=10 ; $i++) {
	$b['name'] .= $i;
	$b['age'] = rand(1,100);
	$b['id'] = $i;
	$v[$i] = $b;
}
// $model->create('test', $v);
// $res = $model->where('id','test')->findBatch(['test']);
$res = $model->where('id','test')->findInRedis(['name'=>['like','1']],[['age',1],['id',2]],5);

print_r($res);

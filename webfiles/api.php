<?php
  function getRealUserIp(){
    switch(true){
      case (!empty($_SERVER['HTTP_X_REAL_IP'])) : return $_SERVER['HTTP_X_REAL_IP'];
      case (!empty($_SERVER['HTTP_CLIENT_IP'])) : return $_SERVER['HTTP_CLIENT_IP'];
      case (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) : return $_SERVER['HTTP_X_FORWARDED_FOR'];
      default : return $_SERVER['REMOTE_ADDR'];
    }
 }

$settings = parse_ini_file('conf/settings.ini');

$servername = $settings['DatabaseIP'];
$username = $settings['DatabaseUser'];
$password = $settings['DatabasePass'];
$dbname = $settings['DatabaseName'];
$dbtable = $settings['DatabaseTableName'];
$dbport = $settings['DatabasePort'];
 
// get the HTTP method
$method = $_SERVER['REQUEST_METHOD'];


$input = json_decode(file_get_contents('php://input'),true);
 
// connect to the mysql database
$link = mysqli_connect($servername, $username, $password, $dbname, $dbport);
mysqli_set_charset($link,'utf8');


//Only extracts the body of the request and key from the path if updating, deleting or getting something from the database. Inserting a new row doesn't need a key in the path so this is not required.
if ($method=="GET" OR $method=="PUT" OR $method=="DELETE")
{	
	//Get the body of the request
	$request = explode('/', trim($_SERVER['PATH_INFO'],'/'));
	// retrieve the key from the path
	$key = array_shift($request)+0;
}

// escape the columns and values from the input object
$columns = preg_replace('/[^a-z0-9_]+/i','',array_keys($input));
$values = array_map(function ($value) use ($link) {
  if ($value===null) return null;
  return mysqli_real_escape_string($link,(string)$value);
},array_values($input));
 
// build the SET part of the SQL command
$set = '';
for ($i=0;$i<count($columns);$i++) {
  $set.=($i>0?',':'').'`'.$columns[$i].'`=';
  $set.=($values[$i]===null?'NULL':'"'.$values[$i].'"');
}
$set.=',`SourceIP`="'.getRealUserIp().'"';


 

// create SQL based on HTTP method
switch ($method) {
  case 'GET':
	$sql = "select * from ".$dbname.".".$dbtable.($key?" WHERE id=$key":''); break;
  case 'PUT':
    $sql = "update ".$dbname.".".$dbtable." set $set where id=$key"; break;
  case 'POST':
    $sql = "insert into ".$dbname.".".$dbtable." set $set"; break;
  case 'DELETE':
    $sql = "delete ".$dbname.".".$dbtable." where id=$key"; break;
}
 
// excecute SQL statement
$result = mysqli_query($link,$sql);
 
// die if SQL statement failed
if (!$result) {
  http_response_code(404);
  die(mysqli_error($link));
}
 
// print results, insert id or affected row count
if ($method == 'GET') {
  if (!$key) echo '[';
  for ($i=0;$i<mysqli_num_rows($result);$i++) {
    echo ($i>0?',':'').json_encode(mysqli_fetch_object($result));
  }
  if (!$key) echo ']';
} elseif ($method == 'POST') {
  echo mysqli_insert_id($link);
} else {
  echo mysqli_affected_rows($link);
}
 
// close mysql connection
mysqli_close($link);

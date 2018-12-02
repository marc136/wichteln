<?php


$debug = false;

$storage = 'data.json';
$data = NULL;
$passwords_file = 'pass.json';

if (!file_exists($passwords_file)) {
  file_put_contents($passwords_file, '{}');
}

$names = [ "One", "Two", "Three", "Four"];


require_once('passwords.php');

$post_data = filter_input_array(INPUT_POST);
if ($debug) var_dump($post_data);
$name = $post_data['name'];

$show = valid_password();
$partner = ($show) ? get_partner() : NULL;

$array = array('partner' => $partner, 'name' => $name);
$array['valid_password'] = $show;
$array['post_data'] = $post_data;
if ($debug) var_dump($array);

if (!$partner) {
    http_response_code(401);
}
header('Content-type: application/json');
echo json_encode($array);
exit();

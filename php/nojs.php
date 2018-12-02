<?php


$debug = false;

$storage = 'data.json';
$data = NULL;
$passwords_file = 'pass.json';

if (!file_exists($passwords_file)) {
  file_put_contents($passwords_file, '{}');
}

$names = [ "One", "Two", "Three", "Four"];


if ($_POST) {
  require('verify.php');
  // check login
  // display partner
} else {
  // display login form

  require('login.php');
  // exit('hagge');
}


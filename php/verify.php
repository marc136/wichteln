<?php
require_once('passwords.php');

$post_data = filter_input_array(INPUT_POST);
if ($debug) var_dump($post_data);
$name = $post_data['name'];

$show = valid_password();
$partner = ($show) ? get_partner() : NULL;

if ($debug) var_dump(array('partner' => $partner, 'name' => $name));

?>

<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <title>Wichteln</title>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/css/bootstrap.min.css" integrity="sha384-PsH8R72JQ3SOdhVi3uxftmaW6Vc51MKb0q5P2rRUpPvrszuE4W1povHYgTpBfshb" crossorigin="anonymous">

  <link rel="stylesheet" href="style.css">
</head>
<body class="">
  <div class="container">
    <div class="row align-items-center fullsize">
      <form class="col">

        <?php if ($show) { ?>
          <script>
            window.wichteln = { partner: <?php echo $partner; ?>}
          </script>

          <h3>Hallo, <?php echo($name); ?>, Du darfst </h3>
          <h1 class="green"><?php echo($partner); ?></h1>
          <h3>beschenken.</h3>
        <?php } else { ?>
          <h3>Passwort falsch.</h3>
          <a class="form-control btn btn-primary" href="./">Nochmal versuchen</a>
        <?php } ?>
      </form>
    </div>
  </div>
</body>
</html>
<?php

shuffle($names);

function to_option($name) {
  return "<option value=\"$name\">$name</option>";
}

$options = implode("\n", array_map("to_option", $names));

if (!isset($self)) {
  $self = $_SERVER['PHP_SELF'];
}

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
      <form class="col" action="<?php echo $self; ?>" method="POST">
        <h1 class="green">Wichteln</h1>
        <p>Damit keiner spicken kann, wen Du gezogen hast, musst Du ein Passwort vergeben.</p>
        <p>Danach kannst Du Deinen Wichtel ziehen.<br />
        Mit dem Passwort kannst Du dann jederzeit nochmal schauen, wen Du beschenken darfst.</p>
        <div class="form-row">
          <div class="col">
            <select class="form-control" name="name">
              <?php echo($options) ?>
            </select>
          </div>
          <div class="col">
            <input class="form-control" type="password" name="password" maxlength="255" placeholder="Passwort" required />
          </div>
          <div class="col">
            <input class="form-control btn btn-primary" type="submit" value="Anmelden" />
          </div>
        </div>
      </form>
    </div>
</div>
</body>
</html>
<?php

require_once("/etc/wikimo/config.php");

$mysqli = new mysqli($SECRETS_wgDBserver, $SECRETS_wgDBuser, $SECRETS_wgDBpassword, $SECRETS_wgDBname);
if (!$mysqli) {
    http_response_code(500);
    echo "Can't connect to the database";
    exit;
}

/* check if server is alive */
if (!$mysqli->ping()) {
    http_response_code(500);
    echo "Database ping failed";
    exit;
}

echo "All Checks : OK";

?>

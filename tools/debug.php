<?php
# Drop this file in the core folder and reload your web server
#+ LocalSettings.php will automatically pick it up.
#
# NOTE: You do not want to do this in production.

error_reporting( -1 );
ini_set( 'display_errors', 1 );
$wgShowExceptionDetails = true;
$wgDebugToolbar = true;
$wgShowDebug = true;
$wgDevelopmentWarnings = true;
$wgShowSQLErrors = true;
$wgDebugDumpSql  = true;

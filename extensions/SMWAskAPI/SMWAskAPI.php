<?php

/**
 * Initializing file for Semantic MediaWiki Ask API extension.
 *
 * @file
 * @ingroup SMWAskAPI
 * @author pierremz
 */

if ( !defined( 'MEDIAWIKI' ) ) {
	die( 'Not an entry point.' );
}

define( 'SMWASKAPI_VERSION', '0.9 alpha' );

$smwaskgIP = dirname( __FILE__ );

include_once( "$smwaskgIP/api/SMWAsk_API.php" );

global $wgExtensionCredits;

$wgExtensionCredits[defined( 'SEMANTIC_EXTENSION_TYPE' ) ? 'semantic' : 'other'][] = array(
	'path' => __FILE__,
	'name' => 'SMWAskAPI',
	'version' => SMWASKAPI_VERSION,
	'author' => array( '[https://sourceforge.net/users/pierremz Pierre Mz]' ),
	'url' => 'https://sourceforge.net/projects/smwaskapi/',
	'description' => 'API for executing semantic queries (#ask) in Semantic MediaWiki'
);
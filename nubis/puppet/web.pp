class { 'nubis_apache':
    # Changing the Apache mpm is necessary for the Apache PHP module
    mpm_module_type => 'prefork',
    check_url       => '/?redirect=0',
    port            => 81,
}

# Add modules
class { 'apache::mod::rewrite': }
class { 'apache::mod::proxy': }
class { 'apache::mod::proxy_http': }
class { 'apache::mod::php': }

apache::vhost { $project_name:
    port               => 81,
    default_vhost      => true,
    docroot            => "/var/www/${project_name}/core",
    docroot_owner      => 'root',
    docroot_group      => 'root',
    block              => ['scm'],
    setenvif           => [
      'X-Forwarded-Proto https HTTPS=on',
      'Remote_Addr 127\.0\.0\.1 internal',
    ],
    access_log_env_var => '!internal',
    access_log_format  => '%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"',
    custom_fragment    => "
        # Use modification time and size for etags
        FileETag MTime Size

	# Detect private IP addresses
        SetEnvIfExpr \"-R '10.0.0.0/8' || -R '172.16.0.0/12' || -R '192.168.0.0/16'\" internal

	# Compress custom deflate types
	Include /etc/apache2/mods-enabled/deflate.conf
	Include /etc/apache2/mods-enabled/newrelic.conf
	AddOutputFilterByType DEFLATE text/javascript
    ",
    headers            => [
      # Nubis headers
      "set X-Nubis-Version ${project_version}",
      "set X-Nubis-Project ${project_name}",
      "set X-Nubis-Build   ${packer_build_name}",

      # Security Headers
      'set X-Content-Type-Options "nosniff"',
      'set X-XSS-Protection "1; mode=block"',
      'set X-Frame-Options "DENY"',
      'set Strict-Transport-Security "max-age=31536000"',
    ],

    aliases            => [
        {
            alias => '/images',
            path  => "/var/www/${project_name}/images",
        },
        {
            alias => '/assets',
            path  => "/var/www/${project_name}/assets",
        },
        {
            alias => '/extensions',
            path  => "/var/www/${project_name}/core/extensions",
        },
    ],

    rewrites           => [
      {
        comment      => 'Rewrite the old UseMod URLs to the new MediaWiki ones',
        rewrite_rule => ['^/AdminWiki(/.*|$) https://intranet.mozilla.org/%{QUERY_STRING} [R=permanent,L]'],
      },
      {
        comment      => 'Rewrite the old UseMod URLs to the new MediaWiki ones',
        rewrite_rule => ['^/PluginFutures(/.*|$) https://intranet.mozilla.org/PluginFutures$1 [R=permanent,L]'],
      },
      {
        comment      => 'This is for the ECMAScript 4 working group bug 324452',
        rewrite_rule => ['^/ECMA(/.*|$) https://intranet.mozilla.org/ECMA$1 [R=permanent,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/Mozilla2\.0([/\?].*|$) /wiki/Mozilla2:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/GeckoDev([/\?].*|$) /wiki/GeckoDev:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/XULDev([/\?].*|$) /wiki/XUL:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/Calendar([/\?].*|$) /wiki/Calendar:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/SVG([/\?].*|$) /wiki/SVG:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/SVGDev([/\?].*|$) /wiki/SVGDev:Home_Page? [R,L]'],
      },
      {
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/mozwiki https://wiki.mozilla.org/ [R,L]'],
      },
      {
        comment      => 'Redirect old /wiki/ urls',
        rewrite_rule => ['^/wiki/(.*)$ https://wiki.mozilla.org/$1 [R,L]'],
      },
      {
        comment      => 'Redirect old /wiki/ urls',
        rewrite_rule => ['^/wiki$ https://wiki.mozilla.org/index.php [R,L]'],
      },
      {
        comment      => 'Rewrite http://wiki.domain.tld/article properly, this is the main rule. Do not rewrite requests for files in MediaWiki subdirectories, php files, error docs, favicon and robot.txt',
        rewrite_cond => ['%{REQUEST_URI} !^/(assets|extensions|images|skins|resources)/',
                         '%{REQUEST_URI} !^/(redirect|index|opensearch_desc|api|load|thumb).php',
                         '%{REQUEST_URI} !^/error/(40(1|3|4)|500).html',
                         '%{REQUEST_URI} !^/favicon.ico',
                         '%{REQUEST_URI} !^/robots.txt',
                         '%{REQUEST_URI} !^/contribute.json'],
        rewrite_rule => ["^/(.*)\$ /var/www/wiki/core/index.php"],
      },
    ],
}


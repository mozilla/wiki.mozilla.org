class { 'nubis_apache':
    # One-time initial setup script to e.g. create DB schemas
    update_script_source => 'puppet://nubis/files/wiki_setup.sh',

    # Changing the Apache mpm is necessary for the Apache PHP module
    mpm_module_type => 'prefork',
}

# Add modules
class { 'apache::mod::rewrite': }
class { 'apache::mod::proxy': }
class { 'apache::mod::proxy_http': }

include nubis_configuration
nubis::configuration{ $project_name:
  format  => 'php',
}

apache::vhost { $project_name:
    port               => 80,
    default_vhost      => true,
    docroot            => "/var/www/$project_name/core",
    docroot_owner      => 'root',
    docroot_group      => 'root',
    block              => ['scm'],
    setenvif           => [
      'X-Forwarded-Proto https HTTPS=on',
      'Remote_Addr 127\.0\.0\.1 internal',
      'Remote_Addr ^10\. internal',
    ],
    access_log_env_var => '!internal',
    access_log_format  => '%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"',
    custom_fragment    => "
    # Don't set default expiry on anything
    ExpiresActive Off
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

    rewrites           => [
      {
        #    RewriteRule ^/AdminWiki(/.*|$) https://intranet.mozilla.org/%{QUERY_STRING} [R=permanent,L]
        comment      => 'Rewrite the old UseMod URLs to the new MediaWiki ones',
        rewrite_rule => ['^/AdminWiki(/.*|$) https://intranet.mozilla.org/%{QUERY_STRING} [R=permanent,L]'],
      },
      {
        #    RewriteRule ^/PluginFutures(/.*|$) https://intranet.mozilla.org/PluginFutures$1 [R=permanent,L]
        comment      => 'Rewrite the old UseMod URLs to the new MediaWiki ones',
        rewrite_rule => ['^/PluginFutures(/.*|$) https://intranet.mozilla.org/PluginFutures$1 [R=permanent,L]'],
      },
      {
        #    RewriteRule ^/ECMA(/.*|$) https://intranet.mozilla.org/ECMA$1 [R=permanent,L]
        comment      => 'This is for the ECMAScript 4 working group bug 324452',
        rewrite_rule => ['^/ECMA(/.*|$) https://intranet.mozilla.org/ECMA$1 [R=permanent,L]'],
      },
      {
        #    RewriteRule ^/Mozilla2\.0([/\?].*|$) /wiki/Mozilla2:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/Mozilla2\.0([/\?].*|$) /wiki/Mozilla2:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/GeckoDev([/\?].*|$) /wiki/GeckoDev:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/GeckoDev([/\?].*|$) /wiki/GeckoDev:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/XULDev([/\?].*|$) /wiki/XUL:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/XULDev([/\?].*|$) /wiki/XUL:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/Calendar([/\?].*|$) /wiki/Calendar:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/Calendar([/\?].*|$) /wiki/Calendar:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/SVG([/\?].*|$) /wiki/SVG:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/SVG([/\?].*|$) /wiki/SVG:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/SVGDev([/\?].*|$) /wiki/SVGDev:Home_Page? [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/SVGDev([/\?].*|$) /wiki/SVGDev:Home_Page? [R,L]'],
      },
      {
        #    RewriteRule ^/mozwiki https://wiki.mozilla.org/ [R,L]
        comment      => 'Old Wiki that has been moved into the public wiki',
        rewrite_rule => ['^/mozwiki https://wiki.mozilla.org/ [R,L]'],
      },
      {
        #    RewriteRule ^/wiki/(.*)$ https://wiki.mozilla.org/$1 [R,L]
        comment      => 'Redirect old /wiki/ urls',
        rewrite_rule => ['^/wiki/(.*)$ https://wiki.mozilla.org/$1 [R,L]'],
      },
      {
        #    RewriteRule ^/wiki$ https://wiki.mozilla.org/index.php [R,L]
        comment      => 'Redirect old /wiki/ urls',
        rewrite_rule => ['^/wiki$ https://wiki.mozilla.org/index.php [R,L]'],
      },
      {
        #    RewriteCond %{REQUEST_URI} !^/(assets|extensions|images|skins|resources)/
        #    RewriteCond %{REQUEST_URI} !^/(redirect|index|opensearch_desc|api|load|thumb).php
        #    RewriteCond %{REQUEST_URI} !^/error/(40(1|3|4)|500).html
        #    RewriteCond %{REQUEST_URI} !^/favicon.ico
        #    RewriteCond %{REQUEST_URI} !^/robots.txt
        #    RewriteRule ^/(.*)$ /data/www/wiki.mozilla.org/core/index.php?title=$1 [L,QSA]
        comment      => 'Do not rewrite requests for files in MediaWiki subdirectories, MediaWiki PHP files, HTTP error documents, favicon.ico, or robots.txt',
        rewrite_cond => ['%{REQUEST_URI} !^/(assets|extensions|images|skins|resources)/'],
        rewrite_cond => ['%{REQUEST_URI} !^/(redirect|index|opensearch_desc|api|load|thumb).php'],
        rewrite_cond => ['%{REQUEST_URI} !^/error/(40(1|3|4)|500).html'],
        rewrite_cond => ['%{REQUEST_URI} !^/favicon.ico'],
        rewrite_cond => ['%{REQUEST_URI} !^/robots.txt'],
        # Rewrite http://wiki.domain.tld/article properly, this is the main rule
        rewrite_rule => ['^/(.*)$ /data/www/wiki.mozilla.org/core/index.php?title=$1 [L,QSA]'],
      },
    ],


}


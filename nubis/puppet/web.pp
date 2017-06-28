class { 'nubis_apache':
}

# Add modules
class { 'apache::mod::rewrite': }
class { 'apache::mod::proxy': }
class { 'apache::mod::proxy_http': }

apache::vhost { $project_name:
    port               => 80,
    default_vhost      => true,
    docroot            => '/var/www/wiki.mozilla.org',
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
        comment      => 'Rewrite the old UseMod URLs to the new MediaWiki ones',
#        rewrite_cond => ['%{HTTP:X-Forwarded-Proto} =http'],
        rewrite_rule => ['^/AdminWiki(/.*|$) https://intranet.mozilla.org/%{QUERY_STRING} [R=permanent,L]'],
      }
    ],
#    # Rewrite the old UseMod URLs to the new MediaWiki ones
#    RewriteRule ^/AdminWiki(/.*|$) https://intranet.mozilla.org/%{QUERY_STRING} [R=permanent,L]


#    RewriteRule ^/PluginFutures(/.*|$) https://intranet.mozilla.org/PluginFutures$1 [R=permanent,L]
#
#    # This is for the ECMAScript 4 working group
#    # https://bugzilla.mozilla.org/show_bug.cgi?id=324452
#    RewriteRule ^/ECMA(/.*|$) https://intranet.mozilla.org/ECMA$1 [R=permanent,L]
#
#    # Old Wikis that have been moved into the public wiki
#    RewriteRule ^/Mozilla2\.0([/\?].*|$) /wiki/Mozilla2:Home_Page? [R,L]
#    RewriteRule ^/GeckoDev([/\?].*|$) /wiki/GeckoDev:Home_Page? [R,L]
#    RewriteRule ^/XULDev([/\?].*|$) /wiki/XUL:Home_Page? [R,L]
#    RewriteRule ^/Calendar([/\?].*|$) /wiki/Calendar:Home_Page? [R,L]
#    RewriteRule ^/SVG([/\?].*|$) /wiki/SVG:Home_Page? [R,L]
#    RewriteRule ^/SVGDev([/\?].*|$) /wiki/SVGDev:Home_Page? [R,L]
#    RewriteRule ^/mozwiki https://wiki.mozilla.org/ [R,L]
#
#    ###
#    ### The following rewrites are for PublicWiki, to make top-level page names work.
#    ### This section MUST be last to let all the other wikis keep working.
#    ###
#
#    # The following rules are only for backwards compatibility
#    # (so that old links to your site keep working). You should leave them out in a new install.
#    # Redirect old /wiki/ urls
#    RewriteRule ^/wiki/(.*)$ https://wiki.mozilla.org/$1 [R,L]
#    RewriteRule ^/wiki$ https://wiki.mozilla.org/index.php [R,L]
#    # end backward compatibility rules, the following ones are important
#
#
#    # Don't rewrite requests for files in MediaWiki subdirectories,
#    # MediaWiki PHP files, HTTP error documents, favicon.ico, or robots.txt
#    RewriteCond %{REQUEST_URI} !^/(assets|extensions|images|skins|resources)/
#    RewriteCond %{REQUEST_URI} !^/(redirect|index|opensearch_desc|api|load|thumb).php
#    RewriteCond %{REQUEST_URI} !^/error/(40(1|3|4)|500).html
#    RewriteCond %{REQUEST_URI} !^/favicon.ico
#    RewriteCond %{REQUEST_URI} !^/robots.txt
#
#    # Rewrite http://wiki.domain.tld/article properly, this is the main rule
#    RewriteRule ^/(.*)$ /data/www/wiki.mozilla.org/core/index.php?title=$1 [L,QSA]
}


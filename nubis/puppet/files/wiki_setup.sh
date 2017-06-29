# Setup symlinks so things are where they are expected
base_dir=/var/www/wiki.mozilla.org
storage=/data/www/wiki.mozilla.org
ln -s $base_dir/LocalSettings.php $base_dir/core/LocalSettings.php
[ ! -e $base_dir/core/skins/common/fonts ] && ln -s $base_dir/assets/fonts $base_dir/core/skins/common/fonts
[ ! -e $base_dir/images ] && ln -s $storage/images $base_dir/images
[ ! -e $base_dir/php_sessions ] && ln -s $storage/php_sessions $base_dir/php_sessions 
[ ! -e $base_dir/extensions/Bugzilla/Bugzilla_charts ] && ln -s $base_dir/extensions/Bugzilla/Bugzilla_charts $storage/Bugzilla_charts

# Do mediawiki setup steps such as DB migration, etc
(cd $base_dir && php tools/composer.phar install)
(cd $base_dir/core && php maintenance/update.php --quick)

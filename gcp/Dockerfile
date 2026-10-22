# MediaWiki 1.39 base image.
# Upstream dropped the EOL 1.39 branch (and docker.io/mediawiki:1.39 is frozen on
# PHP 8.3.29), so this stage is vendored from the last upstream 1.39 Dockerfile:
# https://github.com/wikimedia/mediawiki-docker/blob/24aafc7228dd3ea0f6d35bf250664f4c4569e1e3/1.39/apache/Dockerfile
# Pinned to PHP >= 8.3.36 for PHP2Shell (CVE-2026-109618, CVE-2026-109619).
FROM docker.io/php:8.3.36-apache AS mediawiki-base

# System dependencies
RUN set -eux; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
		librsvg2-bin \
		imagemagick \
		# Required for SyntaxHighlighting
		python3 \
	; \
	rm -rf /var/lib/apt/lists/*

# Install the PHP extensions we need
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libicu-dev \
		libonig-dev \
		liblua5.1-0-dev \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		calendar \
		intl \
		mbstring \
		mysqli \
		opcache \
	; \
	\
	pecl install APCu-5.1.28; \
	pecl install LuaSandbox-4.1.2; \
	docker-php-ext-enable \
		apcu \
		luasandbox \
	; \
	rm -r /tmp/pear; \
	\
	# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# Enable Short URLs
RUN set -eux; \
	a2enmod rewrite; \
	{ \
		echo "<Directory /var/www/html>"; \
		echo "  RewriteEngine On"; \
		echo "  RewriteCond %{REQUEST_FILENAME} !-f"; \
		echo "  RewriteCond %{REQUEST_FILENAME} !-d"; \
		echo "  RewriteRule ^ %{DOCUMENT_ROOT}/index.php [L]"; \
		echo "</Directory>"; \
	} > "$APACHE_CONFDIR/conf-available/short-url.conf"; \
	a2enconf short-url

# Enable AllowEncodedSlashes for VisualEditor
RUN sed -i "s/<\/VirtualHost>/\tAllowEncodedSlashes NoDecode\n<\/VirtualHost>/" "$APACHE_CONFDIR/sites-available/000-default.conf"

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# SQLite Directory Setup
RUN set -eux; \
	mkdir -p /var/www/data; \
	chown -R www-data:www-data /var/www/data

# Version
ENV MEDIAWIKI_MAJOR_VERSION=1.39
ENV MEDIAWIKI_VERSION=1.39.17

# MediaWiki setup
RUN set -eux; \
	fetchDeps=" \
		gnupg \
		dirmngr \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	\
	curl -fSL "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_MAJOR_VERSION}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz" -o mediawiki.tar.gz; \
	curl -fSL "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_MAJOR_VERSION}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz.sig" -o mediawiki.tar.gz.sig; \
	export GNUPGHOME="$(mktemp -d)"; \
	# gpg key from https://www.mediawiki.org/keys/keys.txt
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
		D7D6767D135A514BEB86E9BA75682B08E8A3FEC4 \
		441276E9CCD15F44F6D97D18C119E1A64D70938E \
		F7F780D82EBFB8A56556E7EE82403E59F9F8CD79 \
		1D98867E82982C8FE0ABC25F9B69B3109D3BB7B0 \
		E059C034E7A430583C252F4AA8F734246D73B586 \
	; \
	gpg --batch --verify mediawiki.tar.gz.sig mediawiki.tar.gz; \
	tar -x --strip-components=1 -f mediawiki.tar.gz; \
	gpgconf --kill all; \
	rm -r "$GNUPGHOME" mediawiki.tar.gz.sig mediawiki.tar.gz; \
	chown -R www-data:www-data extensions skins cache images; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
	rm -rf /var/lib/apt/lists/*

CMD ["apache2-foreground"]

# wikimo image.
FROM mediawiki-base
# Ensure this matches MEDIAWIKI_MAJOR_VERSION above.
ENV MWIKI_VER=39
WORKDIR /var/www/html/

ARG UID=10001
ARG GID=10001

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg unzip zlib1g-dev libpng-dev
RUN docker-php-ext-install gd

# Prepare for nonroot user
RUN groupadd -g $GID app; \
    useradd -g $GID -u $UID -m -s /usr/sbin/nologin app; \
    chown -R app:app /var/www/html/

USER app

RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount /var/www/html/extensions/ConfirmAccount
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/LabeledSectionTransclusion /var/www/html/extensions/LabeledSectionTransclusion
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler /var/www/html/extensions/TimedMediaHandler
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS /var/www/html/extensions/RSS
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms /var/www/html/extensions/PageForms
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters /var/www/html/extensions/UrlGetParameters
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /var/www/html/extensions/NoTitle
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets /var/www/html/extensions/Widgets
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend /var/www/html/extensions/MobileFrontend
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/SendGrid /var/www/html/extensions/SendGrid
RUN git clone --depth 1 --single-branch --branch main https://github.com/mozilla/mediawiki-bugzilla.git /var/www/html/extensions/Bugzilla

# Composer pinned to 2.8.12: 2.9+ blocks packages with security advisories by
# default, and MediaWiki 1.39 core pins some (guzzle 7.4.5, symfony/yaml 5.4.23).
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --version=2.8.12 && \
    php -r "unlink('composer-setup.php');"

COPY composer.local.json /var/www/html/composer.local.json
COPY ports.conf /etc/apache2/ports.conf
COPY LocalSettings.php /var/www/html/LocalSettings.php
COPY php.ini /usr/local/etc/php/php.ini
RUN php composer.phar update --no-dev

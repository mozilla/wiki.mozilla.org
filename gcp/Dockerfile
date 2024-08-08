# Ensure both post 1. numbers match here.
FROM docker.io/mediawiki:1.39
ENV MWIKI_VER=39
WORKDIR /var/www/html/

ARG UID=10001
ARG GID=10001

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg unzip

# Prepare for nonroot user
RUN groupadd -g $GID app; \
    useradd -g $GID -u $UID -m -s /usr/sbin/nologin app; \
    chown -R app:app /var/www/html/

USER app

RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount /var/www/html/extensions/ConfirmAccount

#extensions/googleAnalytics, do we need this?
#RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/googleAnalytics /var/www/html/extensions/googleAnalyics

RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/LabeledSectionTransclusion /var/www/html/extensions/LabeledSectionTransclusion
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler /var/www/html/extensions/TimedMediaHandler
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS /var/www/html/extensions/RSS
#extensions/Sandstone
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms /var/www/html/extensions/PageForms
#extensions/Smartsheet-MediaWiki-Extension need to replace/upgrade
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters /var/www/html/extensions/UrlGetParameters
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /var/www/html/extensions/NoTitle
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets /var/www/html/extensions/Widgets
RUN git clone --depth 1 --single-branch --branch REL1_${MWIKI_VER} https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend /var/www/html/extensions/MobileFrontend
#RUN git clone --depth 1 --single-branch --branch master https://github.com/mozilla/mediawiki-bugzilla.git /var/www/html/extensions/Bugzilla
#extensions/ImportFromEtherpad can we drop? requires pandoc
#extensions/MobileFrontend can we drop? vector has some mobile modes
#skins/GraphViz need replacement, do we even need?
#extensions/SemanticResultFormats composer
#extensions/SemanticMediaWiki composer
#extensions/SemanticWatchlist compose
#extensions/SubPageList composer
#skins/common/fonts/Fira do we need still? if so we need to update it

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');"

COPY composer.local.json /var/www/html/composer.local.json
RUN php composer.phar update --no-dev

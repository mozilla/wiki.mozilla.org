# wikimo test
## Dev Environment
Make sure to have the wikimo database dump downloaded into this folder.
Use `gsutil cp gs://wikimo-share/wiki.sql .` to do so.

Having this file, start the MariaDB container only using `docker compose up db`.
With the `wiki.sql` file being present, the container will autoimport the dump (which may take a while) and restart the database afterwards.

You can then start the whole setup using `docker compose up -d`, the wiki should be up and running then.

## "Runbook"

Use `docker compose up --build mediawiki` after changing the version in `Dockerfile`.

To migrate the `wiki.sql` dump to the latest version use the following path:

- switch the version in `Dockerfile` to `mediawiki:1.35` and update MWIKI_VER to match the point release number.
- Run `docker compose exec mediawiki php maintenance/update.php`

- switch the version in `Dockerfile` to `mediawiki:1.39` and update MWIKI_VER to match the point release number.
- Run `docker compose exec mediawiki php maintenance/update.php`
- Run `docker compose exec mediawiki php extensions/SemanticMediaWiki/maintenance/populateHashField.php`
- Run `docker compose exec mediawiki php extensions/SemanticMediaWiki/maintenance/rebuildData.php -v --with-maintenance-log` <- this takes a while, may not need? we should clean up spam before doing this

### Notes
- switch the version in `Dockerfile` to `mediawiki:1.xx` and update MWIKI_VER to match the point release number.
- Run `docker-compose exec mediawiki php maintenance/run.php update.php`

Make sure to mount the local `LocalSettings.php` into the container. It includes all required settings for `mediawiki:1.42.1` so far.

## Cleanup Scripts
Scripts that could be run on >=1.27
```shell
compose exec mediawiki php maintenance/deleteArchivedRevisions.php --delete
compose exec mediawiki php maintenance/removeUnusedAccounts.php --delete
```

## Migration Plan
1. Put the AWS Wiki into maintenance.
2. Dump the DB.
3. Import DB and images into GCP environment.
4. Deploy a 1.35 build to GCP.
5. Run `php maintenance/update.php` with 1.35.
6. Deploy a 1.39 build to GCP
7. Run `php maintenance/update.php` with 1.39
8. Run `php maintenance/deleteArchivedRevisions.php --delete`.
9. Run `php maintenance/removeUnusedAccounts.php --delete`.
10. Run `php maintenance/populateHashField.php`.
11. Run `php maintenance/rebuildData.php -v --with-maintenance-log`.
12. Check GCP version of wiki.
13. Update DNS to point to GCP Wiki.
14. Remove maintenance mode on GCP Wiki.
15. Clean up AWS Wiki (and optionally Nubis).
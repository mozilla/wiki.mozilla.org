# wikimo test

## "Runbook"

Use `docker compose up --build mediawiki` after changing the version in `Dockerfile`.

To migrate the db dump to the latest version use the following path:

- switch the version in `Dockerfile` to `mediawiki:1.35` and update MWIKI_VER to match the point release number.
- Set     "wikimedia/at-ease": "v2.1.0" to     "wikimedia/at-ease": "v2.0.0"
- Run `docker compose exec mediawiki php maintenance/update.php`

- switch the version in `Dockerfile` to `mediawiki:1.39` and update MWIKI_VER to match the point release number.
- Set     "wikimedia/at-ease": "v2.0.0" to     "wikimedia/at-ease": "v2.1.0"
- Run `docker compose exec mediawiki php maintenance/update.php`
- Run `docker compose exec mediawiki php extensions/SemanticMediaWiki/maintenance/populateHashField.php`
- Run `docker compose exec mediawiki php extensions/SemanticMediaWiki/maintenance/rebuildData.php -v --with-maintenance-log` <- this takes a while, may not need? we should clean up spam before doing this

### Notes
- switch the version in `Dockerfile` to `mediawiki:1.xx` and update MWIKI_VER to match the point release number.
- Run `docker-compose exec mediawiki php maintenance/run.php update.php`

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
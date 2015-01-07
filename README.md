wiki.mozilla.org
================

This is the deployment repository for the wiki.mozilla.org project. To find out more about this project please visit the [About](https://wiki-dev.allizom.org/MozillaWiki:About) page. To get involved with the project visit the [Team](https://wiki-dev.allizom.org/MozillaWiki:Team) page.

## Install
If you wish to have a local install of wiki.m.o including posts and content you will need to get the following datasets:
1. A copy of the production database*
2. A copy of the images directory
3. A copy of the extesnions/Bugzilla/charts directory**

\* There is talk of generating a sanitized (remove PII) database for convenience.
** This should not be the case. This extension should store its data in the images folder or in the temp file location as appropriate.

Once you have a copy of the aforementioned datasets you need to:
1. clone this repository
2. create a secrets.php file (see below)
3. run the install.sh script (found in the tools directroy)

## The secrets.php file
This file is where information specific to a particular deployment is stored. In hindsight I must admit that this is a poorly chosen name. This file should be self-explanatory. You can crib off of the -dist file or set environment variables in which case they will be automatically consumed.

## Updating core
MediaWiki core is installed as a submodule. To update it, simply follow your normal submodule workflow:
```bash
cd core
git checkout TAG
cd ../
git add core
git commit
git push
```

## Extensions
We are installing extensions in three separate ways
### The Subversion model
A few (two) extensions are available through Subversion only. These extensions are included fully. To update them you need to navigate into the extension's folder and issue an `svn up`. Then simply follow your usual procedure for committing upstream.
### The git submodule model
The majority of extensions are installed as git submodules. Simply follow normal submodule practice for this. In short:
- navagate to path/to/submodule directory
- `git checkout TAG`
- navagate to top level
- `git add path/to/submodule`
### The Composer model
Extensions installed with composer need to be updated using the `php tools/composer.phar` command. For information on usage of this command see the [Composer Documentation](https://getcomposer.org/doc/). There are several things to note about using Composer in conjunction with MediaWiki.
- While Composer normally installs in a directory named vendor, they are also duplicated on install to the extensions directory. These should not be checked into git and as such need to be added to the .gitignore file.
- You need to be sure to `git add composer.lock` file whenever you make changes to the `composer.json` manually or with the `composer.phar` command. This will avoid errors when setting up a fresh install.
- Composer automatically handles dependency resolution. Therefore you should not add any dependent extensions to the extensions directory.
- Extensions installed with Composer are automatically loaded through the `vendor/autoload.php` file and do not need to be included in the `LocalSettings.php` file.



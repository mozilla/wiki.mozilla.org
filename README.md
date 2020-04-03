wiki.mozilla.org
================

[![Build Status](https://travis-ci.com/mozilla-it/wiki.mozilla.org.svg?branch=master)](https://travis-ci.com/mozilla-it/wiki.mozilla.org)

This is the deployment repository for the [wiki.mozilla.org](https://wiki.mozilla.org) project. To find out more about this project please visit the [About](https://wiki.mozilla.org/MozillaWiki:About) page. To get involved with the project visit the [Team](https://wiki.mozilla.org/MozillaWiki:Team) page.

## Development
<details>
  <summary>Learn more.</summary>

### Prerequisites
  
* [php 7]()
* [composer]()

### MacOS Setup

This MacOS setup guide assumes the following of the machine:

* MacOS Catalina
* Homebrew

#### Install Composer

`brew install composer`

#### Install PHP

`brew install php@7.2`

</details>

## secrets.php
<details>
  <summary>Learn more.</summary>

### The secrets.php file

This file is where information specific to a particular deployment is stored. In hindsight I must admit that this is a poorly chosen name. This file should be self-explanatory. You can crib off of the -dist file or set environment variables in which case they will be automatically consumed.

</details>

## Core Updates
<details>
  <summary>Learn more.</summary>

### Updating core

MediaWiki core is installed as a submodule. To update it, simply follow your normal submodule workflow:
```bash
cd core
git checkout TAG
cd ../
git add core
git commit
git push
```
</details>

## Extensions
<details>
  <summary>Learn more.</summary>

We are installing extensions in three separate ways.

### The Subversion model
A few (two) extensions are available through Subversion only. These extensions are included fully. To update them you need to navigate into the extension's folder and issue an `svn up`. Then simply follow your usual procedure for committing upstream.
### The git submodule model
The majority of extensions are installed as git submodules. Simply follow normal submodule practice for this. In short:
- navagate to path/to/submodule directory
- `git checkout TAG`
- navagate to top level
- `git add path/to/submodule`
</details>

## The Composer Model
<details>
  <summary>Learn more.</summary>

Extensions installed with composer need to be updated using the `php tools/composer.phar` command. For information on usage of this command see the [Composer Documentation](https://getcomposer.org/doc/). There are several things to note about using Composer in conjunction with MediaWiki.
- While Composer normally installs in a directory named `vendor`, they are also duplicated on install to the `extensions` directory. These should not be checked into git and as such need to be added to the `.gitignore` file.
- You need to be sure to `git add composer.lock` file whenever you make changes to the `composer.json` manually or with the `composer.phar` command. This will avoid errors when setting up a fresh install.
- Composer automatically handles dependency resolution. Therefore you should not add any dependent extensions to the extensions directory.
- Extensions installed with Composer are automatically loaded through the `vendor/autoload.php` file and do not need to be included in the `LocalSettings.php` file.
</details>

## Author(s)

Stewart Henderson <shenderson@mozilla.com>
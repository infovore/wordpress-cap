wordpress-cap
=============

A pattern for deploying Wordpress sites via Capistrano.

REQUIREMENTS
------------

* your Wordpress site in a git repository (configuration details below)
* Ruby 1.8.7+ (might work on others, not tested)
* the following Ruby gems: capistrano, erubis, railsless-deploy
* a server you can SSH into. (This doesn't really work for shared hosting)

INSTALLATION
------------

You'll need to install the Rubygems above:

  sudo gem install capistrano
  sudo gem install erubis
  sudo gem install railsless-deploy

Then, put the contents of this repo into the ROOT of your wordpress site - the
config directory, the Capfile, and make sure advanced-cache.php.erb is in your
wp-content if you want to configure caching on deployment.

CONFIGURATION
-------------

You'll then need to configure your server for deployment. In your /var/www/site
directory - on the remote server - create two directories writeable by the user
you'll deploy as (as well as the web user): they should be called 'shared' and
'releases'.

The pattern of deployment is the usual Capistrano routine:

* all the code gets pushed out to a directory called releases/YYYYMMDDHHMMSS
* various files that should persist between deployments are symlinked from
  shared into this release directory.
* Finally, /var/www/site/current is symlinked to the latest release.

This being Wordpress, there are a few things we'd like to persist between
deployments:

* the wp-content/uploads directory
* the site configuration
* the cache configuration

To do this, there are some assumptions made about the configuration of your
site.

The single most important thing you must know:

**DO NOT CHECK YOUR wp-config.php INTO YOUR GIT REPOSITORY**

Seriously. Why not? Because this file is almost certainly DIFFERENT for every
environment. If you're running Wordpress on your laptop, wp-config.php will not
be the same as live. What you should do is:

* add wp-config.php to your .gitignore file
* put the wp-config.php for the live site into
  /var/www/site/shared/wp-config.php

We'll then symlink the correct wp-config.php into the site on live. One thing
that'll make this easier is defining the WP_HOME and WP_SITEURL constants in
your config file: this means you don't have defining these in the configuration
database.

Secondly, we don't want to lose our uploads folder on every deploy. So, again:

* add wp-content/uploads to your .gitignore
* move your uploads folder in its entirety to /var/www/site/shared/uploads
  , and make sure it's got the right permissions.

Then, on every deploy, we'll symlink uploads - and any new uploads will thus be
shared between releases.

CONFIGURING CACHING
-------------------

If you use caching on your site - which you probably should - it'd be good not
to lose our cache settings on every deploy. Most WordPress caching tools use the
ABSPATH constant, which disregards symlinks. However, Capistrano can tell us the
full release path when it deploys, so we can generate cache configuration as we
deploy.

I have had no luck making the popular WP Super Cache work with this. However,
I have successfully made [Hyper Cache] [1] work with this, so that's what we'll
do.

Install Hyper-Cache and set it up as normal. Then, add the
advanced-cache.php.erb file (included in this repo) to your local wp-content
directory. You might want to alter the .erb file to reflect the options you've
selected in your own Hyper Cache configuration. Finally, move your
wp-content/cache directory in its entirety - with correct permissions - to
/var/www/site/shared/cache .

To enable cache configuration, uncomment the two lines at the end of the
rakefile that enable the "symlink_hyper_cache" and "write_advanced_cache_template"
tasks. On each deployment, this will:

* symlink the cache directory to the latest release
* write out a new advanced-cache.php file that'll have the correct full release
  path in for caching

CONFIGURING PRESERVATION OF LEGACY FILES
----------------------------------------

Deploying with Capistrano means placing your entire site into version control.
That might not be appropriate: if you're like me, you've got a nice tidy
Wordpress site, and then a bucketload of other scripts and stuff from previous
sites. Don't worry! You don't need to put that junk into git if you don't want
to. Instead, place it all into /var/www/site/shared/legacy , and uncomment the
line in config/deploy.rb that enables the symlink_legacy_files task. Then, on
every deploy, everything in your legacy directory will be symlinked into your
site root - and it'll be just as it was before, except nicely, tidily deployed.

CONFIGURING APACHE
------------------

Needless to say, you'll now need to point your Apache DocumentRoot to
/var/www/site/current 


PERFORMING THE DEPLOYMENT
-------------------------

Once we've got everything configured, make sure all your code is pushed into
your remote git repository. Then, just type

  cap deploy

in a shell on your local machine, in the Wordpress site root, and everything
should get pushed out to your server in one fell swoop.

---

  [1]: http://wordpress.org/extend/plugins/hyper-cache/ "Hyper Cache"

﻿# ScholarSphere

ScholarSphere is a Ruby on Rails application utilizing the Blacklight and Hydra-head gems for integration with the search & indexing system, Solr, and the digital asset management platform, Fedora Commons.  The application runs on Fedora 3.4.2 and Solr 3.5.0.

ScholarSphere is being developed as part of
[Penn State's Digital Stewardship Program](http://stewardship.psu.edu/).
Development on ScholarSphere began as part of the prototype
[CAPS project](http://stewardship.psu.edu/2011/02/caps-a-curation-platform-prototype.html). Code
and documentation are freely available via [Github](http://github.com/psu-stewardship/scholarsphere).

For more information, read the [ScholarSphere development docs](https://github.com/psu-stewardship/scholarsphere/wiki).

## Install

Install system dependencies

 * libmysqlclient-dev (if running MySQL as RDBMS)
 * libsqlite3-dev (if running SQLite as RDBMS)
 * libmagick-dev
 * libmagickwand-dev
 * [FITS](http://code.google.com/p/fits/) -- put it in a
  directory on your PATH

Install gems

    bundle install

Copy and **edit** database, Fedora, and Solr configs

    cp config/database.yml.sample config/database.yml
    cp config/fedora.yml.sample config/fedora.yml
    cp config/solr.yml.sample config/solr.yml

(Re-)Generate the app's secret token

    rake secret:token

Create and migrate database

    rake db:create
    rake db:migrate

If you'll be *developing* ScholarSphere, setup test databases and load
fixture data

    RAILS_ENV=test rake db:create
    RAILS_ENV=test rake db:migrate
    RAILS_ENV=test rake scholarsphere:fixtures:generate
    RAILS_ENV=test rake scholarsphere:fixtures:refresh

To use the built-in Fedora and Solr instances, get the bundled hydra-jetty,
configure it, & fire it up

    git submodule init
    git submodule update
    rake jetty:config
    rake jetty:start

Start the delayed job workers (needed for characterization and audit services)

    script/delayed_job start

Run the app server

    rails server

Browse to http://localhost:3000/ and you should see ScholarSphere!

## Usage Notes

### Auditing All Datastreams

To audit the digital signatures of every version of every object in the
repository, run the following command

    RAILS_ENV=production script/audit_repository

You'll probably want to schedule this regularly (e.g., via cron) in production environments.

### Harvesting Authorities Locally

ScholarSphere supports "authority suggestion," a feature that links controlled
vocabularies to descriptive metadata elements.  This provides functionality both
for mapping string values to URIs and for populating dropdowns in metadata form
fields, e.g., if a user types "Cro" into a subject field, they might see a list
that includes "Croatian independence," the subject they were going to type out.

In order to avoid network latency, these vocabularies are harvested in advance
and stuffed into the ScholarSphere relational database for easy and quick lookups.

To get a sense for how this works, pull in database fixtures containing
pre-harvested authorities

    rake db:data:load

To harvest more authorities:

1. Harvest the authority (See available harvest tasks via `rake -T
scholarsphere:harvest`) -- N.B. depending on the size of the vocabulary, this
may take a *very* long time, especially if you're using a slower database such
as SQLite.
1. (OPTIONAL) Generate fixtures so other instances don't need to re-harvest (See
available database tasks via `rake -T db`)
1. Register the vocabulary with a domain term in generic_file_rdf_datastream.rb
(See the bottom of the file for examples)

## Contribute

1. Fork the codebase e.g. to https://github.com/your-username/scholarsphere
1. Clone your fork locally (`git clone
git@github.com:your-username/scholarsphere.git my-scholarsphere`)
1. Create a branch to hold your changes (`git checkout -b new-feature`)
1. Commit the changes you've made (`git commit -am "Some descriptive text around
what you've added"`)
1. Push your branch to github (`git push origin new-feature`)
1. Create a pull request e.g. at https://github.com/your-username/scholarsphere/pull/new/master

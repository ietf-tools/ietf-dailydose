<img src="https://raw.github.com/pasieronen/ietf-dailydose/master/static/dailydose_title.png">

# http://tools.ietf.org/dailydose/

## Internals

See [main.pl](scripts/main.pl) for details:

1. [download_data.pl](scripts/download_data.pl) downloads various data sources (using wget)
2. [check_data.pl](scripts/check_data.pl) checks if the data looks OK (and not e.g. truncated)
3. Next, each data source is processed:
  - For internet drafts, [draft_updates_atom.pl](scripts/draft_updates_atom.pl) compares data/(yesterday)/all_id.txt and data/(today)/all_id.txt, and writes an Atom feed containing interesting changes to data/(today)/draft_updates_atom.xml.
  - For RFC editor queue, [rfcq_progress_atom.pl](scripts/rfcq_progress_atom.pl) works similarly.
  - For all other data sources,
    - If necessary, a data source specific script (e.g. [liaisons_atom.pl](scripts/liaisons_atom.pl)) converts the data (in this case, a HTML page) to an Atom feed that contains all the data in the source. Some data sources, like IPR disclosures, are already in Atom format.
    - [atom_unread.pl](scripts/atom_unread.pl) checks with entries are new (by reading data/(yesterday)/liaisons_read.txt), writes a new Atom feed containing only the new entries (data/(today)/liaisons_unread.xml) and stores the updated state (to data/(today)/liaisons_read.txt).
4. [make_daily_content.pl](scripts/make_daily_content.pl) reads the Atom feeds (and all_id.txt/1id-abstract to get draft metadata), and formats the data in HTML to data/(today)/content_(left|right).txt.
5. [new_issue.pl](scripts/new_issue.pl) reads data/(today)/content_(left|right).txt and articles/schedule (a mostly unused feature nowadays), and writes (issue).html and (issue)_(left|right).html. These are the files served by Apache.
6. Finally, [update_feeds.pl](scripts/update_feeds.pl) generates Atom/RSS feeds for the issues, and [remove_old_data.pl](scripts/remove_old_data.pl) cleans data older than 14 days.

There's also an "admin" interface, basically a trivial CMS where you
can write articles/ads, and schedule them to appear on certain days,
but this feature has not been used in years.

About high availability: tools.ietf.org is actually multiple
servers. Each server runs Daily Dose independently, but the
/www/tools.ietf.org/dailydose/ directory is rsync'd from
merlot.tools.ietf.org to the other servers (overwriting anything they
might have generated earlier). Each server should be able to handle
errors (such as disk full or network problems), and recover once
merlot and the rsync is working again. This has complicated the logic
of handling yesterday's/today's data, issue numbering, etc.

## Running the code

Yes, this is legacy code -- Daily Dose uses Perl, Server Side Includes
(with Apache 2.0/2.2 syntax, not 2.4), and even Henrik's own
Python-based templating language (https://tools.ietf.org/tools/pyht/). 
The JavaScript parts (very few) are really plain vanilla 
JavaScript -- not even jQuery is used.

But all hope is not lost -- there's now a Docker image that hopefully
makes it possible to hack Daily Dose more easily (originally the
development was done mainly by ssh'ing to the production servers :-).

First, build the image: `docker/build`.

Next, start the container: `docker/run`:

- The container first downloads yesterday's and today's data from tools.ietf.org, so you can get quickly started. 
- You get a normal shell prompt.
- There's Apache running, exposed as port 4444. Apache error logs go to the terminal (in case you need to debug server side includes).
- The host Git working tree is mounted as /www/tools.ietf.org/dailydose/dailydose-current, so you can edit the scripts on the host.
- All other data under /www/tools.ietf.org/ is persisted on the host under the docker-data/ directory. This is not strictly necessary, but may help development.

Now, what can you do with it? If you run

```
perl dailydose-current/scripts/new_issue.pl data/$(cat data/previous.txt) 9000  .
```

You can now browse to http://(docker-machine-ip):4444/dailydose/9000.html!

Next you could try this:

```
perl dailydose-current/scripts/make_daily_content.pl none data/$(cat data/previous.txt)
```

A common task involves fixing a script whose HTML scraping has stopped working (due to changes in the HTML):

```
cd dailydose-current/scripts
previous=../../data/$(cat ../../data/previous.txt)
perl liaisons_atom.pl none $previous
less $previous/liaisons_atom.xml
less $previous/liaisons.html
```

After that, you're pretty much on your own :)

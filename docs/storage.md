# Backup Storage

Mixtape uses a standardized backup storage layout that it may be helpful to
understand. This documents outlines the basics.


## File system location

By default, Mixtape backups are stored and accessed from the following
default location:

    /backup/<host>/mixtape

The `--backup-dir=<dir>` option (to all commands) allows replacing the
`/backup` part of this location. Similarily, the `--mixtape-dir=<dir>`
option replaces the whole location with a specified directory.


## Directory layout

Below is an example of a small Mixtape backup directory:

    +- config
    +- index/
    |   +- index.2017-01-19-0846.txt.xz
    |   +- index.2017-01-20-1149.txt.xz
    +- data/
        +- 33d/
        |   +- 847/
        |       +- image.jpg
        +- 68e/
        |   +- 24f/
        |       +- long.txt.xz
        +- files/
            +- 2017-03/
                +- files.2017-01-19-0846.tar.xz
                +- files.2017-01-20-1149.tar.xz


## Configuration file

The `config` file in the Mixtape directory lists all the backup paths to be
stored (one per line). Paths should be absolute, e.g. `/opt/subdir`.

By prefixing a line with `-`, the specified path will be excluded from the
backup. If a line prefixed with `-` doesn't contain a `/` path separator,
all files with the specified name are excluded.

Below is a default `config` file containing only named excludes of `.git`
and others:

```bash
# Configuration of backup includes and excludes.
#
# /dir             includes '/dir' into backup
# - /dir/subdir    excludes '/dir/subdir' from backup
# - name           excludes all 'name' files and dirs

- .git
- .hg
- .svn
```

The `config` file can be edited with any text editor. Changes take effect
on the next run of `mixtape-backup`. Changes will not have any effect on
previous backups.


## Index files

The index files contains a list of all files and directories backed up at a
specific point in time. The files are tab-separated text files with columns
for all the file meta-data saved, including the `sha256sum` of each file
and the location inside the backup `data` directory.

Below is a small excerpt from an example index file (with a few line breaks
added for readability):

```
drwxr-xr-x	root	root	2017-01-19 08:44:48	4	/test
-rw-r--r--	root	root	2017-01-18 08:01:16	4	/test/README.txt
	dcf1ab049b0a5c9bad7555a64bc3ea1d625c658d432bef956178b063d665b172
	files/2017-03/files.2017-03-03-0647.tar.xz
drwxr-xr-x	root	root	2017-01-19 08:44:53	4	/test/subdir
-rw-r--r--	root	root	2017-01-19 08:34:01	264	/test/subdir/loremipsum.txt
	68e24fba182bb7272ba855b59be46f9fb59fb5e60757d4fd6c6c481e39f0e507
	68e/24f/loremipsum.txt.xz
```

A new index file is created on each run of `mixtape-backup`, which
(depending on backup frequency) may lead to many such files being present.
Storing too many index files will slow down searches and use more storage.
Use the `mixtape-gc` tool or plain `rm` to remove older index files. Note
that `mixtape-gc` also removes files from the `data` directory that are no
longer referenced by any index.


## Data files

The `data` directory contains copies of the actual files backed up. Smaller
files (less than 256 KB in size) are stored into `tar.xz` archives under
the `data/files/<year>-<month>/` directory. Only new or modified files are
stored into each archive, so the archive from the initial backup is usually
much larger than the other archives. See below for an example archive
listing:

```
-rw-r--r-- 1 root root 481280 Feb 14 02:07 files.2017-02-14-0207.tar.xz
-rw-r--r-- 1 root root    456 Feb 15 02:07 files.2017-02-15-0207.tar.xz
-rw-r--r-- 1 root root   3304 Feb 17 02:07 files.2017-02-17-0207.tar.xz
```

Larger files are stored in a `data/<sha-part-1>/<sha-part-2>/` directory
based on the `sha256sum` of their content. As the files are modified,
multiple copies will be stored under different directories.

Large files are normally also compressed, unless the file extension implies
that the file is already compressed (e.g. `.jpg`, `.zip`, etc).

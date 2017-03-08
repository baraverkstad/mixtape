# Backup Storage

Mixtape uses a standardized backup storage layout that it may be helpful
to understand. This documents outlines the basics.


## File system location

By default, Mixtape backups are stored and accessed from the following
default location:

> `/backup/<host>/mixtape`

The `--backup-dir=<dir>` option (to all commands) allows replacing the
`/backup` part of this location. Similarily, the `--mixtape-dir=<dir>`
option replaces the whole location with a specified directory.


## Directory layout

Below is an example of a small Mixtape backup directory:

```
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
```


## Configuration file

The `config` file in the Mixtape directory lists all the backup paths to
be stored (one per line). Paths should be absolute, e.g. `/opt/subdir`.

By prefixing a line with `-`, the specified path will be excluded from the
backup. If a line prefixed with `-` doesn't contain a `/` path separator,
all files with the specified name are excluded. By default, entries like
`- .git`, `- .svn` and similar are added to the top of the `config`.

The `config` file can be edited with any text editor. Changes take effect
on the next run of `mixtape-backup`.


# Index files

The index files contains a list of all files and directories backed up
at a specific point in time. The files are tab-separated text files with
columns for all the file meta-data saved, including the `sha256sum` of
each file and the location inside the backup `data` directory.

A new index file is created on each run of `mixtape-backup`, which may
lead to many such files being present (slowing down searches and using
more storage). Use the `mixtape-gc` tool or plain `rm` to remove older
index files. Note that `mixtape-gc` also cleans up any files in the
`data` directory that are no longer referenced from an index.


# Data files

TODO

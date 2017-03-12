# mixtape-backup

Stores files into the backup.


## Usage:

    mixtape-backup [<path> ...]

Performs a recursive backup of one or more `<path>` directories (or files).
The `<path>` arguments are only required on the first run. Subsequent runs
will reuse the previously specified paths (optionally adding new ones from
the command-line).

Specific file names or subdirs may be excluded by prefixing with a `-`
character.

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--store-all`         | Stores copies of all files, duplicating file data         |
| `--store-modified`    | Stores copies of modified or new files (default)          |
| `--debug`             | Enables more output (verbose mode)                        |
| `--quiet`             | Disables normal output (quiet mode)                       |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)

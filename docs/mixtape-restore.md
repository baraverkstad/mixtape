# mixtape-restore

Restores files from the backup.


## Usage:

> `mixtape-restore <index> <path>`

Recursively restores all files in `<path>` found inside a single backup
`<index>`. The `<index>` can be specified as an index id (e.g.
`@586efbc4`), a named search (e.g. `first`, `last`) or unique timestamp
(e.g. `2017-01-01`).

The `<path>` should be the absolute file path for files to restore (e.g.
`/etc`). Use `/` to restore all files. An initial `/` char will be added if
missing.

The files are restored into a restore directory matching the index file
name (e.g. `/backup/<host>/mixtape/restore-2017-01-19-0846/`). This makes
it possible to combine multiple partial restores from the same index into a
single directory.

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--debug`             | Enables more output (verbose mode)                        |
| `--quiet`             | Disables normal output (quiet mode)                       |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)

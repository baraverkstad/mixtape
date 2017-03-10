# mixtape-status

Prints a backup status summary or a summary for a specified index.


## Usage:

    mixtape-status [<index>]

Prints a backup status summary or a summary for a specified `<index>`.

The `<index>` can be specified as an index id (e.g. `@586efbc4`), a named
search (e.g. `first`, `last`) or partial timestamp (e.g. `2017-01`) with
optional glob matching (e.g. `20??-*-01`).

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)

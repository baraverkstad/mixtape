# mixtape-search

Searches for matching files in the backup.


## Usage:

> `mixtape-search [<index>] <file>`

Searches the backups for all files matching the `<file>` name or path. The
search can be limited to one or more `<index>` files, either with and index
id (e.g. `@586efbc4`"), a named search (e.g. `all`, `first`, `last`) or a
partial timestamp (e.g. `2017-01`) with optional glob matching (e.g.
`20??-*-01`). If no `<index>` is specified, `all` is assumed.

The `<file>` name or path supports glob matching (e.g. `/etc/**/*.sh`).
Avoid shell expansion of the pattern by using quotes (i.e. `"pattern"`). A
pattern starting with `/` will match an absolute file path.

By default, the oldest copy of each file version (a unique `sha256sum`) is
printed. Use `--all` to show all copies.

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--all`               | Prints all file versions matched                          |
| `--newest`            | Prints the newest file versions matched                   |
| `--oldest`            | Prints the oldest file versions matched (default)         |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)
* [mixtape-list](mixtape-list.md)

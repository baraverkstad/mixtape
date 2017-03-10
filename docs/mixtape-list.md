# mixtape-list

Lists backups and optionally the content files.


## Usage:

    mixtape-list [<index>] [<path>]

Lists backup `<index>` files and optionally their content files starting
with `<path>`. A limited set of `<index>` files can be specified either as
an index id (e.g. `@586efbc4`), a named search (e.g. `all`, `first`,
`last`) or a partial timestamp (e.g. `2017-01`) with optional glob matching
(e.g. `20??-*-01`). When neither `<index>` nor `<path>` is specified, `all`
is assumed. If a `<path>` is specified, but no `<index>`, then `last` is
assumed.

The optional file `<path>` for listing files from the indexes. Use `/` to
show all files. The `<path>` must be an absolute file path, and an initial
`/` char will be added if missing.

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--long`              | Prints content files in long format                       |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)
* [mixtape-search](mixtape-search.md)

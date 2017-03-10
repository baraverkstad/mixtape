# mixtape-gc

Removes expired indexes and non-referenced storage files.


## Usage:

    mixtape-gc [--delete-expired] [--keep-<interval>=#]

Deletes all stored backup files not referenced from any index. Optionally
also deletes expired index files.

Index files expire when not found in any one of the five retention
categories (yearly, monthly, weekly, daily or latest). Each category
contains a limited number of slots, filled with the oldest available index
file for that slot (i.e. one file per year, one per month, etc).

The number of slots per category is pre-defined (see options below),
counting backwards until the limit is reached. Unfilled slots will be
ignored in the total count. Set the category size to zero to ignore it.

| Options               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--delete-expired`    | Deletes expired index files                               |
| `--keep-yearly=#`     | Number of yearly indexes to keep, defaults to 10          |
| `--keep-monthly=#`    | Number of monthly indexes to keep, defaults to 18         |
| `--keep-weekly=#`     | Number of weekly indexes to keep, defaults to 10          |
| `--keep-daily=#`      | Number of daily indexes to keep, defaults to 14           |
| `--keep-latest=#`     | Number of recent indexes to keep, defaults to 5           |
| `--debug`             | Enables more output (verbose mode)                        |
| `--quiet`             | Disables normal output (quiet mode)                       |
| `--backup-dir=<dir>`  | Sets the root backup dir, instead of `/backup`            |
| `--mixtape-dir=<dir>` | Sets the mixtape dir, instead of `/backup/<host>/mixtape` |
| `--help`              | Prints help information (and quits)                       |
| `--version`           | Prints version information (and quits)                    |


## See also:

* [Backup storage structure](storage.md)

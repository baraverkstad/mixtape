# mixtape-backup

Stores files into the backup.


## Usage:

`mixtape-backup [<path> ...]`

| Argument | Description                                         |
| -------- | --------------------------------------------------- |
| `<path>` | A file or directory to backup (recursively).        |

The `<path>` arguments are only required on the first run. Subsequent
runs will reuse the same paths as the first. Specific file names or
subdirs may be excluded by prefixing with a `-` character.


## See also:

* Backup storage structure

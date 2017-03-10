# Mixtape Backup

Practical backups. The Unix toolkit way.


## Features

Mixtape is aimed at replacing `tar` or `rsync` for general backups. It
automatically deduplicates and compresses files upon backup, making the
backup process fast and space-efficient.

Mixtape is written in Bash, using the standard GNU/Linux toolkit (`tar`,
`awk`, `grep`, `sort`, etc). This means that you can easily check, inspect
or extract data from the backups using the tools already on your system.

See the [full list of features](docs/features.md) for reasons to use or
avoid Mixtape for your backups.


## Usage

Mixtape is provided as a set of command-line tools:

| Command                                    | Description                    |
| ------------------------------------------ | ------------------------------ |
| [mixtape-backup](docs/mixtape-backup.md)   | Stores files into the backup   |
| [mixtape-gc](docs/mixtape-gc.md)           | Removes expired backups        |
| [mixtape-list](docs/mixtape-list.md)       | Lists backups and content      |
| [mixtape-restore](docs/mixtape-restore.md) | Restores files from the backup |
| [mixtape-search](docs/mixtape-search.md)   | Searches for matching files    |
| [mixtape-status](docs/mixtape-status.md)   | Prints a backup status summary |

Please check the [backup storage structure](docs/storage.md) documentation
to better understand the terminology and file structure.


## Requirements

* GNU Bash (4.2 or higher)
* XZ Utils (5.2 or higher)
* GNU/Linux command-line environment (no BSD support yet)


## Related Tools

Mixtape backups are stored to the local filesystem. For a complete solution,
the backup directory should be cloned to another server or to cloud storage
(preferably as an encrypted copy). Here are some useful tools:

- Rclone - [rclone.org](http://rclone.org)
- Rsync - [rsync.samba.org](https://rsync.samba.org)

Alternative deduplicating backup tools exist aplenty today. At the time of
writing, here are some of the most promising (in no particular order):

- Duplicity — [duplicity.nongnu.org](http://duplicity.nongnu.org/)
- Borg Backup — [borgbackup.readthedocs.io](https://borgbackup.readthedocs.io/)
- ZBackup — [zbackup.org](http://zbackup.org)
- BUP — [bup.github.io](https://bup.github.io)
- rdedup — [github.com/dpc/rdedup](https://github.com/dpc/rdedup)

You should probably give one or more of the above a try before using Mixtape.

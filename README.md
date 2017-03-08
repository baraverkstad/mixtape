# Mixtape Backup

Practical backups. The Unix toolkit way.


## Features

Mixtape is created as an improvement over the old backup practices of
using `tar` or `rsync`. Here are some of the reasons to consider:

- **Deduplicated data** — Large files are only stored once (deduplication),
  using their `sha256sum` to detect copies and changes. In most cases, this
  often provides sufficient deduplication to make backups fast and
  space-efficient.

- **Data compression** — Backup data is compressed using `lzma` to save
  space. Small files are also bundled together in `tar` archives before
  compression to keep the number of files low and compression ratios high.

- **Shell-friendly** — Mixtape is written in Bash, using the standard
  GNU/Linux toolchain (`tar`, `awk`, `grep`, `sort`, etc). This means that
  you can check, inspect or extract data from the backups using the tools
  already on your system. No extra installs or custom archive formats.

- **Cloud-friendly** — The number of files are kept low (much lower than
  the number of files backed up), which makes it practical to sync the
  backups to cloud storage. Consider using [rclone](http://rclone.org)
  with encryption to move data off-server.

- **Garbage collection** — Mixtape contains a tool to remove older
  backups on a complex schedule. Backups can also be removed with `rm`,
  using the garbage collection tool to remove the referenced data files.
  This makes is viable to run backups as frequently as every minute if
  desired.

- **Simple search, restore & status** - A number of tools are available for
  inspecting the backups, including simple file pattern searches. Other
  tools allows simple restore without overwriting, listing all backup
  files, printing disk usage, and more.


## Non-features

There are many good reasons to avoid using Mixtape for backing up your data.
Here are some of them:

- **No chunk deduplication** — By splitting files into chunks, better data
  deduplication is possible. This is important for large files sharing
  portions of their data (e.g. docker images). Mixtape has opted for making
  file restores simple with standard Unix tools instead.

- **No sparse file support** — Files containing gaps (i.e. sparse files)
  are handled just as any other file. They will be compressed if possible,
  but other backup tools may store these files more efficiently.

- **No extended attributes** - The suid/guid/sticky bits and extended
  attributes of a file are currently ignored when storing the backups. Nor
  will they be available upon restore. It is possible that this will be
  added to a future version. 

- **No remote storage** — Backups are stored on the local file system and
  remote storage transfer must be handled by a separate tool. This uses
  more diskspace, but enables quicker searches and easier file recovery.
  Consider using [rclone](http://rclone.org) with encryption to move data
  off-server.

- **No encryption** — Backups are not encrypted (as they are stored locally).
  Again, this is a tradeoff to enable fast searching and easy access. Use a
  cloud upload tool with built-in encryption when moving data off-server.


## Other Tools

Deduplicating backup tools exist aplenty today. At the time of writing, here
are some of the most promising (in no particular order):

- Duplicity — [duplicity.nongnu.org](http://duplicity.nongnu.org/)
- Borg Backup — [borgbackup.readthedocs.io](https://borgbackup.readthedocs.io/)
- ZBackup — [zbackup.org](http://zbackup.org)
- BUP — [bup.github.io](https://bup.github.io)
- rdedup — [github.com/dpc/rdedup](https://github.com/dpc/rdedup)

You should probably give one or more of the above a try.

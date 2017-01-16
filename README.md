# Mixtape Backup

Practical backups. The Unix toolkit way.


## Features

Mixtape is (in many ways) an improvement over the old backup practices of
using `tar` or `rsync`. Here are some of the reasons to consider:

- **Deduplicated data** — Large files are stored using their `sha1sum` to
  avoid duplicating them on successive backups. In practice, this often
  provides sufficient deduplication to make backups fast and space-efficient.

- **Data compression** — Backup data is compressed using `lzma` (when
  applicable) to save space. Small files are also bundled together in
  `tar` archives before compression to keep the number of files low and
  compression ratios high.

- **Shell friendly** — Mixtape is written in Bash, using the standard
  GNU/Linux toolchain (`tar`, `awk`, `grep`, `sort`, etc). This means you
  can easily check or inspect the backups using the tools already on your
  system. No extra installs or developer trust needed.

- **Cloud friendly** — The number of files are kept low (much lower than
  the number of files backed up), which makes it practical to sync the
  backups to cloud storage. Consider using [rclone](http://rclone.org)
  with encryption to move data off-server.


## Non-features

There are many good reasons not to use Mixtape for backing up your data.
Here are some of them:

- **No chunk deduplication** — By splitting files into chunks, better data
  deduplication is possible. In particular for large files sharing portions
  of their data (i.e. docker images, etc). Mixtape has opted for the route
  of making file restores easy using standard Unix tools instead.

- **No sparse file support** — Files containing gaps (i.e. sparse files)
  are not handled specially. They will be compressed if possible, but other
  tools may store these files more efficiently.

- **No remote storage** — Backups are stored on the local file system and
  remote storage transfer must be handled by separate tools. This uses more
  diskspace, but enabled quick searches and easy file recovery. Consider
  using [rclone](http://rclone.org) with encryption to move data off-server.

- **No encryption** — Backups are not encrypted (as they are stored locally).
  Again, this is a tradeoff to enable fast searching and easy acces. Other
  backup tools (with built-in cloud uploading) should provide this, or it
  can be added upon off-server transfer.

- **No garbage collection** — Not implemented yet. Less of a problem than
  one could suspect, as the backup index files can be removed with a simple
  `rm`. If large files are not modified very frequently, this is normally
  where the backups increase the most in size (over time).


## Other Tools

Deduplicating backup tools exist aplenty today. At the time of writing, here
are some of the most promising (in no particular order):

- Duplicity — http://duplicity.nongnu.org/index.html
- Borg Backup — https://borgbackup.readthedocs.io/en/stable/
- ZBackup — http://zbackup.org
- BUP — https://bup.github.io
- rdedup — https://github.com/dpc/rdedup

You should probably give one or more of the above a try.

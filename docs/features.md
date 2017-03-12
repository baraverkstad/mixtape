# Features

Mixtape is created as an improvement over the old backup practices of using
`tar` or `rsync`. Here are some of the reasons to consider using Mixtape
for backups:

- **Deduplicated data** — Files are only stored once (deduplication), using
  their `sha256sum` to detect copies and changes. In many cases, this
  provides sufficient deduplication to make backups both fast and
  space-efficient.

- **Data compression** — Backup data is compressed using `xz` to save space.
  Small files are bundled together into `tar` archives before compression
  to keep the number of files low and compression ratios high.

- **Shell-friendly** — Mixtape is written in Bash, using the standard
  GNU/Linux toolchain (`tar`, `awk`, `grep`, `sort`, etc). This means that
  you can check, inspect or extract data from the backups using the tools
  already on your system. No extra installs or custom archive formats.

- **Cloud-friendly** — The number of files are kept low (much lower than
  the number of files backed up), which makes it practical to sync the
  backups to cloud storage.

- **Garbage collection** — Backups can be made to expire based on a dynamic
  schedule that keeps fewer backups the older they become. Backups can also
  be manually removed with plain `rm`, using the garbage collection tool to
  remove referenced data files. This makes is viable to run backups as
  frequently as every minute if desired.

- **Simple search, restore & status** - A number of tools are available for
  inspecting the backups, including searching for files based on simple file
  glob patterns. Other tools allows simple restore without overwriting,
  listing all backup files, printing disk usage, and more.


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

- **No extended attributes** - The suid/guid/sticky bits, extended
  attributes, SELinux attributes, etc of files are currently ignored when
  storing the backups. Nor will they be available upon restore. It is
  possible that this will be added to a future version.

- **No remote storage** — Backups are stored on the local file system and
  remote storage transfer must be handled by a separate tool. This uses
  more diskspace, but enables quicker searches and easier file recovery.
  Consider using [rclone](http://rclone.org) with encryption to move data
  off-server.

- **No encryption** — Backups are not encrypted (as they are stored locally).
  Again, this is a tradeoff to enable fast searching and easy access. Use a
  cloud upload tool with built-in encryption when moving data off-server.

- **No BSD, MacOS or Windows support** — Although written in Bash, the
  scripts are known to not work in a non-GNU/Linux environment. This is due
  to subtle differences in `awk`, `sort` and other similar tools. A future
  version may address this.

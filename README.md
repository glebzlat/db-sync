# KeePassXC database sync script

This simple script creates the remote database backup, merges the remote
database with the local database and saves it on a cloud. It is intended to be
run by systemd on timer.

## Configuration

DB-Sync sources the config file `.config/db-sync/config`. It requires the
following variables:

- `local_file`: Local database file.
- `remote`: Remote drive name.
- `remote_dir`: Directory on the remote drive to store the database mirror.
- `backup_pattern`: Backup filename pattern. Uses date format
    (see `man:date(1)`, e.g. `keepass_%Y-%m-%dT%H:%M.kdbx`).
- `password_file`: Write your database password to this file. It must be placed
    at the same directory as the config file.
- `backup_dir`: Directory where periodic backup files are saved.

See [the example config](./config.example) for more details.

Config directory must have permissions `u+rwx` or `700`:

```sh
chmod 700 ${HOME}/.config/db-sync
```

The script will automatically set permissions `700` to files in the config
directory.

## Prerequisites

The script uses [rclone](https://rclone.org) to interact with the cloud and
[keepassxc-cli](https://keepassxc.org) to merge the database. Other dependencies
include:

- Linux-based OS
- Systemd
- Bash
- GNU coreutils
- grep
- GNU Make (only for installation/setup)

## Installation

Run

```sh
make install
```

to install the files. It will automatically create the config file, which must
be edited before taking further steps.

The following command starts the service and the timer:

```sh
make start
```

Wait for several seconds and inspect the status of the service to ensure
everything is fine:

```sh
systemctl --user status db-sync.service
```

To uninstall the files:

```sh
make uninstall
```

## License

Licensed under [MIT License](./LICENSE)

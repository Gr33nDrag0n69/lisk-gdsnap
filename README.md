# lisk-gdsnap

A custom version of the `lisk_snapshot.sh` script.

The legacy version of `lisk_snapshot.sh` (v0.6.x to v1.5.1) was written by Isabella and Me in early 2017 and had some extra parameters:

* Internal lock system to prevent multiple instances running at same time.
* Database forced VACUUM prior to dumping.
* Custom output directory parameter.
* Auto-cleanup parameter.
* Generic copy parameter.
* and more...

They were all removed by Lisk HQ starting with v1.6.0 of lisk-node.

This script was made to keep these features while using new snapshot code.

First version (2019-05-04) was made to be compatible with v1.6.0.

Latest version (2019-07-30) was modified to be compatible with v2.0.0.


## Requirements

* Must be run with the same user lisk-node is running.
* If using custom output directory, make sure the user running the script have write permissions on target directory.

## Install

#### MainNet

> wget https://raw.githubusercontent.com/Gr33nDrag0n69/lisk-gdsnap/master/gdsnap.sh -O ~/lisk-main/gdsnap.sh && chmod 700 ~/lisk-main/gdsnap.sh

#### Testnet

> wget https://raw.githubusercontent.com/Gr33nDrag0n69/lisk-gdsnap/master/gdsnap.sh -O ~/lisk-test/gdsnap.sh && chmod 700 ~/lisk-test/gdsnap.sh

## Usage

```
./gdsnap.sh [-o <output directory>] [-d <days to keep>] [-g]

 -o <output directory>     -- Output directory. Default is ./backups
 -d <days to keep>         -- Days to keep GZ files. Default is 0. (Disabled)
 -g                        -- Make a copy of backup file named blockchain.db.gz.
```

## Cronjob Examples

### Default (MainNet)

> 30 */6 * * * /bin/bash ~/lisk-main/gdsnap.sh > /dev/null 2>&1

* Run every 6 hours starting at 00:30
* Use default output directory: ~/lisk-main/backups/
* No file cleanup.
* No generic copy.
* No log file.

### snapshot.lisknode.io (MainNet)

> 0 */3 * * * /bin/bash ~/lisk-main/gdsnap.sh -o /opt/nginx/snapshot.lisknode.io -d 5 -g > ~/lisk-main/logs/gdsnap.log 2>&1

* Run every 3 hours starting at 00:00
* Use custom output directory
* Delete *.gz files older than 5 days
* Create/Overwrite a copy of the latest snapshot to blockchain.db.gz 
* Output logs to ~/lisk-main/logs/gdsnap.log

### testnet-snapshot.lisknode.io (TestNet)

> 0 */4 * * * /bin/bash ~/lisk-test/gdsnap.sh -o /opt/nginx/testnet-snapshot.lisknode.io -d 3 -g > ~/lisk-test/logs/gdsnap.log 2>&1

* Run every 4 hours starting at 00:00
* Use custom output directory
* Delete *.gz files older than 3 days
* Create/Overwrite a copy of the latest snapshot to blockchain.db.gz 
* Output logs to ~/lisk-test/logs/gdsnap.log

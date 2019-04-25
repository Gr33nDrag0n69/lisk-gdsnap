# lisk-gdsnap

A custom version of the lisk_snapshot.sh script.

The legacy version of lisk_snapshot.sh was written by Isabella and Me and had a lot of cool parameters:
* Custom output directory parameter. (Replaced by a env. variable)
* Auto-cleanup parameter. (Removed)
* Generic copy parameter. (Removed)

They were all ditched by Lisk HQ on their new "pgdump only" version.

I rewrote from scratch a merge of both scripts functionnality.
The parameters are all the same that were uses on the legacy script.

### Lisk HQ / LightCurve

Feel free to replace the new bundled script by this one. ;)

### Requirements

* Must be run with the same user lisk-node is running
* If using custom output directory, make sure the user running the script have write permissions on target directory.

### Usage

### Cronjob



#!/bin/bash -e
#######################################################################################################################
#
# Compatible/Tested with v2.0.0 ONLY
#
# LiskHQ/lisk-scripts/lisk_snaphot.sh
# Copyright (C) 2017 Lisk Foundation
#
# LiskHQ/lisk-sdk/lisk/build/target/lisk_snapshot.sh
# Copyright (C) 2019 Lisk Foundation
#
# Gr33nDrag0n69/lisk-gdsnap/gdsnap.sh
# Copyright (C) 2019 Gr33nDrag0n
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################


### Init. Env. ########################################################################################################

set -euo pipefail
IFS=$'\n\t'

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck source=env.sh
. "$(pwd)/env.sh"

### Default Configuration #############################################################################################

OUTPUT_DIRECTORY="$PWD/backups"

DAYS_TO_KEEP="0" # Disabled

GENERIC_COPY=false

# Not configurable via parameter(s).

SOURCE_DATABASE=$( node scripts/generate_config.js |jq --raw-output '.components.storage.database' )

STALL_THRESHOLD="15"

LOCK_LOCATION="$PWD/locks"
LOCK_FILE="$LOCK_LOCATION/snapshot.lock"

### Function(s) #######################################################################################################

parse_option() {
	OPTIND=1
	while getopts :o:d:g OPT; do
		case "$OPT" in
			o)
				mkdir -p "$OPTARG" &> /dev/null
				if [ -d "$OPTARG" ]; then
					OUTPUT_DIRECTORY="$OPTARG"
				else
					echo "$(now) Output directory is invalid."
					exit 1
				fi ;;

			d)
				if [ "$OPTARG" -ge 0 ]; then
					DAYS_TO_KEEP="$OPTARG"
				else
					echo "Invalid number for days to keep."
					exit 1
				fi ;;

			g) GENERIC_COPY=true ;;

			:) echo "$(now) Missing option argument for -$OPTARG" >&2; exit 1 ;;

			?) usage; exit 1 ;;

			*) echo "$(now) Unimplemented option: -$OPTARG" >&2; exit 1 ;;

		esac
	done
}

usage() {
	echo -e "\\nUsage: $0 [-o <output directory>] [-d <days to keep>] [-g]\\n"
	echo " -o <output directory>     -- Output directory. Default is ./backups"
	echo " -d <days to keep>         -- Days to keep GZ files. Default is 0. (Disabled)"
	echo " -g                        -- Make a copy of backup file named blockchain.db.gz."
	echo ''
}

now() {
	date +'%Y-%m-%d %H:%M:%S'
}

### MAIN ##############################################################################################################

parse_option "$@"

### Lock File Management

echo -e "\\n$(now) Checking for existing snapshot operation"

if [ ! -f "$LOCK_FILE" ]; then
	echo "√ Previous snapshot is not runnning. Proceeding."
else
	if [ "$( stat --format=%Y "$LOCK_FILE" )" -le $(( $(date +%s) - ( STALL_THRESHOLD * 60 ) )) ]; then
		echo "√ Previous snapshot is stalled for $STALL_THRESHOLD minutes, terminating and continuing with a new snapshot."
		bash lisk.sh stop_node >/dev/null
		dropdb --if-exists lisk_snapshot 2> /dev/null
		bash lisk.sh stop >/dev/null
		bash lisk.sh start >/dev/null
		rm -f "$LOCK_FILE" &> /dev/null
	else
		echo "X Previous snapshot is in progress, aborting."
		exit 1
	fi
fi

### Create Lock File

echo -e "\\n$(now) Creating Lock File"
mkdir -p "$LOCK_LOCATION" &> /dev/null
touch "$LOCK_FILE" &> /dev/null

### Stop Software (Node Only, Keep PostgreSQL Up)

echo -e "\\n$(now) Stopping Lisk Node & Removing 'lisk_snapshot' DB copy."
bash lisk.sh stop_node >/dev/null
dropdb --if-exists lisk_snapshot 2> /dev/null

### Vacuum database before dumping

echo -e "\\n$(now) Executing vacuum on database '$SOURCE_DATABASE' before copy"
vacuumdb --analyze --full "$SOURCE_DATABASE" &> /dev/null

### Duplicate DB

echo -e "\\n$(now) Duplicating '$SOURCE_DATABASE' DB to 'lisk_snapshot' DB."
createdb --template="$SOURCE_DATABASE" lisk_snapshot

### Removing peers & memdata from DB copy

echo -e "\\n$(now) Removing peers data from DB 'lisk_snapshot'"
psql --dbname=lisk_snapshot --command='TRUNCATE peers;' >/dev/null

### Dump 'lisk_snapshot' DB

echo -e "\\n$(now) Dumping 'lisk_snapshot' DB to gzip file"
HEIGHT=$( psql --dbname=lisk_snapshot --tuples-only --command='SELECT height FROM blocks ORDER BY height DESC LIMIT 1;' |xargs)
OUTPUT_FILE="${OUTPUT_DIRECTORY}/${SOURCE_DATABASE}_backup-${HEIGHT}.gz"
TEMP_FILE=$( mktemp --tmpdir="$OUTPUT_DIRECTORY" )
pg_dump --no-owner lisk_snapshot | gzip -9 >"$TEMP_FILE"
mv -f "$TEMP_FILE" "$OUTPUT_FILE"
chmod 644 "$OUTPUT_FILE"

###  Generic Copy

if [ "$GENERIC_COPY" = true ] 2> /dev/null; then
	echo -e "\\n$(now) Overwriting Generic Copy (blockchain.db.gz)"
	GENERIC_FILE="${OUTPUT_DIRECTORY}/blockchain.db.gz"
	cp -f "$OUTPUT_FILE" "$GENERIC_FILE"
	chmod 644 "$GENERIC_FILE"
fi

### Start Software

echo -e "\\n$(now) Starting Lisk Node"
bash lisk.sh start_node >/dev/null

### OLD GZ Files Cleanup

if [ "$DAYS_TO_KEEP" -gt 0 ]; then
	echo -e "\\n$(now) Deleting snapshots older than $DAYS_TO_KEEP day(s) in $OUTPUT_DIRECTORY"
	mkdir -p "$OUTPUT_DIRECTORY" &> /dev/null
	find "$OUTPUT_DIRECTORY" -name "${SOURCE_DATABASE}_backup-*.gz" -mtime +"$(( DAYS_TO_KEEP - 1 ))" -exec rm {} \;
fi

### Remove Lock File

echo -e "\\n$(now) Removing Lock File"
rm -f "$LOCK_FILE" &> /dev/null

### Exit

echo -e "\\n$(now) Snapshot Complete"
exit 0

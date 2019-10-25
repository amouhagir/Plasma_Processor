#!/bin/sh

root=$( realpath "$( dirname "$0" )" )
hostname=$( hostname )

#ENABLE_BITSTREAM=
#ENABLE_SIMULATION=

RSYNC="rsync -a -s --progress --delete"
KEY="$HOME/.ssh/$hostname/$hostname"
SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SSH="ssh"
SCP="scp"
GATEWAY="ssh.enseirb-matmeca.fr"
USER="paukocialkowsk"
PORT=1234
ROOT="projet-avance-se"
BITSTREAM="Plasma/BIN/plasma.bit"
PROJECT="i2c"
BINARY="Plasma/BIN/$PROJECT.bin"
SRC="$HOME/$ROOT/Plasma"
DST="$USER@$GATEWAY:$ROOT"
HOST="$1"

if [ -z "$HOST" ]
then
	HOST="regiotonum" # cannabis, lsd, darlingtonia
fi

test=$( ssh-add -l | grep "$KEY" || true )

if [ -z "$test" ]
then
	echo -e "Adding SSH key for \e[1;33m$hostname\e[0m:"
	ssh-add "$KEY"
fi

if [ -z "$DRY" ] && [ -z "$NODRY" ] && [ -z "$NOSYNC" ]
then
	echo -en "Sync in \e[1;31mdry\e[0m mode: "
	read DRY
fi

if [ -n "$DRY" ]
then
	dry="--dry-run"
	dry_description=" \e[1;31m(dry run)\e[0m"
fi

echo -e "Deploy \e[1;34mplasma\e[0m from \e[1;33m$hostname\e[0m to \e[1;33m$GATEWAY\e[0m$dry_description"

if [ -z "$NOSYNC" ]
then
	$RSYNC $dry "$SRC" "$DST"
fi

echo -e "Setup \e[1;34mgateway\e[0m on port \e[1;33m$PORT\e[0m"

screen -S plasma -d -m ssh -L $PORT:$HOST:22 "$GATEWAY" && echo "Attached via screen" || exit 1
sleep 5

echo -e "Run \e[1;34mclean\e[0m"

$SSH $SSH_OPTIONS -p $PORT "$USER@localhost" "cd projet-avance-se && source config.sh && make -C Plasma clean"

if [ -n "$ENABLE_SIMULATION" ]
then
	echo -e "Run \e[1;34msimulation\e[0m"

	$SSH $SSH_OPTIONS -p $PORT "$USER@localhost" "cd projet-avance-se && source config.sh && make -C Plasma simulation"
fi

if [ -n "$ENABLE_BITSTREAM" ]
then
	echo -e "Run \e[1;34mplasma\e[0m"

	$SSH $SSH_OPTIONS -p $PORT "$USER@localhost" "cd projet-avance-se && source config.sh && make -C Plasma plasma"

	echo -e "Copy \e[1;34mbitstream\e[0m"

	$SCP "$DST/$BITSTREAM" $( basename "$BITSTREAM" )
fi

echo -e "Run \e[1;34mproject\e[0m"

$SSH $SSH_OPTIONS -p $PORT "$USER@localhost" "cd projet-avance-se && source config.sh && make -C Plasma project CONFIG_PROJECT=$PROJECT"

echo -e "Copy \e[1;34mproject\e[0m"

$SCP "$DST/$BINARY" $( basename "$BINARY" )

echo -e "Run \e[1;34mclean\e[0m"

$SSH $SSH_OPTIONS -p $PORT "$USER@localhost" "cd projet-avance-se && source config.sh && make -C Plasma clean"

echo -e "Close \e[1;34mgateway\e[0m on port \e[1;33m$PORT\e[0m"

screen -X -S plasma kill

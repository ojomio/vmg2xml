#!/bin/bash

DIR=$1
FILE=$2

EXT=$(echo $2 | awk -F '.' '{print $NF}')

trap unlock SIGHUP SIGINT SIGTERM SIGKILL

RUNDIR=/run
BACKUPDIR=/backup
GITBIN=$(which git)
DATEBIN=$(which date)
LOGGERBIN=$(which logger)
SYSTEMCTLBIN=$(which systemctl)

function unlock()
{
    if [ -n $1 ]
    then
        rm -f $1
    fi
}

function reload_service()
{
    StartDate=$($SYSTEMCTLBIN show --property=ExecMainStartTimestamp $1 | cut -d '=' -f2)
    StartTimestamp=$(date -d '$StartDate' +%s)
    ActualTimestamp=$($DATEBIN +%s)
    DeltaTimestamp=$(echo "${ActualTimestamp}-${StartTimestamp}" | bc)
    if [ $DeltaTimestamp -gt 1 ]
    then
        $SYSTEMCTLBIN reload $1
    fi
}

function backupthat
{
    # Create lock for the dir git commited and pulled
    Simple_Dir=$(echo "$DIR" | sed 's/\//_/g')
    LockFile=${RUNDIR}/incron$Simple_Dir.lock
    [ -f $LockFile ] && exit 1
    touch $LockFile

    ${LOGGERBIN} -p local0.info -t incron_action "Incron Autocommit, file ${FILE} has been modified."
    cd $DIR
    ${GITBIN} commit -a -m "Incron Autocommit, file ${FILE} has been modified" | grep -vE "^#"
    cd ${BACKUPDIR}${DIR}
    ${GITBIN} pull
    unlock ${LockFile}
}

case $FILE in
    *ld.so.cache*|*.swp|*.swx|4913|*~)
        ${LOGGERBIN} -p local0.info -t incron_action "Incron denied file ${FILE}"
        exit 0
        ;;
    *)
		case $DIR in
            /etc*)
                backupthat
                ;;
		    /var/named*)
                reload_service named
                backupthat
		        ;;
		    /var/kerberos*)
                reload_service krb5kdc
                backupthat
		        ;;
		    /var/www*|/var/lib*)
                backupthat
		        ;;
        esac
        ;;
esac

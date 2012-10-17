#!/bin/bash

DIR=$1
FILE=$2

EXT=$(echo $2 | awk -F '.' '{print $NF}')

BACKUPDIR=/data/backup
GITBIN=$(which git)
LOGGERBIN=$(which logger)

function backupthat
{
    ${LOGGERBIN} -p local0.info -t incron_action "Incron Autocommit, file ${DIR}/${FILE} has been modified."
    cd $DIR
    ${GITBIN} commit -q -a -m "Incron Autocommit, file ${DIR}/${FILE} has been modified"
    cd ${BACKUPDIR}${DIR}
    ${GITBIN} pull
}

case $EXT in
    ld.so.cache*|swp|swx|4913)
        echo $FILE
        exit 0
        ;;
    *)
		case $DIR in
            /etc*)
                backupthat
                ;;
		    /var/named)
		        /usr/bin/systemctl reload named.service
                backupthat
		        ;;
		    /var/kerberos)
		        /usr/bin/systemctl reload krb5kdc.service 
                backupthat
		        ;;
		    /var/www|/var/lib*)
                backupthat
		        ;;
        esac
        ;;
esac

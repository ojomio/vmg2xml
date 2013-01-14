#!/bin/sh

#set -x

# Global variable initialisation

LOGFILE=/storage/logfiles/autostart-$(date +%Y%m%d)
DOWNLOAD_DIR=/storage/downloads/
TVSHOWS_DIR=/storage/tvshows/
MOVIES_DIR=/storage/videos/
PROCESSED_DIR=/storage/.config/autostart_processed_dir.ls
PROCESSED_FILE=/storage/.config/autostart_processed_files.ls

# Regex pattern used later

EXCLUDED_DIR="incoming|sample|watch|\/$|downloads\/.*\/.*$(cat ${PROCESSED_DIR})"
EXCLUDED_FILES="incoming|sample|watch|\/$|downloads\/.*\/.*$(cat ${PROCESSED_FILE})"
EXTENSION_PATTERN=".{4}$"
TVSHOW_PATTERN="saison|season|s[0-9]{2}"
MOVIENAME_PATTERN=".*[0-9]{4}"
REMOVE_SPACE="sed 's/ /_/g'"
RETURN_SPACE="sed 's/_/ /g'"
GET_TVSHOW_NAME="sed -r -e 's/(.*)([Ss]aison.*|[Ss]eason.*|[Ss][0-9]{1,2}).*/\1/' -e 's/[\.\-_]/ /g' -e 's/ *$//'"
GET_TVSHOW_SEASON="sed -r -e 's/^.*([Ss]aison.?[0-9]*).*/\1/' -e 's/.*[Ss]eason.?([0-9]*).*/Saison \1/' -e 's/.*[Ss].?([0-9]{2}).*/Saison \1/'"
SURROUND_YEARS="sed -r 's/(\(?[0-9]{4})\)?/(\1)/'"

# Main

LS_DIR=$(find ${DOWNLOAD_DIR} -type d | grep -viE "${EXCLUDED_DIR}" | eval ${REMOVE_SPACE})
LS_FILES=$(find ${DOWNLOAD_DIR} -type f | grep -viE ${EXCLUDED_FILES} | eval ${REMOVE_SPACE})

echo -e "\nBegin: $(date +%H:%M)\nProcessing Directories" >>  ${LOGFILE}
for SAFE_DIR in $LS_DIR
do
    # Restore right file name with space
    DIR=$(echo "$SAFE_DIR" | eval ${RETURN_SPACE})

    # Try to detect tvshow pattern
    detectTVShow=$(echo "$DIR" | cut -d"/" -f 4 | grep -Ei $TVSHOW_PATTERN)

    # Processing
    if [ x"${detectTVShow}" = x ]
    then
        echo "This directory contains a movie: $DIR" >> ${LOGFILE}

        # Detect useful files removing space in names, replacing them with underscore
        FILES=$(find "$DIR" -iname *mkv ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *avi ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *mp4 ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -n "$FILES" ] &&  for SAFE_FILE in $FILES
        do
           FILE=$( echo "$SAFE_FILE" | eval ${RETURN_SPACE})
           EXTENSION=$(echo "$FILE" | grep -E -o ${EXTENSION_PATTERN})
           NAME=$(echo "$FILE" | cut -d"/" -f 4 | grep -E -o ${MOVIENAME_PATTERN} | eval ${SURROUND_YEARS})
           echo "Link: $FILE ${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
           ln -f "$FILE" "${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
        done
    else
        echo "It is a series: $DIR" >> ${LOGFILE}
        
        # Try to detect tvshow name
        # Get rid of unwanted characters and replaced them by space and get rid of trailing space
        TVSHOW_NAME=$(echo "$detectTVShow" | eval ${GET_TVSHOW_NAME})
        echo "Tv Show name is : $TVSHOW_NAME" >> ${LOGFILE}

        echo "Create Directories for $DIR" >> ${LOGFILE}
        DIR_NAME=$(echo "$DIR" | cut -d "/" -f 4 | eval ${GET_TVSHOW_SEASON})
        mkdir -p "${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}" >> ${LOGFILE}

        # Detect useful files removing space in names, replacing them with underscore
        FILES=$(find "$DIR" -iname *mkv ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *avi ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *mp4 ! -iname "*sample*" | eval ${REMOVE_SPACE}) 2> /dev/null
        [ -n "$FILES" ] && for SAFE_FILE in $FILES
        do
           FILE=$(echo "$SAFE_FILE" | eval ${RETURN_SPACE})
           echo "Link: $FILE ${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}/" >> ${LOGFILE}
           ln -f "$FILE" "${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}/" >> ${LOGFILE}
        done
    fi
    echo -n "|${DIR}" >> ${PROCESSED_DIR}
done

echo "Processing Files" >>  ${LOGFILE}
for SAFE_FILE in $LS_FILES
do
    # Detect useful files removing space in names, replacing them with underscore
    FILE=$( echo "$SAFE_FILE" | eval ${RETURN_SPACE})
    EXTENSION=$(echo "$FILE" | grep -E -o ${EXTENSION_PATTERN})
    NAME=$(echo "$FILE" | cut -d"/" -f 4 | grep -E -o ${MOVIENAME_PATTERN} | eval ${SURROUND_YEARS})
    if [ "$EXTENSION" = ".avi" -o "$EXTENSION" = ".mkv" -o "$EXTENSION" = ".mp4" ]
    then
        echo "Link: $FILE ${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
        ln -f "$FILE" "${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
        echo -n "|${FILE}" >> ${PROCESSED_FILE}
    fi
done
echo "End: $(date +%H:%M)" >>  ${LOGFILE}

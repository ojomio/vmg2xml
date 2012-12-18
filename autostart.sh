#!/bin/sh


# Regex pattern used later

EXCLUDED_DIR="incoming|watch|\/$"
EXTENSION_PATTERN=".{4}$"
TVSHOW_PATTERN="saison|season|s[0-9]{2}"
MOVIENAME_PATTERN=".*[0-9]{4}"
REMOVE_SPACE='s/ /_/g'
RETURN_SPACE='s/_/ /g'
GET_TVSHOW_NAME='s/(.*)([Ss]aison.*|[Ss]eason.*|[Ss][0-9]{1,2}).*/\1/'
GET_TVSHOW_SEASON= -e 's/^.*([Ss]aison.?[0-9]*).*/\1/' -e 's/.*[Ss]eason.?([0-9]*).*/Saison \1/' -e 's/.*[Ss].?([0-9]{2}).*/Saison \1/'
REMOVE_UNWANTED_CHARACTERS='s/[\.\-_]/ /g'
REMOVE_TRAILING_SPACE='s/ *$//'
SURROUND_YEARS='s/(\(?[0-9]{4})\)?/(\1)/'

# Global variable initialisation

LOGFILE=/storage/.log/autostart-$(date +%Y%m%d)
TVSHOWS_DIR=/storage/videos/
MOVIES_DIR=/storage/tvshows/
DOWNLOAD_DIR=/storage/downloads/
LS_DIR=$(find ${DOWNLOAD_DIR} -type d | grep -vE ${EXCLUDED_DIR} | sed ${REMOVE_SPACE} )
LS_FILES=$(find ${DOWNLOAD_DIR} -type f | grep -vE ${EXCLUDED_DIR} | sed ${REMOVE_SPACE})

echo "LS_DIR = $LS_DIR" >> ${LOGFILE}

echo "Processing Directories" >>  ${LOGFILE}
for SAFE_DIR in $LS_DIR
do
    # Restore right file name with space
    DIR=$(echo "$SAFE_DIR" | sed ${RETURN_SPACE})

    # Try to detect tvshow pattern
    detectTVShow=$(echo "$DIR" | cut -d"/" -f 4 | grep -Ei $TVSHOW_PATTERN)

    # Processing
    if [ x"${detectTVShow}" = x ]
    then
        echo "This directory contains a movie: ${DIR}" >> ${LOGFILE}

        # Detect useful files removing space in names, replacing them with underscore
    	FILES=$(find "$DIR" -iname *mkv | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *avi | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *mp4 | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -n "$FILES" ] &&  for SAFE_FILE in $FILES
    	do
    	   FILE=$( echo "$SAFE_FILE" | sed ${RETURN_SPACE})
    	   EXTENSION=$(echo "$FILE" | grep -E -o ${EXTENSION_PATTERN})
    	   NAME=$(echo "$FILE" | cut -d"/" -f 4 | grep -E -o ${MOVIENAME_PATTERN} | sed -r ${SURROUND_YEARS})
    	   echo "Create link into videos directory" >> ${LOGFILE}
           echo "Link: $FILE ${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
    	   ln -f "$FILE" "${MOVIES_DIR}${NAME}${EXTENSION}"
    	done
    else
        echo "It is a series: $detectTVShow" >> ${LOGFILE}
    	
    	# Try to detect tvshow name
    	# Get rid of unwanted characters and replaced them by space and get rid of trailing space
    	TVSHOW_NAME=$(echo "$detectTVShow" | sed -r -e ${GET_TVSHOW_NAME} -e ${REMOVE_UNWANTED_CHARACTERS} -e ${REMOVE_TRAILING_SPACE})
    	echo "Tv Show name is : $TVSHOW_NAME" >> ${LOGFILE}

        echo "Create Directories for $DIR" >> ${LOGFILE}
        DIR_NAME=$(echo "$DIR" | cut -d "/" -f 4 | sed -r ${GET_TVSHOW_SEASON})
    	echo "Directory to create:  ${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}" >> ${LOGFILE}
    	mkdir -p "${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}"

        # Detect useful files removing space in names, replacing them with underscore
    	FILES=$(find "$DIR" -iname *mkv | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *avi | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -z "$FILES" ] &&  FILES=$(find "$DIR" -iname *mp4 | sed ${REMOVE_SPACE}) 2> /dev/null
    	[ -n "$FILES" ] && for SAFE_FILE in $FILES
    	do
    	   FILE=$(echo "$SAFE_FILE" | sed ${RETURN_SPACE})
           echo "Files to link: $FILE ${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}/" >> ${LOGFILE}
    	   ln -f "$FILE" "${TVSHOWS_DIR}${TVSHOW_NAME}/${DIR_NAME}/"
    	done
    fi
done

for SAFE_FILE in $LS_FILES
do
	echo "Processing files" >> ${LOGFILE}
	echo "It is a movie" >> ${LOGFILE}
        # Detect useful files removing space in names, replacing them with underscore
        FILE=$( echo "$SAFE_FILE" | sed ${RETURN_SPACE})
        EXTENSION=$(echo "$FILE" | grep -E -o ${EXTENSION_PATTERN})
        NAME=$(echo "$FILE" | cut -d"/" -f 4 | grep -E -o ${MOVIENAME_PATTERN} | sed -r ${SURROUND_YEARS})
	if [ "$EXTENSION" = ".avi" -o "$EXTENSION" = ".mkv" -o "$EXTENSION" = ".mp4" ]
	then
           echo "Create link into videos directory" >> ${LOGFILE}
           echo "Link: $FILE ${MOVIES_DIR}${NAME}${EXTENSION}" >> ${LOGFILE}
           ln -f "$FILE" "${MOVIES_DIR}${NAME}${EXTENSION}"
        fi
done

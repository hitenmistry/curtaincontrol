#!/bin/bash
#
# Script to get sunrise and sunset times for updating curtain control
# crontab
#
# Utilises suncalc page from www.dawnsun.net with wget

# Set up some variables
DEBUG=1
DAY=`date +%d`
MONTH=`date +%m`
YEAR=`date +%Y`

# Strip leading 0's as it doesn't work with site
MONTH=`echo ${MONTH} | sed 's/^0//'`

if [ ${DEBUG} -ne 0 ]
then
    echo "==== Local Data ===="
    echo "`date`"
    echo "Day   = $DAY"
    echo "Month = $MONTH"
    echo "Year  = $YEAR"
fi

TMPFILE=/tmp/sunriseset

TIMEZONE=`date | awk '{ print $5 }'`

if [ ${DEBUG} -ne 0 ]
then
    echo "Timezone = $TIMEZONE"
    echo "===================="
fi

if [ "$TIMEZONE" = "BST" ]
then
    # BST: (summer)
    wget -O ${TMPFILE} "http://www.dawnsun.net/astro/suncalc/?sc=1&d=${DAY}&m=${MONTH}&y=${YEAR}&lad=51&lam=34&ns=N&lod=0&lom=7&we=W&th=0&tm=0&dst=1" > /dev/null 2>&1
if [ $? -ne 0 ]
then
    # There was an error getting the values so exit without any changes
    echo "ERROR getting sunrise/sunset times"
    echo "ERROR getting sunrise/sunset times from www.dawnsun.net for curtain crontab change" | mail -s "Curtain Control" hitman@gmail.com
    exit 1
fi
else
    # GMT
    wget -O ${TMPFILE} "http://www.dawnsun.net/astro/suncalc/?sc=1&d=${DAY}&m=${MONTH}&y=${YEAR}&lad=51&lam=34&ns=N&lod=0&lom=7&we=W&th=0&tm=0" > /dev/null 2>&1
if [ $? -ne 0 ]
then
    # There was an error getting the values so exit without any changes
    echo "ERROR getting sunrise/sunset times"
    echo "ERROR getting sunrise/sunset times from www.dawnsun.net for curtain crontab change" | mail -s "Curtain Control" hitman@gmail.com
    exit 1
fi
fi


# get Sunrise time and strip tags

# remove most HTML tags (accommodates multiple-line tags)
# sed -e :a -e 's/<[^>]*>//g;/</N;//ba'

SUNRISE=`grep -A 1 Rise ${TMPFILE} | tail -1 | sed 's/<dd>//' | sed 's^</dd>^^'`
SUNSET=`grep -A 1 Set ${TMPFILE} | tail -1 | sed 's/<dd>//' | sed 's^</dd>^^'`

if [ ${DEBUG} -ne 0 ]
then
    echo "==== Sunrise/set times for above date ===="
    echo "Sunrise = $SUNRISE"
    echo "Sunset  = $SUNSET"
    echo "=========================================="
fi

if [ ${DEBUG} -gt 0 ]
then
    rm ${TMPFILE}
fi

function subtractmins {

    TIME=$1 # TIME must be in HHMM format
    DEDUCTMINS=$2
    NEWTIME=`date +%H:%M --utc -d"today ${TIME:0:2}:${TIME:2:2} UTC - $DEDUCTMINS minutes"`
    echo $NEWTIME
}

SUNRISEHOUR=`echo ${SUNRISE} | cut -d":" -f1`
SUNRISEMIN=`echo ${SUNRISE} | cut -d":" -f2`
SUNSETHOUR=`echo ${SUNSET} | cut -d":" -f1`
SUNSETMIN=`echo ${SUNSET} | cut -d":" -f2`

SUNRISE=${SUNRISEHOUR}${SUNRISEMIN}
SUNSET=${SUNSETHOUR}${SUNSETMIN}

if [ ${DEBUG} -ne 0 ]
then
    echo "==== Sunrise components ===="
    echo "Sunrise Hour = $SUNRISEHOUR"
    echo "Sunrise Min = $SUNRISEMIN"
    echo "==== Sunset components ===="
    echo "Sunset Hour = $SUNSETHOUR"
    echo "Sunset Min = $SUNSETMIN"
    echo "==========================="
    echo "Sunrise = $SUNRISE"
    echo "Sunset  = $SUNSET"
fi

LOUNGESUNSET=`subtractmins $SUNSET 20`
BEDSUNSET=`subtractmins $SUNSET 10`

if [ ${DEBUG} -ne 0 ]
then
    echo "==== Modified times ===="
    echo "LOUNGESUNSET = $LOUNGESUNSET"
    echo "BEDSUNSET = $BEDSUNSET"
    echo "========================"
fi

SUNRISE="${SUNRISEHOUR}:${SUNRISEMIN}"
SUNSET="${SUNSETHOUR}:${SUNSETMIN}"

if [ ${DEBUG} -ne 0 ]
then
    echo "==== Sunrise components ===="
    echo "SUNRISEHOUR = $SUNRISEHOUR"
    echo "SUNRISEMIN = $SUNRISEMIN"
    echo "==== Sunset components ===="
    echo "SUNSETHOUR = $SUNSETHOUR"
    echo "SUNSETMIN = $SUNSETMIN"
    echo "==========================="
    echo "Sunrise = $SUNRISE"
    echo "Sunset  = $SUNSET"
fi

# Make sure Bedroom Hour is sensible!
BEDSUNRISEHOUR=`expr $SUNRISEHOUR + 0`

if [ $BEDSUNRISEHOUR -lt 7 ]
then
    BEDSUNRISEHOUR="07"
    if [ ${DEBUG} -ne 0 ]
    then
        echo "==== Ensuring BEDSUNRISEHOUR is Sensible ===="
        echo "BEDSUNRISEHOUR modified = $BEDSUNRISEHOUR"
        echo "============================================="
    fi
fi

#BEDSUNRISEHOUR=`echo ${SUNRISE} | cut -d":" -f1`
BEDSUNRISEMIN=${SUNRISEMIN}
BEDSUNSETHOUR=`echo ${BEDSUNSET} | cut -d":" -f1`
BEDSUNSETMIN=`echo ${BEDSUNSET} | cut -d":" -f2`
LOUNGESUNRISEHOUR=${SUNRISEHOUR}
LOUNGESUNRISEMIN=${SUNRISEMIN}
LOUNGESUNSETHOUR=`echo ${LOUNGESUNSET} | cut -d":" -f1`
LOUNGESUNSETMIN=`echo ${LOUNGESUNSET} | cut -d":" -f2`


if [ ${DEBUG} -ne 0 ]
then
    echo "Lounge Randomised Sunrise Hour = $LOUNGESUNRISEHOUR"
    echo "Lounge Randomised Sunrise Min = $LOUNGESUNRISEMIN"
    echo "Bed Randomised Sunrise Hour = $BEDSUNRISEHOUR"
    echo "Bed Randomised Sunrise Min = $BEDSUNRISEMIN"
    echo "Lounge Randomised Sunset Hour = $LOUNGESUNSETHOUR"
    echo "Lounge Randomised Sunset Min = $LOUNGESUNSETMIN"
    echo "Bed Randomised Sunset Hour = $BEDSUNSETHOUR"
    echo "Bed Randomised Sunset Min = $BEDSUNSETMIN"
fi

CRONTAB=/tmp/hiten.cron

crontab -l > $CRONTAB

# Use sed to replace the minutes
sed -i '/curtain_lounge_open/s/[0-9][0-9]/'${LOUNGESUNRISEHOUR}'/2' ${CRONTAB}
sed -i '/curtain_lounge_open/s/[0-9][0-9]/'${LOUNGESUNRISEMIN}'/' ${CRONTAB}

sed -i '/curtain_bedroom_open/s/[0-9][0-9]/'${BEDSUNRISEHOUR}'/2' ${CRONTAB}
sed -i '/curtain_bedroom_open/s/[0-9][0-9]/'${BEDSUNRISEMIN}'/' ${CRONTAB}

sed -i '/curtain_lounge_close/s/[0-9][0-9]/'${LOUNGESUNSETHOUR}'/2' ${CRONTAB}
sed -i '/curtain_lounge_close/s/[0-9][0-9]/'${LOUNGESUNSETMIN}'/' ${CRONTAB}

sed -i '/curtain_bedroom_close/s/[0-9][0-9]/'${BEDSUNSETHOUR}'/2' ${CRONTAB}
sed -i '/curtain_bedroom_close/s/[0-9][0-9]/'${BEDSUNSETMIN}'/' ${CRONTAB}

crontab ${CRONTAB}

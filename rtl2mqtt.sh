#!/bin/sh

export LANG=C
PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

CONFIG_PATH=/data/options.json
MQTT_HOST="$(jq --raw-output '.mqtt_host' $CONFIG_PATH)"
MQTT_USER="$(jq --raw-output '.mqtt_user' $CONFIG_PATH)"
MQTT_PASS="$(jq --raw-output '.mqtt_password' $CONFIG_PATH)"
MQTT_MSGTYPE="$(jq --raw-output '.msgType' $CONFIG_PATH)"
MQTT_IDS="$(jq --raw-output '.ids' $CONFIG_PATH)"


# Start the listener and enter an endless loop
echo "Starting RTL_433 with parameters:"
echo "MQTT Host =" $MQTT_HOST
echo "MQTT User =" $MQTT_USER
echo "MQTT Password =" $MQTT_PASS
echo "MQTT Message Type =" $MQTT_MSGTYPE
echo "MQTT Device IDs =" $MQTT_IDS


#set -x  ## uncomment for MQTT logging...
/usr/local/bin/rtl_tcp &>/dev/null &

sleep 10

/go/bin/rtlamr -format json -msgtype=$MQTT_MSGTYPE -filterid=$MQTT_IDS | while read line
do
  VAL="$(echo $line | jq --raw-output '.Message.Consumption' | tr -s ' ' '_')" # replace ' ' with '_'
  DEVICEID="$(echo $line | jq --raw-output '.Message.ID' | tr -s ' ' '_')"
  
  
  MQTT_PATH="readings/$DEVICEID/meter_reading"

  # Create file with touch /tmp/rtl_433.log if logging is needed
  [ -w /tmp/rtl_433.log ] && echo $line >> rtl_433.log
  echo $VAL | /usr/bin/mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -i RTL_433 -r -l -t $MQTT_PATH
done

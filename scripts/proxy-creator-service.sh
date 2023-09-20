UNIX_DIR=/home/proxy-installer
LOG_DIR=/home/proxy-installer
PID_FILE=/var/run/3proxy_service.pid

APP_PATH=/home/proxy-installer

SERVICE_NAME="3proxy Service"

start()
{
	if [ ! -e $UNIX_DIR ]
	then
		mkdir -p $UNIX_DIR
	fi

	if [ ! -e $LOG_DIR ]
	then
		mkdir -p $LOG_DIR
	fi

	if ps aux | grep -v grep | grep "java -jar proxy-creator-0.0.1.jar" > /dev/null
	then
		echo "$SERVICE_NAME still running"
	else
		echo "Start $SERVICE_NAME"
		cd $APP_PATH
		java -jar proxy-creator-0.0.1.jar > $LOG_DIR/PCoreService.log 2>&1 &
		echo $! > $PID_FILE
		echo '[OK]'
	fi
}

stop()
{
	echo "Stopping $SERVICE_NAME"
	cat $PID_FILE | xargs kill -9
	rm $PID_FILE
	echo '[OK]'
}

status()
{
	echo "Status"
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status
		;;
	restart)
		stop
		start
		;;
	*)
		echo "Usage: $0 {start|stop|restart|status}"
		;;
esac



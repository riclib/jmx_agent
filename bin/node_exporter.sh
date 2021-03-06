#!/bin/ksh
#set -x
#title           :node_exporter.sh
#description     :this script will start or stop prometheus node exporter
#author		 :Johan De Wulf
#date            :20180517
#version         :0.1    
#usage		 :node_exporter.sh [start|stop|status|version] 
#notes           :
#==============================================================================

usage()
{
  if [ ${#@} == 0 ]; then
    echo "usage: $0 [start|stop|status|version]"
    echo "* start: start prometheus node exporter"
    echo "* stop : stop prometheus node exporter"
    echo "* status: status prometheus node exporter"
    echo "* version: version prometheus node exporter"
fi
}

# Read the configuration file
if [ "x$RUN_CONF_SERVER" = "x" ]; then
  RUN_CONF_SERVER="./setEnv.ini"
fi

if [ -r "$RUN_CONF_SERVER" ]; then
  . "$RUN_CONF_SERVER"
fi

is_node_running()
{
  retval=""
  PID="`ps -ef | grep $node_prometheus_exporter_file-$node_exporter_version | grep $web_listen_address |awk '{print $2}' | wc -l`"
  if [ $PID -gt 0 ]
    then
      retval="true"
    else
      retval="false"
  fi
  echo "$retval"
}


status_node()
{
  PID="`ps -ef | grep $node_prometheus_exporter_file-$node_exporter_version | grep $web_listen_address |awk '{print $2}' | wc -l`"
  if [ $PID -gt 0 ]  
    then
      echo "prometheus node exporter running at address $web_listen_address"
    else
      echo "prometheus node exporter not running at address $web_listen_address"
  fi
}

version_node()
{
  if [ -f $node_prometheus_exporter_file-$node_exporter_version ]
    then
      ./$node_prometheus_exporter_file-$node_exporter_version --version
    else
      echo "prometheus node exporter file $node_prometheus_exporter_file-$node_exporter_version not found"
  fi  
}

stop_node()
{
  retval=$(is_node_running)
  if [ "$retval" == "true" ]
    then
      PID="`ps -ef | grep $node_prometheus_exporter_file-$node_exporter_version | grep $web_listen_address |awk '{print $2}'`"
      kill $PID ; sleep 10; kill -9 $PID >/dev/null 2>&1
      status_node
    else
      status_node
  fi 
}

start_node()
{
  retval=$(is_node_running)
  if [ "$retval" == "false" ]
    then
      nohup >/dev/null 2>&1 ./$node_prometheus_exporter_file-$node_exporter_version --collector.textfile.directory=$collector_textfile_directory --web.listen-address=$web_listen_address &
      status_node 
    else
      status_node
  fi
}

case "$1" in
  'start') start_node ;;
  'stop')  stop_node ;; 
  'status') status_node ;;
  'version') version_node ;;
  *) usage
esac

#!/bin/bash
#home dir
home="/apps/solidmon/collector"
#create the data directory
mkdir -p $home/data 

#create the default config if it doesn't exist
config_file=$home/conf/du_folders.conf

if [[ ! -f $config_file ]]; then
  echo >$config_file "/apps/adf/kafka/confluent_data_logs"
fi

#patch setEnv.ini if needed
grep -q -F 'collector_textfile_directory' setEnv.ini
if [ $? -ne 0 ]; then
  echo >>setEnv.ini 'export collector_textfile_directory="$solidmon_home/data"'
fi

# add the folder parameter to node exporter startup
cd $home/bin
mv node_exporter.sh node_exporter.sh.bak 
cat node_exporter.sh.bak | sed 's/version --web/version --collector.textfile.directory=$collector_textfile_directory --web/' >node_exporter.sh
chmod +x node_exporter.sh

# add to crontab if not there yet
line="*/5 * * * * du -d 1 -b \`tr '\n' ' ' < $config_file\` | sed > $home/data/directory_size.prom.\$\$ -ne 's/^\([0-9]\+\)\t\(.*\)$/node_directory_size_bytes{directory=\"\\2\"} \1/p' && mv $home/data/directory_size.prom.\$\$ $home/data/directory_size.prom"
echo "$line"
crontab -l | grep -q -F 'directory_size'
if [ $? -ne 0 ]; then
  (echo "$line" ; crontab -l 2>/dev/null) | crontab -
fi


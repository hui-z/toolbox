#!/bin/bash
# ZHOU Cheng <c.zhou@live.com>
# Disable Transparent Huge Pages (THP) in Ubuntu
# https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/

set -e

# Run as root
if [ "$EUID" -ne 0 ]
then echo "Please run as root"
    exit
fi

# Create the init.d script.
sudo cat > /etc/init.d/disable-transparent-hugepages << EOL
#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case $1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > ${thp_path}/enabled
    echo 'never' > ${thp_path}/defrag

    re='^[0-1]+$'
    if [[ $(cat ${thp_path}/khugepaged/defrag) =~ $re ]]
    then
      # RHEL 7
      echo 0  > ${thp_path}/khugepaged/defrag
    else
      # RHEL 6
      echo 'no' > ${thp_path}/khugepaged/defrag
    fi

    unset re
    unset thp_path
    ;;
esac
EOL

# Make it executable.
sudo chmod 755 /etc/init.d/disable-transparent-hugepages

# Configure your operating system to run it on boot.
sudo update-rc.d disable-transparent-hugepages defaults

# Test Changes
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

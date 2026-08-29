#!/bin/bash
(crontab -u $(whoami) -l; echo "0 0 * * * /usr/bin/unattended-upgrade -d" ) | crontab -u $(whoami) -
(crontab -u $(whoami) -l; echo "0 12 * * * /home/jaime/scripts/backup.sh" ) | crontab -u $(whoami) -
(crontab -u $(whoami) -l; echo "0 11 * * * sudo chown -R jaime /home/jaime/docker/" ) | crontab -u $(whoami) -
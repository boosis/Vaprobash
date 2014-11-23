#!/usr/bin/env bash

echo ">>> Installing Redis"

# Add repository
sudo apt-add-repository ppa:rwky/redis -y

# Install Redis
# -qq implies -y --force-yes
sudo apt-get install -y redis-server

# Redis Configuration
sudo mkdir -p /etc/redis/conf.d

# transaction journaling - config is written, only enabled if persistence is requested
cat << EOF | sudo tee /etc/redis/conf.d/journaling.conf
appendonly yes
appendfsync everysec
EOF

# Persistence
if [ ! -z "$1" ]; then
	if [ "$1" == "persistent" ]; then
		echo ">>> Enabling Redis Persistence"

		# add the config to the redis config includes
		if ! cat /etc/redis/redis.conf | grep -q "journaling.conf"; then
			sudo echo "include /etc/redis/conf.d/journaling.conf" >> /etc/redis/redis.conf
		fi

		# schedule background append rewriting
		if ! crontab -l | grep -q "redis-cli bgrewriteaof"; then
			line="*/5 * * * * /usr/bin/redis-cli bgrewriteaof > /dev/null 2>&1"
			(sudo crontab -l; echo "$line" ) | sudo crontab -
		fi
	fi # persistent
fi # arg check

sudo service redis-server restart

php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?
#
#if [ $PHP_IS_INSTALLED -eq 0 ]; then
#    # install php extencion
#    echo "" > answers.txt
#    sudo pecl install redis < answers.txt
#    rm answers.txt
#
#    # add extencion file and restart service
#    echo 'extension=redis.so' | sudo tee /etc/php5/mods-available/redis.ini
#
#    ln -s /etc/php5/mods-available/redis.ini /etc/php5/fpm/conf.d/20-mongo.ini
#    ln -s /etc/php5/mods-available/redis.ini /etc/php5/cli/conf.d/20-mongo.ini
#    sudo service php5-fpm restart
#fi

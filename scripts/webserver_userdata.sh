#!/bin/bash
sudo yum -y update
sudo yum -y install yum-utils
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install iotop iperf3 iptraf tcpdump git bash-completion
sudo yum -y install httpd php mysql php-mysql
sudo yum -y install python-pip
sudo yum -y install nethogs iftop lnav nmon tmux wireshark vsftpd ftp golang
sudo systemctl start httpd
sudo systemctl enable httpd
cd /var/www/html/
sudo git clone https://github.com/whchoi98/ec2meta-webpage.git
sudo systemctl restart httpd

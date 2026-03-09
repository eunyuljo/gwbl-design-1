#!/bin/bash
sudo yum -y update
sudo yum -y install yum-utils
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install jq httpd iptables-services php mysql php-mysql
sudo yum -y install iotop iperf3 iptraf tcpdump git bash-completion
sudo yum -y install python-pip
sudo yum -y install nethogs iftop lnav nmon tmux wireshark vsftpd ftp htop golang

# Enable IP Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Environment variable configuration (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document > /home/ec2-user/iid
export instance_interface=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
export instance_vpcid=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$instance_interface/vpc-id)
export instance_az=$(cat /home/ec2-user/iid | jq -r '.availabilityZone')
export instance_ip=$(cat /home/ec2-user/iid | jq -r '.privateIp')
export instance_region=$(cat /home/ec2-user/iid | jq -r '.region')
export gwlb_ip=$(aws --region $instance_region ec2 describe-network-interfaces --filters Name=vpc-id,Values=$instance_vpcid | jq ".NetworkInterfaces[] | select(.AvailabilityZone==\"$instance_az\") | select(.InterfaceType==\"gateway_load_balancer\") | .PrivateIpAddress" -r)

# Webpage configuration
sudo systemctl start httpd
sudo systemctl enable httpd
sudo chown -R $USER:$USER /var/www
cat > /var/www/html/index.html <<EOF
<h1>Gateway Load Balancer Test:</h1>
<html><h2>My Public IP is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4/)</h2></html>
<html><h2>My Private IP is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4/)</h2></html>
<html><h2>My Host Name is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/hostname/)</h2></html>
<html><h2>My instance-id is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id/)</h2></html>
<html><h2>My instance-type is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)</h2></html>
<html><h2>My placement/availability-zone is: $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)</h2></html>
EOF
sudo systemctl restart httpd

# Start and configure iptables
sudo systemctl enable iptables
sudo systemctl start iptables

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

# Configure nat table to hairpin traffic back to GWLB
sudo iptables -t nat -A PREROUTING -p udp -s $gwlb_ip -d $instance_ip -i eth0 -j DNAT --to-destination $gwlb_ip:6081
sudo iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $gwlb_ip -d $gwlb_ip -o eth0 -j MASQUERADE

sudo service iptables save

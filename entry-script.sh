echo "Installing Docker"
sudo yum update -y && sudo yum install -y docker
echo "Docker Start System Control"
sudo systemctl start docker
echo "Docker User Group Add"
sudo usermod -aG docker ec2-user
echo "Setting Docker Permissions"
sudo chmod 666 /var/run/docker.sock
echo "Docker Run Nginx"
docker run -d -p 8080:80 nginx
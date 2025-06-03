#!/bin/bash
yum update -y
amazon-linux-extras enable docker
yum install docker -y
service docker start
usermod -a -G docker ec2-user

# Pull and run your app container
docker pull karthik0741/images:petclinic_img
docker run -d \
  -e MYSQL_URL=jdbc:mysql://${mysql_url}/petclinic \
  -e MYSQL_USER=petclinic \
  -e MYSQL_PASSWORD=petclinic \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=petclinic \
  -p 80:8080 \
  karthik0741/images:petclinic_img

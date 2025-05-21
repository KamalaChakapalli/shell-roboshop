#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0d920b3da6141e705"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z0185878EC5RA4SI82RG"
DOMAIN_NAME="daws84skc.site"

for instance in ${INSTANCES[0]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t2.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance, Tags=[{Key=name, Value=test}]" ---query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
    echo "$instance ipaddress is: $IP"
done
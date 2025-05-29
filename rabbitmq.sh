#!/bin/bash

source ./common.sh
app_name=rabbitmq

CHECK_ROOT

echo "Please enter rabbitmq password to setup"
read -s RABBITMQ_PASSWD
VALIDATE $? "Reading rabbitmq password"

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq repo"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing Rabbitmq server"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling rabbitmq server"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Starting mabbitmq server"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWD &>> $LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE

PRINT_TIME
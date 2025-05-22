#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/logs/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" &>> $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $Log_File
    exit 1 #you can give any value upto 127 other than 0
else
    echo "You are running with root access" | tee -a $Log_File
fi

#validate functions takes the exit status of previous command as input

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $Log_File
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "Disabling default nginx"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
VALIDATE $? "Enabling nginx:1.24"

dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> $LOG_FILE
systemctl start nginx
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Removing default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx
VALIDATE $? "Restarting nginx"

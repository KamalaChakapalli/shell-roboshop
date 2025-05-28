#!/bin/bash

START_TIME=$(date +%s)
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
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #you can give any value upto 127 other than 0
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

#validate functions takes the exit status of previous command as input

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install golang -y &>> $LOG_FILE
VALIDATE $? "Installing Python3"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "Roboshop system user already present.. $Y so skipping $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $LOG_FILE
VALIDATE $? "Download of dispatch"

rm -rf /app/*
cd /app
unzip /tmp/dispatch.zip &>> $LOG_FILE
VALIDATE $? "Unzipping of dispatch"

go mod init dispatch &>> $LOG_FILE
VALIDATE $? "Building a module"

go get &>> $LOG_FILE
VALIDATE $? "Download Go packages"

go build &>> $LOG_FILE
VALIDATE $? "Building of packages"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Copying dispatch service"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon Reload"

systemctl enable dispatch &>> $LOG_FILE
VALIDATE $? "Enabling dispatch"

systemctl start dispatch &>> $LOG_FILE
VALIDATE $? "Starting dispatch"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
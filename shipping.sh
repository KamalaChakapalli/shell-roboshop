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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD
VALIDATE $? "Reading root password"

dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
VALIDATE $? "Download of shipping"

rm -rf /app/*
cd /app
unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Unzipping of shipping"

mvn clean package &>> $LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? "Moving and renaming the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon Reload"

systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.daws84skc.site -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
    mysql -h mysql.daws84skc.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>> $LOG_FILE
    mysql -h mysql.daws84skc.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>> $LOG_FILE
    mysql -h mysql.daws84skc.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>> $LOG_FILE
else
    echo -e "Data is already loaded into MYSQL.. $Y SKIPPING $N"
fi
VALIDATE $? "Loading data into MYSQL"

systemctl restart shipping &>> $LOG_FILE
VALIDATE $? "Restarting shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
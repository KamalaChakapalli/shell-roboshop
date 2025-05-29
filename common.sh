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
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

APP_SETUP()
{
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

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>> $LOG_FILE
    VALIDATE $? "Download of $app_name"

    rm -rf /app/*

    cd /app

    unzip /tmp/$app_name.zip &>> $LOG_FILE
    VALIDATE $? "Unzipping of $app_name"
}

NODEJS_SETUP()
{
    dnf module disable nodejs -y &>> $LOG_FILE
    VALIDATE $? "Disabling nodejs"

    dnf module enable nodejs:20 -y &>> $LOG_FILE
    VALIDATE $? "Enabling nodejs:20"

    dnf install nodejs -y &>> $LOG_FILE
    VALIDATE $? "Installing nodejs:20"

    npm install &>> $LOG_FILE
    VALIDATE $? "Installing dependencies"
}

PYTHON_SETUP()
{
    dnf install python3 gcc python3-devel -y &>> $LOG_FILE
    VALIDATE $? "Installing Python3"

    pip3 install -r requirements.txt &>> $LOG_FILE
    VALIDATE $? "Installing dependencies"
}
SYSTEMD_SETUP()
{
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Copying $app_name service"

    systemctl daemon-reload &>> $LOG_FILE
    systemctl enable $app_name &>> $LOG_FILE
    systemctl start $app_name
    VALIDATE $? "Starting $app_name"

}

CHECK_ROOT()
{
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
        exit 1 #you can give any value upto 127 other than 0
    else
        echo "You are running with root access" | tee -a $LOG_FILE
    fi
}

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

PRINT_TIME()
{
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
}
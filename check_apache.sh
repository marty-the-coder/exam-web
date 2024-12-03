#!/bin/bash

apache_running(){ #i make a function for saying it is running, then the date and put that into the "apache_status.log"
    echo "Apache was saved! It is now back up :) - $(date):" >> /home/marteck/eksamen8/apache_status.log #the echo is for what is should says. is prints everything that is within the ""
    #the >> says it should be put in something. and it is to add on and not replace what is already there.
    #then i make sure to put the full path to the log file so that it can find it.
    rm /tmp/apache_status #the rm removes the file. so if apache is running it removes it
    
}

apache_not_running(){ #this is the same as the one above, but is says apache is down
    echo "Apache is down, need a medic! - $(date)" >> /home/marteck/eksamen8/apache_status.log
    touch /tmp/apache_status
}

apache_status(){ #here i make a function for checking if apache is running.
#using the "if" tells the script that it is going to check a condition. In the same way it is used in day-to-day language
#the "systemctl" is a command-line tool that is part of systemd, which is a system and service manager for Linux operating systems. It is used to manage services (also known as daemons) and other system resources.
#the "is-active" is a subcommand of systemctl. It checks whether a specified service is currently active (running). In this case, we are checking the status of the Apache HTTP server.
#"--quiet" tells the script that this should not run in terminal. it should be run quiet.
#"apache2" tells that this is the system we are checking
#"then" follows the "if".
    if systemctl is-active --quiet apache2; then
    #the first scenerio is if apache is running
    if [ -f /tmp/apache_status ]; then #the "[ -f /tmp/apache_status ]" checks if the temporary apache_status file exists. if the file exists, then apache was not running during last check
    apache_running #it says that if apache is running, then it should print the "apache_running" function.
    fi
    else
    #the second scenerio is if apache is not running
    if [ ! -f /tmp/apache_status ]; then #the "!" reverses the command. so instead of checking if it exists, it checks if it doesnt exist.
    apache_not_running #the "else" means that if the first part is not true, meaning if apache is not running, then it sould print the "apache_not_running" function
    fi
    fi; #"fi" ends the "if"
}

apache_status

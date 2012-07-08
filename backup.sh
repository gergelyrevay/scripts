#/bin/sh
#variables for command line arguments
ssh_key=
host_name=
mysql_user=
mysql_pwd=
email=
path=

# what to backup
source_files="/etc /var/www /var/log /home /tmp/mysql_backup.gz /tmp/installed_packages"

# usage
usage() 
{
    echo " This script can create backup from a remote server."
    echo " Due to security reasons this script should run on the" 
    echo " backup server to pull the data."
    echo
    echo " $ backup.sh <OPTIONS>"
    echo 
    echo " OPTIONS:"
    echo
    echo " -i <ssh key>     the SSH identity key to use with rsync"
    echo " -h <host>        target host and username to backup from (i.e.:user@host)"
    echo " -u <username>    username for mysql db"
    echo " -p <passw>       password for mysql db"
    echo " -e <email>       email address to send emails to"
    echo " -d <path>        target directory for the backup"
}

# function to executo commands on the remote server
run_on_server()
{
    CMD="ssh -i $ssh_key $host_name $1"
    $CMD &> $log_file
    handle_error $? "run_on_server failed to run '$CMD'"
}

# function to dumpl mysql db
dump_mysql()
{
    run_on_server "mysqldump -u $mysql_user -p$mysql_pwd --all-databases | gzip > /tmp/mysql_backup.gz"
}

# function to dump installed package list
dump_installed_packages()
{
    run_on_server "dpkg --get-selections > /tmp/installed_packages"
}

# function to log in system log
logthis()
{
    logger "BACKUP: $1"
    echo BACKUP: $1 >> $log_file
}

# function to send email
mailme()
{
    logthis "mailme"
    handle_error $? "mailme failed"
}

handle_error()
{
    return_code="$1"
    msg="$2"
    if [ $return_code != 0 ]; then
    {
        logthis $msg
        exit 1
    } fi
}

# do the actual syncing
sync_backup()
{
    rsync -avzR -e "ssh -i $ssh_key" --rsync-path "sudo rsync" $host_name:"$source_files" $path &> $log_file
    handle_error $? "sync_backup failed"
}


if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts "i:h:u:p:e:d:" OPTIONS
do
    case $OPTIONS in
        i)
            ssh_key=$OPTARG
            ;;
        h)
            host_name=$OPTARG
            ;;
        u)
            mysql_user=$OPTARG
            ;;
        p)
            mysql_pwd=$OPTARG
            ;;
        e)
            email=$OPTARG
            ;;
        d)
            path=$OPTARG
            ;;
        ?)
            usage
            exit
            ;;
    esac    
done

# create current path
path=$path$(date | cut -d" " -f2)

if [ ! -d $path ]; then
    mkdir -p $path
    handle_error $? "Failed to create directory: $path"
    logthis "New directory is created:$path"
fi

path=$path/
log_file=$path/backup-$(date -I).log

logthis "Running backup"

dump_installed_packages
logthis "List of installed packages have dumped on remote server"

dump_mysql
logthis "Mysql dbs have dumped on remote server"

sync_backup
logthis "Syncing is successful"

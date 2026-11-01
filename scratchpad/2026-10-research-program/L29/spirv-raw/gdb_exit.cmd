set pagination off
set print thread-events off
set confirm off
handle SIGPIPE nostop noprint pass
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
source /root/stackhw.py
catch syscall exit_group
run
stackhw exit
info threads
kill
quit

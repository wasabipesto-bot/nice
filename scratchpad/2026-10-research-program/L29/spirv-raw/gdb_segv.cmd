set pagination off
set print thread-events off
set confirm off
handle SIGPIPE nostop noprint pass
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
source /root/stackhw.py
run
stackhw segv
bt 30
bt -25
kill
quit

#!/usr/bin/expect
# please install the expect firstly

set ip          [lindex $argv 0]
set userid      [lindex $argv 1]
set mypassword  [lindex $argv 2]
set mycommand   [lindex $argv 3]
set timeout 100

spawn ssh $userid@$ip $mycommand
expect {
    # First connect, finger print check
    "(yes/no*)?" {
        send "yes\r"
        expect "*password:"
        send "$mypassword\r"
    }
    # input password
    "*password:" {send "$mypassword\r"}
    # No need password
    "Finished" { send_user "Use SSH cypto not password!\n" }
}
expect eof

send_user "Remote execution done!\n"
exit 0
#!/usr/bin/expect
# please install the expect firstly

set ip          [lindex $argv 0]
set userid      [lindex $argv 1]
set mypassword  [lindex $argv 2]
set src   [lindex $argv 3]
set dst   [lindex $argv 4]
set timeout 1000

spawn scp $userid@$ip:$src $dst
expect {
    "(yes/no*)?" {
        send "yes\r"
        expect "*password:"
        send "$mypassword\r"
        }
    "*password:" {send "$mypassword\r"}
    "(y/n)" {send "y\r"}
    "100%"  {send_user "copy file done\n"}
}
expect eof

send_user "copy file done!\n"
exit 0
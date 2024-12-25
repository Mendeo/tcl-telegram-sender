set MESSAGE {Hello, User!}
set SCRIPT_DIR [file dirname [info script]]
set CREDENTIALS_FILE [file join $SCRIPT_DIR credentials.txt]
source [file join $SCRIPT_DIR sender.tcl]

set CRED [getCredentials $CREDENTIALS_FILE]

proc sendMessage {} {
	global MESSAGE
	global CRED
	SendMessageToTelegram $MESSAGE $CRED
	global telegram_sender_waiter
	vwait telegram_sender_waiter
	puts [lindex $telegram_sender_waiter 0]
}

sendMessage
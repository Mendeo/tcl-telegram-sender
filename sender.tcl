#!/usr/bin/env tclsh
package require http
package require tls

http::register https 443 ::tls::socket
http::config -useragent {Tcl telegram bot sender}

proc SendMessageToTelegram {message cred_list} {
	array set cred $cred_list
	set url "https://api.telegram.org/bot$cred(bot_token)/sendMessage"
	#set url {http://127.0.0.1}
	set body "{\"text\": \"$message\", \"chat_id\": \"$cred(chat_id)\"}"
	set contentType application/json
	post $url $body $contentType onTelegramServerRespond
}

proc onTelegramServerRespond {body} {
	if {[hasOkInRespond $body]} {
		global telegram_sender_waiter
		set telegram_sender_waiter [list {Message successfully sent to telegram.} 0]
	} else {
		global telegram_sender_waiter
		set telegram_sender_waiter [list {The server reported an error while sending a message to Telegram.} 5]
	}
}

proc hasOkInRespond {body} {
	set isOk false
	set body [string trim $body]
	if {![string equal [string index $body 0] "\{"]} {
		return false
	}
	#Убираем корневые фигурные скобки
	set body [string range $body 1 end-1]
	foreach el [split $body ,] {
		set keyValue [split $el :]
		set key [string trim [lindex $keyValue 0]]
		if {[string equal $key \"ok\"]} {
			set value [string trim [lindex $keyValue 1]]
			if {[string equal $value true] || [string equal $value \"true\"]} {
				set isOk true
			} else {
				break
			}
		}
	}
	return $isOk
}

proc post {url body contenType callback} {
	catch {http::geturl $url -headers [list Content-Type $contenType] -query $body -command [list onAnswer $callback]} errorOrToken
	if {[string first ::http:: $errorOrToken] == -1} {
		global telegram_sender_waiter
		set telegram_sender_waiter [list $errorOrToken 1]
		return
	}
	after 5000 {
		if {[info exist errorOrToken]} {
			http::reset $errorOrToken
		}
		global telegram_sender_waiter
		set telegram_sender_waiter [list {The telegram server is not respond} 2]
	}

	proc onAnswer {callback token} {
		upvar #0 $token res
		# foreach {key value} [array get res] {
		# 	puts "$key: $value"
		# }
		if {[string match *200* $res(http)]} {
			$callback $res(body)
		} elseif {[string length $res(http)] > 0} {
			global telegram_sender_waiter
			set telegram_sender_waiter [list "The telegram server respond with error: $res(http)" 4]
		} else {
			global telegram_sender_waiter
			set telegram_sender_waiter [list "The telegram server connection error: [lindex $res(error) 0]" 4]
		}
		http::cleanup $token
		return
	}
}

proc getCredentials {pathToCredentials} {
	set credStream [open $pathToCredentials r]
	set values {}
	while {![eof $credStream]} {
		set row [gets $credStream]
		if {[string length $row]} {
			set values [concat $values [split [string trim $row] =]]
		}
		
	}
	close $credStream
	return $values
}

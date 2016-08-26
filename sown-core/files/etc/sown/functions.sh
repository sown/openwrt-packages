#!/bin/ash
. /etc/sown/constants.sh

[ -z "$IPKG_INSTROOT" -a -f /lib/config/uci.sh ] && . /lib/config/uci.sh

include() {
	local file
	
	for file in $(ls $1/*.sh 2>/dev/null); do
		. $file
	done
}

# Utility function imitating Math.max(...)
# Takes any number of arguments
max()
{
	local n=$1
	shift
	
	while [ $# -gt 0 ]; do
		[ $1 -gt $n ] && n=$1
		shift
	done
	
	echo $n
}

# Safely get a value from a uci config file
# like 'uci get' only with a default value
# 
# Usage:
# 	uci_get_bool <config> <section> [<option>] <default>
uci_get()
{
	local config="$1"
	local section="$2"
	local option="$3"
	local default="$4"
	
	if [ $# -eq 3 ]; then
		default="$3"
		option=""
	else
		option=".$option"
	fi
	
	RESULT=`uci get ${config}.${section}${option} 2>/dev/null`
	if [ $? -gt 0 ]; then
		echo "$default"
	else
		echo "$RESULT"
	fi
}

# Safely get a (shell) boolean value from a uci config.
# Returns the exit code of the uci get command. Prints the boolean value (0 or 1)
# 
# Usage:
# 	uci_get_bool <arguments to 'uci_get'>
# 
uci_get_bool()
{
	local RESULT
	# using local with a subshell clobbers the exit code.
	RESULT=`uci_get $@`
	local ret=$?
	case "$RESULT" in
		0|off|false|disabled) RESULT='false';;
		*) RESULT='true';;
	esac
	echo $RESULT
	return $ret
}

# Execute a command for each uci object of a given type.
# The arguments to the command will be the name of the element, and the type
# 
# Usage:
# 	uci_foreach <command> <config_type> <package>
# 
uci_foreach()
{
	local function="$1"
	local cfgtype="$2"
	local package="$3"

	local matches=`uci show $package | grep "=$cfgtype" | sed -re "s/^(.+\..+)=$cfgtype$/\1/"`
	for m in $matches; do
		eval "$function \"$m\" \"$cfgtype\""
	done
}

# Regenerate and install the crontab from the currently enabled crontabs
# Currently enabled crontabs can be found in  /etc/sown/crontabs/current/
# Also: if cron is not running, starts cron.
#
# Usage:
# 	update_crontabs [flag]
#
# [flag]	Any value here will prevent cron from being started
#update_crontabs()
#{
#	local tmp_file=`mktemp -p /tmp crontab.wc.XXXXXX`
#	
#	for file in $(ls /etc/sown/crontabs/current/* 2>/dev/null); do
#		cat "$file" >> "$tmp_file"
#		# Make sure we have newlines
#		echo >> "$tmp_file"
#	done
#	
#	# Remove blank lines
#	local new_tmp_file=`mktemp -p /tmp crontab.wc.XXXXXX`
#	grep -v '^$' "$tmp_file" >> "$new_tmp_file"
#	rm "$tmp_file"
#	tmp_file="$new_tmp_file"
#	
#	
#	local old_md5=`crontab -l | md5sum`
#	local new_md5=`cat "$tmp_file" | md5sum`
#	
#	[ "$old_md5" != "$new_md5" ] && crontab "$tmp_file"
#	rm -f "$tmp_file"
#	
#	# Make sure cron starts if needed
#	if [ -z "$1" ]; then
#		if [ ! -e /var/run/crond.pid ] || ! proc_name_is `cat /var/run/crond.pid` "/usr/sbin/crond" ; then
#			[ ! -z "$(ls /etc/crontabs/ )" ] && [ $(cat /etc/crontabs/* | grep -v '^#' | wc -l ) -gt 0 ] && /etc/init.d/cron restart
#		fi
#	fi
#}

# Usage:
# enable_crontab <crontab_name>
#
# NB: does not update the current crontab
# Exits with code 0 (success) if a change was made. 1 otherwise
enable_crontab()
{
	`uci set crontabs.$1.enabled='true'`;
	RET=$?
	if [ $RET -lt 1 ] ; then
		`uci commit crontabs`
		RET=$?
	fi
	return $RET
}

# Usage:
# disable_crontab <crontab_name>
#
# NB: does not update the current crontab
# Exits with code 0 (success) if a change was made. 1 otherwise
disable_crontab()
{
	`uci set crontabs.$1.enabled='false'`
	RET=$?
	if [ $RET -lt 1 ] ; then
		`uci commit crontabs`
		RET=$?
	fi
	return $RET
}

# Usage:
# get_package_version <package_name>
# 
# Prints package version to stdout.
get_package_version()
{
	opkg list "$1" | cut -d " " -f 3
}

# Usage:
# get_file_mtime <filename>
#
# Prints the time of last modification as seconds since Epoch
get_file_mtime()
{
	stat -c '%Y' $1
}

get_file_mtime_safe()
{
	if [ ! -e "$1" ]; then
		echo '0'
	else
		get_file_mtime $1
	fi
}

# Usage:
# proc_name_is <pid> <name>
proc_name_is()
{
	[ -e "/proc/$1/exe" ] && [ "$2" == "$(get_proc_name $1 )" ]
	return $?
}

# Usage:
# get_proc_name <pid>
get_proc_name()
{
        local exe=`stat -c '%N' /proc/$1/exe | sed -r -e "s/^'.*' -> '(.+)'$/\1/"` 
	if [ "$exe" == "/bin/busybox" ]; then
		which `cat /proc/$1/cmdline | cut -f 1 | head -n 1`
	else
		echo "$exe"
	fi
}

# Updates a specified UCI config file.
# 
# Usage:
# 	update_config <package> <version> <config_file> [data]
# 
#  <config_file> UCI config file name
#  [data]        optional HTTP POST data
# 
# Returns zero only if a sucessful update was performed.
update_config()
{
	local package_name="$1"
	local version_number="$2"
	local config_file="$3"
	local data="$4"
	
	local last_modified=`uci_get $config_file '@meta[0]' last_modified '1970-01-01 00:00:00'`
	local hash_str=`uci_get $config_file '@meta[0]' 'hash' ''`
	
	local date=`date '+%a, %d %b %Y %T' -D '%Y-%m-%d %H:%M:%S' -d "$last_modified"`
	local extra_curl_options="header = \"If-Modified-Since: $date\""
	if [ "$hash_str" ]; then
		extra_curl_options="$extra_curl_options
header = \"If-None-Match: \\\"$hash_str\\\"\""
	fi
	local FILE
	FILE=`download_package_uri "$package_name" "$version_number" "uci_config_$config_file" uci_config "$data" "$extra_curl_options"`
	
	if [ $? -gt 0 ]; then
		return 1
	fi
	
	local SERVER_DATE=`grep '^Last-Modified:' "$FILE.headers" | tr -d '\r' | cut -d ' ' -f 2-`
	[ -z "$SERVER_DATE" ] && SERVER_DATE=`grep '^Date:' "$FILE.headers" | tr -d '\r' | cut -d ' ' -f 2-`
	SERVER_DATE=`date '+%Y-%m-%d %H:%M:%S' -D '%a, %d %b %Y %T' -d "$SERVER_DATE"`
	local SERVER_ETAG=`grep '^ETag:' "$FILE.headers" | tr -d '\r' | cut -d ' ' -f 2-`

	if [ "${hash_str}" != "" ] && [ "${SERVER_ETAG}" == "${hash_str}" ]; then
		return 1
	fi

	if [ "$last_modified" != "1970-01-01 00:00:00" ]; then
		local tmp=`mktemp -t`
        
		uci export $config_file >> "$tmp"
		uci import $config_file < "$FILE"
		
		if [ $? -gt 0 ]; then
			echo "Error loading UCI config. Reverting." >&2
			uci import $config_file < "$tmp"
			uci_commit $config_file
			rm "$tmp"
			mv "$FILE" "$FILE.fail"
			echo "Failed config in $FILE.fail." >&2
			return 1
		else
			rm "$tmp"
		fi
	else
		uci import $config_file < "$FILE"
	fi
	
	rm "$FILE" "$FILE.headers"
	
	uci set $config_file.@meta[0].etag="$SERVER_ETAG"
	uci set $config_file.@meta[0].last_modified="$SERVER_DATE"
	
	uci_commit $config_file
}

# Download a package URI built from the first 3 args.
# 
# Usage:
# 	download_package_uri <package> <version> <request_name> <expected_type> [data] [extra_curl_options]
# 
# <expected_type>      Expected response form
# [data]               optional HTTP POST data
# [extra_curl_options] Extra options added to the generated curl config file
# 
# Returns zero on succesful request matching the expected type, 1 otherwise.
# Returns 1 if the server responds with "HTTP/1.1 304 Not Modified".
# Prints the name of the resulting file(s) (Will be a directory if the expected type was an archive)
download_package_uri()
{
	local package_name=$1
	local version_number=$2
	local request_name=$3
	local expected_type=$4
	local data="$5"
	local extra_curl_options="$6"
	
	local url="`uci get sown_core.@node[0].config_URL`$package_name/$version_number/$request_name"
	local FILE
	FILE=`download_url "$url" "$data" "$extra_curl_options"`
	local res=$?
	
	if [ $res -gt 0 ]; then
		return 1
	fi
	
	if [ `head -n 1 "$FILE.headers" | grep 'HTTP/1.1 304 Not Modified' | wc -l` -ne 0 ]; then
		rm -f "$FILE" "$FILE.headers"
		return 1
	fi
	
	local content_type=`grep '^Content-Type:' "$FILE".headers | tr -d '\r' | cut -d ' ' -f 2`
	SERVER_DATE=`grep '^Date:' "$FILE.headers" | tr -d '\r' | cut -d ' ' -f 2-`
	export SERVER_DATE=`date '+%Y-%m-%d %H:%M:%S' -D '%a, %d %b %Y %T' -d "$SERVER_DATE"`
	export SERVER_ETAG=`grep '^ETag:' "$FILE.headers" | tr -d '\r' | cut -d ' ' -f 2-`

	local mismatch=false
	
	if [ "$expected_type" == 'text' ]; then
		if [ "$content_type" != "text/plain" ]; then
			mismatch=true
		fi
	elif [ "$expected_type" == 'uci_config' ]; then
		if [ "$content_type" != "application/x-uci" ]; then
			mismatch=true
		fi
	elif [ "$expected_type" == 'shell' ]; then
		if [ "$content_type" == "text/x-sh" ]; then
			. "$FILE"
			local res=$?
			rm -f "$FILE" "$FILE.headers"
			[ $res -gt 0 ] && exit $res
		else
			mismatch=true
		fi
	elif [ "$expected_type" == 'archive' ]; then
		if [ "$content_type" == "application/x-tar" ]; then
			TMPDATADIR=` mktemp -d -t`
			tar -x -f "$FILE" -C "$TMPDATADIR"
			rm -f "$FILE" "$FILE.headers"
			FILE="$TMPDATADIR"
		elif [ "$content_type" == "application/x-gtar" ]; then
			TMPDATADIR=` mktemp -d -t`
			tar -xz -f "$FILE" -C "$TMPDATADIR"
			rm -f "$FILE" "$FILE.headers"
			FILE="$TMPDATADIR"
		elif [ "$content_type" == "application/x-gzip" ]; then
			mv "$FILE" "$FILE.gz"
			gunzip "$FILE.gz"
			rm -f "$FILE.headers"
		else
			mismatch=true
		fi
	fi
	
	if $mismatch ; then
		echo "Response type mismatch: $expected_type expected, mime type $content_type returned." >&2
		echo "See $FILE.fail and $FILE.headers.fail for debugging" >&2
		mv "$FILE" "$FILE.fail"
		mv "$FILE.headers" "$FILE.headers.fail"
		return 1
	else
		echo "$FILE"
		return 0
	fi
}

# Usage:
# 	download_url <url> [data] [extra_curl_options]
# 
# [data]               optional HTTP POST data
# [extra_curl_options] Extra options added to the generated curl config file
# 
# Returns 1 on curl error, 0 otherwise.
# Prints the name of the downloaded file. The HTTP headers file can be found by adding .headers to that filename.
download_url()
{
	local url="$1"
	local data="$2"
	local extra_curl_options="$3"
	
	local FILE=`mktemp -t`
	local cfg=`mktemp -t`

	local CLIENT_CRT='/etc/sown/client.crt'
	local CLIENT_KEY='/etc/sown/client.key'
	local CLIENT_CA=`uci get sown_core.@node[0].config_ca`
	if [ -z "$CLIENT_CA" ]; then
		CLIENT_CA='/etc/sown/ca.crt'
	fi

	local INSTALLER_CRT='/etc/sown/installer/client.crt'
	local INSTALLER_KEY='/etc/sown/installer/client.key'
	local INSTALLER_CA='/etc/sown/installer/ca.crt'
	
	echo -e "silent\nshow-error\nremote-time\n" > $cfg
          
        if [ -e "$CLIENT_CA" ]; then                        
                local CA="$CLIENT_CA"                       
        else                                                                     
                local CA="$INSTALLER_CA"                    
        fi       
	
	if [ -e "$CLIENT_CRT" -a -e "$CLIENT_KEY" ]; then
		local CERT="$CLIENT_CRT"
		local KEY="$CLIENT_KEY"
	elif [ -e "$INSTALLER_CRT" -a -e "$INSTALLER_KEY" ]; then
		local CERT="$INSTALLER_CRT"
		local KEY="$INSTALLER_KEY"
	fi

	if [ ! -z "$CERT" -a ! -z "$KEY" -a ! -z "$CA" ]; then
		echo -e "cacert = \"$CA\"\n" >> $cfg
		echo -e "cert = \"$CERT\"\nkey = \"$KEY\"\n" >> $cfg
	fi

	if [ -n "$data" ]; then
		echo "data = \"$data\"" >> $cfg
	fi

	if [ "$extra_curl_options" ]; then
		echo "$extra_curl_options" >> $cfg
	fi

	echo -e "retry = 5\n-m 30" >> $cfg
	echo -e "output = \"$FILE\"\ndump-header = \"$FILE.headers\"" >> $cfg
	echo -e "url = \"$url\"\n" >> $cfg

	env -i /usr/bin/curl -K $cfg > "$cfg.log" 2>&1

	local res=$?
	if [ $res -gt 0 ] ; then
		echo "curl command failed with error code $res." >&2
		echo "curl command failed with error code $res." | /usr/bin/logger
		cat "$cfg" | /usr/bin/logger
		cat "$cfg.log" | /usr/bin/logger
		cat "$FILE.headers" | /usr/bin/logger
		rm "$cfg" "$cfg.log" "$FILE" "$FILE.headers"
		return 1
	fi

	rm "$cfg" "$cfg.log"
	echo "$FILE"
	return 0
}



# Regenerate and install the crontab from the currently enabled crontabs
# Currently enabled crontabs can be found in  /etc/config/crontabs
# Also: if cron is not running, starts cron.
#           
# Usage:
#       update_crontabs [flag]
#                                         
# [flag]        Any value here will prevent cron from being started
update_crontabs()
{
	local cron_file=`eval "echo \\\$ROOT_CRONTAB_FILE"`
	echo "# DO NOT EDIT THE CRONTAB HERE" > "$cron_file";
	echo "# It is automatically generated from /etc/sown/configure_scripts/available/crontabs" >> "$cron_file";
	echo "# which in turn is generated at boot" >> "$cron_file"; 
	COUNT=0;
	ENABLED=`uci get crontabs.@feature[$COUNT].enabled`
	COMMAND=`uci get crontabs.@feature[$COUNT].command`
	STATE=$?
	while [ $STATE -lt 1 ] ; do
		if [ "$ENABLED" == "true" ] ; then
			echo "$COMMAND" >> "$cron_file";
		else
			echo "# $COMMAND" >> "$cron_file";
		fi
		COUNT=$(($COUNT + 1));
		ENABLED=`uci get crontabs.@feature[$COUNT].enabled 2>/dev/null` 
		COMMAND=`uci get crontabs.@feature[$COUNT].command 2>/dev/null`
		STATE=$?	
	done

	local old_md5=`crontab -l | md5sum`
	local new_md5=`cat "$cron_file" | md5sum`
	                                                               
	[ "$old_md5" != "$new_md5" ] && crontab "$cron_file"           
 
 	# Make sure cron starts if needed
 	if [ -z "$1" ]; then
 		if [ ! -e /var/run/crond.pid ] || ! proc_name_is `cat /var/run/crond.pid` "/usr/sbin/crond" ; then
			[ ! -z "$(ls /etc/crontabs/ )" ] && [ $(cat /etc/crontabs/* | grep -v '^#' | wc -l ) -gt 0 ] && /etc/init.d/cron restart
		fi
	fi

}


# Generate a client nonce for initial provisioning phase
# Outputs the generated nonce
get_client_nonce(){
	if [ ! -f /etc/sown/firstrun_nonce ]; then
		part1=`dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum | awk '{print $1;}'`
		part2=`dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum | awk '{print $1;}'`
		part3=`dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum | awk '{print $1;}'`
		part4=`dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum | awk '{print $1;}'`
		nonce="${part1}${part2}${part3}${part4}"
		echo "${nonce}" > /etc/sown/firstrun_nonce
		echo $nonce
	else
		cat /etc/sown/firstrun_nonce
	fi
}
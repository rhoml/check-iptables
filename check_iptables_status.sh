#!/bin/bash
#
# Developers: Rhommel Lamas
# Purpose: Nagios Plugin for Iptables Rules load check
# Version 0.5
#
# ---------------------------------------- License -----------------------------------------------------
# 
# This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
# ---------------------------------------- Documentation -------------------------------------------------
#
# Documentation about iptables: ~:# man iptables
#
# This scripts is intended to be used to check if your iptables rules are set correctly load at any time,
#	I didn't find a better way to check if a server has your rules loaded so I check the number of 
#	configured rules and if they are less than they should be Nagios will send an alert using it 
#   notify service.
# 
# -----------------------------------------------------------------------------------------------------
#  Plugin Description
# -----------------------------------------------------------------------------------------------------
#
# This Plugin handled 2 States
#	OK - The number of Iprules equal o more than the minimun that we setup on the -r variable
#	CRITICAL - The number of IPrules are less than the minimun required.
#	UNKNOWN - It could be something about validation on the parameters
# 
# This plugin also send and log every check to the file $LOG so if the plugins goes critical we can se who
# disable the iptables comparing the time with the auth file.
#----------------------------------------------------------------------------------------------------------
# 	Initialization
#----------------------------------------------------------------------------------------------------------
LOG=/var/log/iptables/iptables.log

function usage()
{
	cat <<EOF
$0 -T <table> -r <min rules>
	<min rules>	Minimun quantity of rules.
	<table>		Table to check.  Currently available:
EOF
	sed 's%^%\t\t%' /proc/net/ip_tables_names
	echo
}

#
# Parameter Validation
##

while getopts "hT:r:" flag
do
	case "$flag" in
		h)
			usage
			exit 0
			;;
		T)
			table="$OPTARG"
			;;
		r)	minrules="$OPTARG"
			;;
	esac
done

shift `expr $OPTIND - 1`

if [ -z "$table" ]
then
	echo "Table must be set."
	usage
	exit 3
fi

if [ -z "$minrules" -o "$minrules" -lt 0 ]
then
	echo "min rules must be set and a number greater than 0."
	usage
	exit 3
fi

##
#	DO NOT MODIFY ANYTHING BELOW THIS
##

CHKIPTBLS="`/sbin/iptables -n -t $table -L |wc -l`"

if [ "$CHKIPTBLS" == 0 ]; then
	TOTRULES=$CHKIPTBLS
else
	TOTRULES=$[$CHKIPTBLS-8]
fi


if [ "$TOTRULES" -ge "$minrules" ]; then
                    echo "OK - Iptables are OK The Table $table has $TOTRULES rules configured"
                    # Nagios exit code 0 = status OK = green
                    exit 0
else
                    echo " CRITICAL - Iptables are CRITICAL The Table $table has $TOTRULES rules configured"
					for i in `w  -h | cut -f1 -d" " | sort | uniq`
					do
							
						echo "`date '+%d/%m/%Y - %H:%M:%S'` - CRITICAL - $i is logged in and there are only $TOTRULES loaded" >> $LOG
					done
                    # Nagios exit code 2 = status CRITICAL = red
                	exit 2                
fi

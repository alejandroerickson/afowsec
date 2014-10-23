#!/bin/bash

# Title: AFOWSEC: Alpine's Fragile One Way Sync for Email Contacts
#
# Author: Alejandro Erickson
#
# Notes: This script is supposed to update your ~/.addressbook file
# (for (al)pine) with google contacts.  It is fragile, and requires
# some manual updates to get it going.  Under ideal conditions, it
# will aquire your google contacts, format them into tab-separated
# alpine addresses, backup your .addressbook file, and add any
# non-duplicate entries it has created.  A duplicate is an address
# line that is identical to another.
#
# Requirements: googlecl (a command line tool for several things
# google... except search, for some reason).  On mac os, you need
# gnu-sed to be mapped to gsed. $HOME should be the path to your home
# folder.  You need to run, and authorise googlecl once before using
# this script.
#
# Usage: Just run the script in the command line, anywhere it will
# have write permissions (to make temp folders).
#


ADDR="$HOME"'/.addressbook'
TMP="$HOME"'/_tmp_addresses'
TMP2="$HOME"'/__tmp_addresses'

#if on mac os x, install gnu-sed for this to work
if [ "$(uname -s)" == "Darwin" ]
then
    SED="gsed"
else
    
    SED="sed"
fi

echo "" >  "$TMP2"
echo "" >  "$TMP"

#get the number of lines in the original addressbook
ADDRBAK="$HOME"'/.addressbook.bak'
cat "$ADDR" > "$ADDRBAK"
echo ""$ADDR" backed up to "$ADDRBAK""
PREVWC=`wc "$ADDR" | $SED 's/\([0-9]\) .*/\1/g'`

#for testing, replace the google command with this
#echo "Alejandro Erickson:work ate@uvic.ca, home alejandro.erickson@gmail.com, home al.erickson.math@gmail.com, other luther.driggers@gmail.com, other luther_driggers@mac.com"

#obtain contact list from googlecl in the above format and | sed
#commands which: prefix a copy of fname lname:, eliminate the words
#work, home, other, put prefix on its own line | sed command which:
#replaces spaces with _ on lines ending in ':' | sed command which:
#removes the newlines following ':' (the ones we just added | grep
#command which discards lines that have "None" in them.  append this
#to $TMP.
google contacts list --fields="name,email" --title=".*" --delimiter=":" | $SED 's/\(.*\):/\1:\t\1\t/g;s/work / /g;s/home / /g;s/other / /g;s/:/:\
/' | $SED '/.*:/ s/ /_/g' | $SED 'N;s/:\n//g' | egrep -v '\bNone\b' >> "$TMP"


#Separate nick TAB name TAB email1, email2, email3 into separate
# entries, with names nick_email1, nick_email2, nick
$SED 's/\(.*[^	]\)\(	.*	\) *\([^,]*\) *, *\(.*\)/\1_\3\2\3\n\1\2\4/g' "$TMP" > "$TMP2"

while ! diff "$TMP" "$TMP2" >/dev/null; do
    cat "$TMP2" > "$TMP"
    $SED 's/\(.*[^	]\)\(	.*	\) *\([^,]*\) *, *\(.*\)/\1_\3\2\3\n\1\2\4/g' "$TMP" > "$TMP2"
done

#append result to $ADDR and remove duplicates
cat "$TMP2" >> "$ADDR"

sort "$ADDR" > "$TMP2"
uniq "$TMP2" > "$ADDR"

#output size of change
echo "previous addressbook had "$PREVWC" entries and new one has `wc "$ADDR" | $SED 's/\([0-9]\) .*/\1/g'`"

rm "$TMP"
rm "$TMP2"


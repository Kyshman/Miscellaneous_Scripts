#!/bin/bash
TEMP_FILE=/tmp/bash_quotes.txt
curl -s http://bash.org/?random1|grep -oE "<p class=\"quote\">.*</p>.*</p>"|grep -oE "<p class=\"qt.*?</p>"|sed -e 's/<\/p>/\n/g' -e 's/<p class=\"qt\">//g' -e 's/<p class=\"qt\">//g'|perl -ne 'use HTML::Entities;print decode_entities($_),"\n"'|awk 'length($0)>0  {printf( $0 "\n%%\n" )}' > $TEMP_FILE
#sleep 1
#sed 's/.$//' bash_quotes.txt > bash_quotes_sed.txt
strfile $TEMP_FILE > /dev/null 2>&1
fortune $TEMP_FILE | sed 's/.$//'

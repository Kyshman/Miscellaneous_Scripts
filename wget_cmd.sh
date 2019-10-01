#!/usr/local/bin/fish
#set -e website
echo "Please enter website to download eg www.example.com and press [ENTER]:"
read website
wget \
     --recursive \
     -e robots=off \
     --no-clobber \
     --page-requisites \
     --adjust-extension \
     --convert-links \
     --restrict-file-names=windows \
     --domains $website \
     --no-parent \
     --mirror \
     --background \
     --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" \
     --output-file=/tmp/wget.log \
     --random-wait \
     	$website


         
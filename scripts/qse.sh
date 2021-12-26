#!/bin/bash

if [[ -n "$q" ]]; then
	q="$(echo "$q" | jq -Rr '@uri' | perl -pe 's/%20/+/g')"
	# agent="$(curl -sL 'https://generate-name.net/user-agent' | pup 'td.name text{}' | head -n 1 | perl -pe 'chomp if eof')"
	agent="$RANDOM$RANDOM"
	curl -sL "https://api.qwant.com/v3/search/web?count=10&q=${q}&t=web&locale=en_US&device=desktop&offset=0&safesearch=1" -H "user-agent: $agent" | jq '[ .data.result.items.mainline[] | select(.type == "web") ]'
fi

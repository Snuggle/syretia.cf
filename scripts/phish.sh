#!/bin/bash

phisherman() {
    curl -sLA 'blargbot https://blargbot.xyz' "https://api.phisherman.gg/v1/domains/$domain" > /home/webhookd/out/.phisherman."$timens"
}

gsb() {
    curl -sL "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=$domain" | tail -n 1 > /home/webhookd/out/.gsb."$timens"
}

rm -rf /home/webhookd/logs/*

if [[ -z "$url" ]]; then
    jq -cn '.domain |= null | .error |= "Missing url input" | .phish |= false | .redirect |= false | .source |= null | .url |= null'
    exit 0
fi

if [[ "$url" == "http"* ]]; then
    export domain="$(echo "$url" | cut -f3 -d '/' | perl -pe 's%^www\.%%')"
else
    export domain="$(echo "$url" | cut -f1 -d '/' | perl -pe 's%^www\.%%')"
fi

redirect="$(jq -r --arg d "$domain" 'any(.[] == $d; .)' /home/webhookd/jsonlite/domains/shorteners)"

if [[ "$redirect" == "true" ]]; then
    domain="$(curl -sIX HEAD "$url" 2>/dev/null | grep -im1 '^location:' | cut -f3 -d'/')"
    if [[ -z "$domain" ]]; then
        jq -cn --arg u "$url" \
        '.domain |= null | .error |= "Failed to follow redirect" | .phish |= false | .redirect |= true | .source |= null | .url |= $u'
        exit 0
    fi
fi

export timens="$(date +%s%N)"

if [[ "$info" == "true" ]]; then
    curl -sL "https://urlscan.io/api/verdict/$domain" | jq -c '.'
    exit 0
fi

yachts="$(jq -r --arg d "$domain" 'any(.[] == $d; .)' /home/webhookd/jsonlite/domains/blacklist)"

if [[ "$yachts" == "true" ]]; then
    echo "{\"domain\":\"$domain\",\"error\":null,\"phish\":true,\"redirect\":$redirect,\"source\":\"phish.sinking.yachts\",\"url\":\"$url\"}"
    # jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    # '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "phish.sinking.yachts" | .url |= $u'
    exit 0
fi

phisherman &
gsb &

wait

phisherman="$(cat /home/webhookd/out/.phisherman."$timens")"
gsb="$(cat /home/webhookd/out/.gsb."$timens")"

rm -rf /home/webhookd/out/.phisherman."$timens"
rm -rf /home/webhookd/out/.gsb."$timens"

if [[ "$phisherman" == "true" ]]; then
    echo "{\"domain\":\"$domain\",\"error\":null,\"phish\":true,\"redirect\":$redirect,\"source\":\"phisherman.gg\",\"url\":\"$url\"}"
    # jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    # '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "phisherman.gg" | .url |= $u'
    exit 0
fi

if [[ "$(echo "$gsb" | jq '.[0][4]')" == "1" ]]; then
    echo "{\"domain\":\"$domain\",\"error\":null,\"phish\":true,\"redirect\":$redirect,\"source\":\"Google Safe Browsing\",\"url\":\"$url\"}"
    # jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
    # '.domain |= $d | .error |= null | .info |= $i | .phish |= true | .redirect |= $r | .source |= "Google Safe Browsing" | .url |= $u'
    exit 0
fi

echo "{\"domain\":\"$domain\",\"error\":null,\"phish\":false,\"redirect\":$redirect,\"source\":null,\"url\":\"$url\"}"
# jq -cn --arg d "$domain" --argjson i "$info" --argjson r "$redirect" --arg u "$url" \
# '.domain |= $d | .error |= null | .info |= $i | .phish |= false | .redirect |= $r | .source |= null | .url |= $u'

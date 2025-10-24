#!/usr/bin/env bash

SRVPORT=4499
RSPFILE=/tmp/response

# Ensure we're in a writable directory
cd /tmp

rm -f $RSPFILE
mkfifo $RSPFILE

get_api() {
        read line
        echo $line
}

handleRequest() {
    # 1) Process the request
        get_api
        mod=$(/usr/games/fortune)

cat <<RESPONSE_EOF > $RSPFILE
HTTP/1.1 200


<pre>$(/usr/games/cowsay "$mod")</pre>
RESPONSE_EOF
}

prerequisites() {
        [ -f /usr/games/cowsay ] &&
        [ -f /usr/games/fortune ] ||
                {
                        echo "Install prerequisites."
                        exit 1
                }
}

main() {
        prerequisites
        echo "Wisdom served on port=$SRVPORT..."

        while [ 1 ]; do
                cat $RSPFILE | nc -lN $SRVPORT | handleRequest
                sleep 0.01
        done
}

main

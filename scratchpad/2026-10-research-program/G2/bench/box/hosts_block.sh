#!/bin/sh
# on box: map production hosts to loopback, then prove the block
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  grep -q "127.0.0.1 $h\$" /etc/hosts || printf '127.0.0.1 %s\n::1 %s\n' $h $h >> /etc/hosts
done
date -u; cat /etc/hosts
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  getent hosts $h; curl -s -m 8 -o /dev/null -w '%{http_code} ' https://$h/; echo "curl $h exit=$?"
done
echo "github $(curl -s -m 8 -o /dev/null -w '%{http_code}' https://github.com/)"

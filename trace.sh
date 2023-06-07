traceroute openapi.yeepay.com > luyou.txt
ping openai.yeepay.com -c 30 > ping.txt
tcpdump -i any -nn host 103.143.19.4 or host 118.184.157.230 -C 15 -W 10 -w `hostname`_openapi.cap

#!/bin/sh
docker run --rm -d -p 9099:8080 \
-e WALLET=0xE84b7EADb9A332580b60d2de1E3ba175834379Fd \
-e POOL_HOST=asia1.ethermine.org \
-e POOL_PORT=4444 \
-e POOL_FAILOVER_ENABLE=True \
-e POOL_HOST_FAILOVER1=eu1.ethermine.org \
-e POOL_PORT_FAILOVER1=4444 \
-e POOL_HOST_FAILOVER2=us1.ethermine.org \
-e POOL_PORT_FAILOVER2=4444 \
-e POOL_HOST_FAILOVER3=us2.ethermine.org \
-e POOL_PORT_FAILOVER3=4444 yuriba/eth-proxy

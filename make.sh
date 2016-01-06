set -ex
DC=us-east-3b
export SDC_URL="https://${DC}.api.joyent.com"
UUID=$(sdc-getaccount | json id)
PUB="${UUID}.${DC}.triton.zone"
PRIV="${UUID}.${DC}.cns.joyent.us"

docker run -d -l triton.cns.services=demo-db --restart=always rethinkdb
sleep 60
docker run -d -l triton.cns.services=demo-db --restart=always rethinkdb rethinkdb --bind all --join demo-db.svc.${PRIV}:29015
sleep 10
docker run -d -l triton.cns.services=demo-db --restart=always rethinkdb rethinkdb --bind all --join demo-db.svc.${PRIV}:29015

docker run -d -l triton.cns.services=demo-app --restart=always quay.io/arekinath/demo-app
docker run -d -l triton.cns.services=demo-app --restart=always quay.io/arekinath/demo-app
docker run -d -l triton.cns.services=demo-app --restart=always quay.io/arekinath/demo-app
docker run -d -l triton.cns.services=demo-app --restart=always quay.io/arekinath/demo-app
sleep 60

docker run -d -l triton.cns.services=demo-lb --restart=always -p 80 quay.io/arekinath/demo-lb
docker run -d -l triton.cns.services=demo-lb --restart=always -p 80 quay.io/arekinath/demo-lb
docker run -d -l triton.cns.services=demo-lb --restart=always -p 80 quay.io/arekinath/demo-lb
sleep 60

echo "running at http://demo-lb.svc.${PUB}/"

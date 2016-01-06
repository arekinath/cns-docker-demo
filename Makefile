UUID ?=		$(shell sdc-getaccount | json id)
IMGPREFIX ?=	quay.io/arekinath/
DC ?=		us-east-3b
PRIVSUFFIX =	$(ACCOUNT_UUID).$(DC).cns.joyent.us
PUBSUFFIX =	$(ACCOUNT_UUID).$(DC).triton.zone

app/rethinkdb-example-nodejs:
	cd app && \
	git clone https://github.com/arekinath/rethinkdb-example-nodejs

demo-app.img.tar: app/Dockerfile app/config.js app/rethinkdb-example-nodejs
	docker build -t $(IMGPREFIX)demo-app -f app/Dockerfile && \
	docker save -o $@ $(IMGPREFIX)demo-app

nginx.img.tar: nginx/Dockerfile
	docker build -t $(IMGPREFIX)alpine-nginx-lua -f nginx/Dockerfile && \
	docker save -o $@ $(IMGPREFIX)alpine-nginx-lua

demo-lb.img.tar: lb/Dockerfile lb/nginx.conf nginx.img.tar
	docker build -t $(IMGPREFIX)demo-lb -f lb/Dockerfile && \
	docker save -o $@ $(IMGPREFIX)demo-lb

% :: %.in
	sed 	-e 's/%%UUID%%/$(UUID)/g' \
		-e 's/%%IMGPREFIX%%/$(IMGPREFIX)/g' \
		-e 's/%%PRIVSUFFIX%%/$(PRIVSUFFIX)/g' \
		-e 's/%%PUBSUFFIX%%/$(PUBSUFFIX)/g' \
		< $<  > $@

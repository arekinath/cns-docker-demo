UUID ?=		$(shell sdc-getaccount | json id)
IMGPREFIX ?=	quay.io/arekinath/
DC ?=		us-east-3b
PRIVSUFFIX =	$(UUID).$(DC).cns.joyent.us
PUBSUFFIX =	$(UUID).$(DC).triton.zone

.PHONY: build
build: demo-app.img.tar demo-lb.img.tar

.PHONY: push
push: build
	docker push $(IMGPREFIX)alpine-nginx-lua && \
	docker push $(IMGPREFIX)demo-app && \
	docker push $(IMGPREFIX)demo-lb

.PHONY: clean
clean:
	git clean -fd

app/repo:
	cd app && \
	git clone https://github.com/arekinath/rethinkdb-example-nodejs repo

demo-app.img.tar: app/Dockerfile app/config.js app/repo
	cd app && \
	docker build -t $(IMGPREFIX)demo-app . && \
	cd .. && \
	docker save -o $@ $(IMGPREFIX)demo-app

nginx.img.tar: nginx/Dockerfile
	cd nginx && \
	docker build -t $(IMGPREFIX)alpine-nginx-lua . && \
	cd .. && \
	docker save -o $@ $(IMGPREFIX)alpine-nginx-lua

demo-lb.img.tar: lb/Dockerfile lb/nginx.conf nginx.img.tar
	cd lb && \
	docker build -t $(IMGPREFIX)demo-lb . && \
	cd .. && \
	docker save -o $@ $(IMGPREFIX)demo-lb

% :: %.in
	@sed 	-e 's/%%UUID%%/$(UUID)/g' \
		-e 's|%%IMGPREFIX%%|$(IMGPREFIX)|g' \
		-e 's/%%PRIVSUFFIX%%/$(PRIVSUFFIX)/g' \
		-e 's/%%PUBSUFFIX%%/$(PUBSUFFIX)/g' \
		< $<  > $@

.PHONY: deploy
deploy: deploy_dbs
	@echo "running at http://demo-lb.svc.$(PUBSUFFIX)"

.PHONY: deploy_dbs
deploy_dbs: .deploy_firstdb .deploy_db2 .deploy_db3

.PHONY: pull_rethinkdb
pull_rethinkdb:
	docker pull rethinkdb

.deploy_firstdb: pull_rethinkdb
	docker run -d -l triton.cns.services=demo-db --restart=always \
		rethinkdb rethinkdb --bind all
	@sh wait_dns.sh demo-db.svc.$(PRIVSUFFIX) 1
	@sleep 10
	touch $@

.deploy_db%: .deploy_firstdb
	docker run -d -l triton.cns.services=demo-db --restart=always \
		rethinkdb rethinkdb --bind all \
		--join demo-db.svc.$(PRIVSUFFIX):29015
	@sleep 10
	touch $@

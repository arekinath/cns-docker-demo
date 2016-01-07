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
deploy: deploy_dbs deploy_apps deploy_lbs
	@echo "running at http://demo-lb.svc.$(PUBSUFFIX)"

.PHONY: deploy_dbs
deploy_dbs: .deploy_firstdb .deploy_db2 .deploy_db3

.pull:
	docker pull rethinkdb && \
	docker pull $(IMGPREFIX)demo-app && \
	docker pull $(IMGPREFIX)demo-lb && \
	touch $@

.deploy_firstdb: .pull
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

.PHONY: deploy_apps
deploy_apps: .deploy_app1 .deploy_app2 .deploy_app3 .deploy_app4

.deploy_app%: .pull .deploy_firstdb
	docker run -d -l triton.cns.services=demo-app --restart=always \
		quay.io/arekinath/demo-app
	@sh wait_dns.sh demo-app.svc.$(PRIVSUFFIX) 1
	touch $@

.PHONY: deploy_lbs
deploy_lbs: .deploy_lb1 .deploy_lb2 .deploy_lb3

.deploy_lb%: .pull .deploy_app1
	docker run -d -l triton.cns.services=demo-lb --restart=always -p 80 \
		quay.io/arekinath/demo-lb
	@sh wait_dns.sh demo-lb.svc.$(PUBSUFFIX) 1
	touch $@

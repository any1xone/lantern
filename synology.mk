SHELL := /bin/bash
PWD :=$(shell pwd)

# generating binary:
LANTERN_SYNO_BIN=lantern_linux_arm-syno

GIT_REVISION_SHORTCODE := $(shell git rev-parse --short HEAD)
SHELL := /bin/bash

SYNO_TOOLCHAINS_PREFIX=$(PWD)/synology-toolchains
SYNO_TARGET=arm-marvell-linux-gnueabi
SYNO_TOOLCHAINS_PATH=$(SYNO_TOOLCHAINS_PREFIX)/$(SYNO_TARGET)/bin


define build-tags
	BUILD_TAGS="" && \
	EXTRA_LDFLAGS="" && \
	if [[ ! -z "$$VERSION" ]]; then \
		EXTRA_LDFLAGS="-X github.com/getlantern/flashlight.compileTimePackageVersion=$$VERSION"; \
	else \
		echo "** VERSION was not set, using default version. This is OK while in development."; \
	fi && \
	if [[ ! -z "$$HEADLESS" ]]; then \
		BUILD_TAGS="$$BUILD_TAGS headless"; \
	fi && \
	BUILD_TAGS=$$(echo $$BUILD_TAGS | xargs) && echo "Build tags: $$BUILD_TAGS" && \
	EXTRA_LDFLAGS=$$(echo $$EXTRA_LDFLAGS | xargs) && echo "Extra ldflags: $$EXTRA_LDFLAGS"
endef

RESOURCES_DOT_GO := ./src/github.com/getlantern/flashlight/ui/resources.go

all: $(LANTERN_SYNO_BIN)

$(RESOURCES_DOT_GO): $(NPM)
	@source setenv.bash && \
	LANTERN_UI="src/github.com/getlantern/lantern-ui" && \
	APP="$$LANTERN_UI/app" && \
	DIST="$$LANTERN_UI/dist" && \
	echo 'var LANTERN_BUILD_REVISION = "$(GIT_REVISION_SHORTCODE)";' > $$APP/js/revision.js && \
	git update-index --assume-unchanged $$APP/js/revision.js && \
	DEST="$@" && \
	cd $$LANTERN_UI && \
	npm install && \
	rm -Rf dist && \
	gulp build && \
	cd - && \
	rm -f bin/tarfs bin/rsrc && \
	go install github.com/getlantern/tarfs/tarfs && \
	echo "// +build !stub" > $$DEST && \
	echo " " >> $$DEST && \
	tarfs -pkg ui $$DIST >> $$DEST && \
	go install github.com/akavel/rsrc && \
	rsrc -ico installer-resources/windows/lantern.ico -o src/github.com/getlantern/flashlight/lantern_windows_386.syso

$(LANTERN_SYNO_BIN): check-syno-toolchains $(RESOURCES_DOT_GO)
	@source setenv.bash && \
	HEADLESS=1 && \
	$(call build-tags) && \
	PATH=$(SYNO_TOOLCHAINS_PATH):$$PATH && \
	CC=$(SYNO_TARGET)-gcc CXX=$(SYNO_TARGET)-g++ LD=$(SYNO_TARGET)-ld RANLIB=$(SYNO_TARGET)-ranlib \
	CGO_ENABLED=1 GOOS=linux GOARCH=arm GOARM=5 \
	go build -a -o $@ -tags="$$BUILD_TAGS" -ldflags="$(LDFLAGS) $$EXTRA_LDFLAGS -linkmode internal -extldflags \"-static\"" github.com/getlantern/flashlight/main && \
	$(SYNO_TARGET)-strip $@

# install synology cross-compling tools
## current install for DS212J: Marvel Kirkwood mv6281 (ARM models v5)
## get your toolchains here: https://sourceforge.net/p/dsgpl/activity?source=project_activity
SYNO_TOOLCHAINS_URL="http://jaist.dl.sourceforge.net/project/dsgpl/DSM%206.0%20Beta2%20Tool%20Chains/Marvell%2088F628x%20Linux%202.6.32/6281-gcc464_glibc215_88f6281-GPL.txz"

check-syno-toolchains:
	@if [ ! -f $(SYNO_TOOLCHAINS_PATH)/$(SYNO_TARGET)-strip ]; then \
		echo "installing Synology toolchains for $(SYNO_TARGET) ..."; \
		mkdir -p $(SYNO_TOOLCHAINS_PREFIX) && \
		curl -sSL $(SYNO_TOOLCHAINS_URL) | tar Jxf - -C $(SYNO_TOOLCHAINS_PREFIX) || \
		(rm -fr $(SYNO_TOOLCHAINS_PREFIX) && \
		echo "failed to download/install Synology toolchains.\n Maybe you should do it manually in $(SYNO_TOOLCHAINS_PREFIX).") \
	fi


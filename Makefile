# Go parameters
TEAM=team
SINGLE=single
GO_CMD=go
GO_BUILD=$(GO_CMD) build
GO_CLEAN=$(GO_CMD) clean
GO_TEST=$(GO_CMD) test
GO_TOOL_COVER=$(GO_CMD) tool cover
GO_GET=$(GO_CMD) get
BINARY_NAME=rit
SINGLE_CMD_PATH=./cmd/$(SINGLE)/main.go
TEAM_CMD_PATH=./cmd/$(TEAM)/main.go
BIN=bin
DIST=dist
DIST_MAC=$(DIST)/darwin
DIST_MAC_TEAM=$(DIST_MAC)/$(TEAM)
DIST_MAC_SINGLE=$(DIST_MAC)/$(SINGLE)
DIST_LINUX=$(DIST)/linux
DIST_LINUX_TEAM=$(DIST_LINUX)/$(TEAM)
DIST_LINUX_SINGLE=$(DIST_LINUX)/$(SINGLE)
DIST_WIN=$(DIST)/windows
DIST_WIN_TEAM=$(DIST_WIN)/$(TEAM)
DIST_WIN_SINGLE=$(DIST_WIN)/$(SINGLE)
VERSION=$(RELEASE_VERSION)
GIT_REMOTE=https://$(GIT_USERNAME):$(GIT_PASSWORD)@github.com/ZupIT/ritchie-cli
MODULE=$(shell go list -m)
DATE=$(shell date +%D_%H:%M)
BUCKET=$(shell VERSION=$(VERSION) ./.circleci/scripts/bucket.sh)
COMMONS_REPO_URL=https://commons-repo.ritchiecli.io/tree/tree.json
IS_RELEASE=$(shell echo $(VERSION) | egrep "^[0-9.]+-beta.[0-9]+")
IS_BETA=$(shell echo $(VERSION) | egrep "*.pre.*")
IS_QA=$(shell echo $(VERSION) | egrep "*qa.*")
IS_NIGHTLY=$(shell echo $(VERSION) | egrep "*.nightly.*")
IS_LEGACY=$(shell echo $(VERSION) | egrep "*.legacy.*")
GONNA_RELEASE=$(shell ./.circleci/scripts/gonna_release.sh)
NEXT_VERSION=$(shell ./.circleci/scripts/next_version.sh)

build-linux:
	mkdir -p $(DIST_LINUX_TEAM) $(DIST_LINUX_SINGLE)
	#LINUX
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE)' -o ./$(DIST_LINUX_TEAM)/$(BINARY_NAME) -v $(TEAM_CMD_PATH)
	#LINUX SINGLE
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE) -X $(MODULE)/pkg/cmd.CommonsRepoURL=$(COMMONS_REPO_URL)' -o ./$(DIST_LINUX_SINGLE)/$(BINARY_NAME) -v $(SINGLE_CMD_PATH)

build-mac:
	mkdir -p $(DIST_MAC_TEAM) $(DIST_MAC_SINGLE)
	#MAC
	GOOS=darwin GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE)' -o ./$(DIST_MAC_TEAM)/$(BINARY_NAME) -v $(TEAM_CMD_PATH)
	#MAC SINGLE
	GOOS=darwin GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE) -X $(MODULE)/pkg/cmd.CommonsRepoURL=$(COMMONS_REPO_URL)' -o ./$(DIST_MAC_SINGLE)/$(BINARY_NAME) -v $(SINGLE_CMD_PATH)

build-windows:
	mkdir -p $(DIST_WIN_TEAM) $(DIST_WIN_SINGLE)
	#WINDOWS 64
	GOOS=windows GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE)' -o ./$(DIST_WIN_TEAM)/$(BINARY_NAME).exe -v $(TEAM_CMD_PATH)
	#WINDOWS 64 SINGLE
	GOOS=windows GOARCH=amd64 $(GO_BUILD) -ldflags '-X $(MODULE)/pkg/cmd.Version=$(VERSION) -X $(MODULE)/pkg/cmd.BuildDate=$(DATE) -X $(MODULE)/pkg/cmd.CommonsRepoURL=$(COMMONS_REPO_URL)' -o ./$(DIST_WIN_SINGLE)/$(BINARY_NAME).exe -v $(SINGLE_CMD_PATH)

build: build-linux build-mac build-windows
ifneq "$(BUCKET)" ""
	echo $(BUCKET)
	aws s3 sync dist s3://$(BUCKET)/$(RELEASE_VERSION) --include "*"
ifneq "$(IS_NIGHTLY)" ""
	echo -n "$(RELEASE_VERSION)" > nightly.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "nightly.txt"
endif
ifneq "$(IS_BETA)" ""
	echo -n "$(RELEASE_VERSION)" > beta.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "beta.txt"
endif
ifneq "$(IS_RELEASE)" ""
	echo -n "$(RELEASE_VERSION)" > stable.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "stable.txt"
endif
ifneq "$(IS_QA)" ""
	echo -n "$(RELEASE_VERSION)" > stable.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "stable.txt"
endif
ifneq "$(IS_LEGACY)" ""
	echo -n "$(RELEASE_VERSION)" > stable-legacy.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "stable-legacy.txt"
endif
else
	echo "NOT GONNA PUBLISH"
endif

build-circle: build-linux build-mac build-windows

release:
	git config --global user.email "$(GIT_EMAIL)"
	git config --global user.name "$(GIT_NAME)"
	git tag -a $(RELEASE_VERSION) -m "CHANGELOG: https://github.com/ZupIT/ritchie-cli/blob/master/CHANGELOG.md"
	git push $(GIT_REMOTE) $(RELEASE_VERSION)
	gem install github_changelog_generator
	github_changelog_generator -u zupit -p ritchie-cli --token $(GIT_PASSWORD) --enhancement-labels feature,Feature --exclude-labels duplicate,question,invalid,wontfix
	git add .
	git commit --allow-empty -m "[ci skip] release"
	git push $(GIT_REMOTE) HEAD:release-$(RELEASE_VERSION)
	curl --user $(GIT_USERNAME):$(GIT_PASSWORD) -X POST https://api.github.com/repos/ZupIT/ritchie-cli/pulls -H 'Content-Type: application/json' -d '{ "title": "Release $(RELEASE_VERSION) merge", "body": "Release $(RELEASE_VERSION) merge with master", "head": "release-$(RELEASE_VERSION)", "base": "master" }'

delivery:
	@echo $(VERSION)
ifneq "$(BUCKET)" ""
	aws s3 sync dist s3://$(BUCKET)/$(RELEASE_VERSION) --include "*"
ifneq "$(IS_NIGHTLY)" ""
	echo -n "$(RELEASE_VERSION)" > nightly.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "nightly.txt"
endif
ifneq "$(IS_BETA)" ""
	echo -n "$(RELEASE_VERSION)" > beta.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "beta.txt"
endif
ifneq "$(IS_RELEASE)" ""
	echo -n "$(RELEASE_VERSION)" > stable.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "stable.txt"
endif
ifneq "$(IS_QA)" ""
	echo -n "$(RELEASE_VERSION)" > stable.txt
	aws s3 sync . s3://$(BUCKET)/ --exclude "*" --include "stable.txt"
endif
else
	echo "NOT GONNA PUBLISH"
endif

publish:
	echo "Do nothing"

clean:
	rm -rf $(DIST)
	rm -rf $(BIN)

unit-test:
	./run-tests.sh

functional-test-single:
	mkdir -p $(BIN)
	$(GO_TEST) -v -count=1 -p 1 `go list ./functional/single/... | grep -v vendor/`

functional-test-team:
	mkdir -p $(BIN)
	$(GO_TEST) -v -count=1 -p 1 `go list ./functional/team/... | grep -v vendor/`

rebase-nightly:
	git config --global user.email "$(GIT_EMAIL)"
	git config --global user.name "$(GIT_NAME)"
	git push $(GIT_REMOTE) --delete nightly | true
	git checkout -b nightly
	git reset --hard master
	git add .
	git commit --allow-empty -m "nightly"
	git push $(GIT_REMOTE) HEAD:nightly

rebase-beta:
	git config --global user.email "$(GIT_EMAIL)"
	git config --global user.name "$(GIT_NAME)"
	git push $(GIT_REMOTE) --delete beta | true
	git checkout -b beta
	git reset --hard nightly
	git add .
	git commit --allow-empty -m "beta"
	git push $(GIT_REMOTE) HEAD:beta

release-creator:
ifeq "$(GONNA_RELEASE)" "RELEASE"
	git config --global user.email "$(GIT_EMAIL)"
	git config --global user.name "$(GIT_NAME)"
	git checkout -b "release-$(NEXT_VERSION)"
	git add .
	git commit --allow-empty -m "release-$(NEXT_VERSION)"
	git push $(GIT_REMOTE) HEAD:release-$(NEXT_VERSION)
else
	echo "NOT GONNA RELEASE"
endif
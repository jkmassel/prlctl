.DEFAULT_GOAL := lint

SWIFTLINT_IMAGE=ghcr.io/realm/swiftlint:0.47.1

lint:
	docker run -it --rm -v `pwd`:`pwd` -w `pwd` $(SWIFTLINT_IMAGE) swiftlint lint --strict

lintfix:
	docker run -it --rm -v `pwd`:`pwd` -w `pwd` $(SWIFTLINT_IMAGE) swiftlint --autocorrect

lint-ci:
	docker run -v `pwd`:`pwd` -w `pwd` $(SWIFTLINT_IMAGE) swiftlint lint --strict

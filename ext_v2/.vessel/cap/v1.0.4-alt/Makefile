.PHONY: check-strict docs

check-strict:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell vessel sources) -Werror --check

docs:
	$(shell vessel bin)/mo-doc
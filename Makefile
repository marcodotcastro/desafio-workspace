.PHONY: up status down test

Volt ?= volt

up:
	@$(Volt) builder up

status:
	@$(Volt) builder status

down:
	@$(Volt) builder down

test:
	@$(Volt) builder test

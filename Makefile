RIL = 2.2.1003G
LOCALE = JAPAN
MARKET = 2.3.6

all:
	@script/meta.sh all \
		--ril-version $(RIL) \
		--gps-locale $(LOCALE) \
		--market-version $(MARKET)
clean:
	@script/meta.sh clean


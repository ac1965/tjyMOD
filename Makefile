BASEROM = update-cm-7.1.0-DesireHD-KANG_201111201027.signed.zip
KERNEL = update_ICS-AUFS_201112020947.zip
RIL = 2.2.1003G
LOCALE = JAPAN
MARKET = 2.3.6

all:
	@script/meta.sh all \
		--ril-version $(RIL) \
		--gps-locale $(LOCALE) \
		--market-version $(MARKET) \
		--baserom $(BASEROM) \
		--kernel $(KERNEL)

clean:
	@script/meta.sh clean

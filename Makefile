BASEROM = $(HOME)/android/build/update-cm-7.1.0-DesireHD-KANG_201111092233.signed.zip
KERNEL = $(HOME)/android/build/update_2.6.35-BFS-WIP-AUFS_201110311141.zip
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

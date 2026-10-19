# BGP-02 - select same scenario on FRRouting or Nokia SR Linux
# Examples: make up PLATFORM=frr ; make verify PLATFORM=srlinux
.DEFAULT_GOAL := help
PLATFORM := srlinux
VALID_PLATFORMS := frr srlinux
ifneq ($(filter $(PLATFORM),$(VALID_PLATFORMS)),$(PLATFORM))
$(error PLATFORM must be frr or srlinux)
endif
.PHONY: help preflight lint pull up deploy verify check status routes ce isp-a isp-b origin failover restore down reset frr-up srl-up frr-down srl-down
help:
	@echo 'BGP-02 | FRRouting + Nokia SR Linux'
	@echo '  make up PLATFORM=frr          FRRouting (preconfigurat automat)'
	@echo '  make up PLATFORM=srlinux      Nokia SR Linux (implicit)'
	@echo '  make verify PLATFORM=...      verifica BGP / calea activa'
	@echo '  make ce PLATFORM=...          consola CE'
	@echo '  make routes PLATFORM=...      BGP CE pentru prefixul de test'
	@echo '  make failover PLATFORM=...    simuleaza pierderea ISP-A'
	@echo '  make restore PLATFORM=srlinux  reabiliteaza ISP-A Nokia'
	@echo '  make reset PLATFORM=...       recreeaza laboratorul'
	@echo '  make down PLATFORM=...        sterge doar topologia aleasa'
	@echo '  make lint PLATFORM=...        verificare statica'
	@echo '  make frr-up / srl-up / frr-down / srl-down'
preflight lint up deploy verify check status routes ce isp-a isp-b origin failover down reset:
	@$(MAKE) -C $(PLATFORM) $@
pull:
	@if [ '$(PLATFORM)' = 'srlinux' ]; then $(MAKE) -C srlinux pull; else sudo docker pull quay.io/frrouting/frr:containerlab-10.7.1; fi
restore:
	@if [ '$(PLATFORM)' = 'srlinux' ]; then $(MAKE) -C srlinux restore; else echo 'FRR failover restores automatically; run make verify PLATFORM=frr'; fi
frr-up:
	@$(MAKE) up PLATFORM=frr
srl-up:
	@$(MAKE) up PLATFORM=srlinux
frr-down:
	@$(MAKE) down PLATFORM=frr
srl-down:
	@$(MAKE) down PLATFORM=srlinux

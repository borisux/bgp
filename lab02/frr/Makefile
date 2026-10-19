.DEFAULT_GOAL := help
.PHONY: help preflight up verify routes check check-b failover status ce isp-a isp-b origin down reset lint

help:
	@echo 'BGP-02 - Dual ISP / BGP Local Preference (FRRouting + Containerlab)'
	@echo '  make preflight  - verify safe VM and installed prerequisites'
	@echo '  make up         - deploy all 4 routers and validate ISP-A is preferred'
	@echo '  make check      - check baseline: ISP-A is preferred'
	@echo '  make check-b    - check after exercise: ISP-B is preferred'
	@echo '  make failover   - temporarily shut down ISP-A BGP on CE, check backup, restore'
	@echo '  make status     - inspect this lab'
	@echo '  make ce         - enter CE vtysh'
	@echo '  make isp-a      - enter ISP-A vtysh'
	@echo '  make isp-b      - enter ISP-B vtysh'
	@echo '  make origin     - enter ORIGIN vtysh'
	@echo '  make reset      - destroy/redeploy this lab from versioned configs'
	@echo '  make down       - destroy only BGP-02 resources'
	@echo '  make lint       - bash/YAML/topology/static config checks'

preflight:
	bash scripts/preflight.sh

up: preflight
	sudo containerlab deploy -t bgp02.clab.yml
	bash check.sh --wait

check:
	bash check.sh

check-b:
	bash check.sh --expect-b

failover:
	bash scripts/failover.sh

status:
	sudo containerlab inspect -t bgp02.clab.yml

ce:
	sudo docker exec -it clab-bgp02-ce vtysh

isp-a:
	sudo docker exec -it clab-bgp02-isp-a vtysh

isp-b:
	sudo docker exec -it clab-bgp02-isp-b vtysh

origin:
	sudo docker exec -it clab-bgp02-origin vtysh

down:
	sudo containerlab destroy -t bgp02.clab.yml --cleanup

reset: down up

lint:
	@for file in check.sh scripts/*.sh; do bash -n "$$file" || exit; done
	python3 scripts/static_lint.py

verify: check

routes:
	sudo docker exec clab-bgp02-ce vtysh -c 'show bgp ipv4 unicast 203.0.113.0/24'

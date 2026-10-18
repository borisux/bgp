#!/usr/bin/env python3
"""Static checks only; no containers are started. Requires python3-yaml."""
from pathlib import Path
import ipaddress
import re
import yaml

root = Path(__file__).resolve().parent.parent
lab = yaml.safe_load((root / 'bgp01.clab.yml').read_text())
assert lab['name'] == 'bgp01', 'Unexpected lab name'
nodes = lab['topology']['nodes']
assert set(nodes) == {'r1', 'r2'}, 'Expected r1 and r2'
assert lab['topology']['links'] == [{'endpoints': ['r1:eth1', 'r2:eth1']}]
assert lab['topology']['kinds']['frr']['daemons'] == ['bgpd']
assert lab['topology']['kinds']['frr']['image'].startswith('quay.io/frrouting/frr:containerlab-')

expected = {
    'r1': ('65001', '65002', '10.0.12.1/30', '10.0.12.2', '192.0.2.1/32'),
    'r2': ('65002', '65001', '10.0.12.2/30', '10.0.12.1', '198.51.100.1/32'),
}
for node, (own_as, peer_as, address, peer, loopback) in expected.items():
    data = nodes[node]
    assert data['kind'] == 'frr'
    assert data['enforce-startup-config'] is True
    path = (root / data['startup-config']).resolve()
    assert path.is_relative_to(root), 'Startup config points outside repo'
    conf = path.read_text()
    for cmd in (
        f'ip address {address}',
        f'ip address {loopback}',
        f'router bgp {own_as}',
        f'neighbor {peer} remote-as {peer_as}',
        f'neighbor {peer} activate',
        f'network {loopback}',
        'no bgp ebgp-requires-policy',
    ):
        assert cmd in conf, f'{node} missing: {cmd}'
    assert ipaddress.ip_interface(address).network == ipaddress.ip_network('10.0.12.0/30')
    assert re.search(rf'^interface eth1\n ip address {re.escape(address)}', conf, re.M)
print('PASS: YAML + FRR static configuration consistency checks.')

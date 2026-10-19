#!/usr/bin/env python3
"""Strict structural sanity checks. Does not prove BGP runtime behavior."""
from pathlib import Path
import ipaddress
import sys
try:
 import yaml
except ImportError:
 sys.exit('Install python3-yaml in the VM to run make lint')
root=Path(__file__).resolve().parent.parent
lab=yaml.safe_load((root/'bgp02.clab.yml').read_text())
assert lab['name']=='bgp02'
nodes=lab['topology']['nodes']
assert set(nodes)=={'ce','isp-a','isp-b','origin'}
expected_links={frozenset(x) for x in [
 ['ce:eth1','isp-a:eth1'],['ce:eth2','isp-b:eth1'],
 ['isp-a:eth2','origin:eth1'],['isp-b:eth2','origin:eth2']]}
actual_links={frozenset(l['endpoints']) for l in lab['topology']['links']}
assert actual_links==expected_links
for n in nodes:
 nd=nodes[n]
 assert nd['kind']=='frr' and nd['enforce-startup-config'] is True
 assert (root/nd['startup-config']).is_file()
conf={n:(root/n/'frr.conf').read_text() for n in nodes}
assert 'router bgp 65000' in conf['ce']
assert 'router bgp 65010' in conf['isp-a']
assert 'router bgp 65020' in conf['isp-b']
assert 'router bgp 65030' in conf['origin']
assert 'set local-preference 200' in conf['ce']
assert 'set local-preference 100' in conf['ce']
assert 'neighbor 10.0.12.2 route-map FROM-ISP-A in' in conf['ce']
assert 'neighbor 10.0.13.2 route-map FROM-ISP-B in' in conf['ce']
assert 'network 203.0.113.0/24' in conf['origin']
assert 'network 192.0.2.1/32' in conf['ce']
for name, peers in {
 'ce':['10.0.12.2','10.0.13.2'],
 'isp-a':['10.0.12.1','10.0.24.2'],
 'isp-b':['10.0.13.1','10.0.34.2'],
 'origin':['10.0.24.1','10.0.34.1']
}.items():
 for peer in peers:
  assert f'neighbor {peer} remote-as ' in conf[name], (name,peer)
  assert f'neighbor {peer} activate' in conf[name], (name,peer)
addrs={n:[] for n in nodes}
for n,s in conf.items():
 for line in s.splitlines():
  if line.strip().startswith('ip address '):
   addrs[n].append(ipaddress.ip_interface(line.strip().split()[-1]))
for side_a, side_b in [('ce','isp-a'),('ce','isp-b'),('isp-a','origin'),('isp-b','origin')]:
 assert any(x.network==y.network and x.ip!=y.ip and x.network.prefixlen==30
            for x in addrs[side_a] for y in addrs[side_b]),(side_a,side_b)
print('PASS: valid YAML, four nodes and links, correct ASNs/peers/policies/interfaces.')

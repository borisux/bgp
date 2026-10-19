#!/usr/bin/env python3
"""Offline lightweight, no pip dependencies; NOT a live SR Linux syntax validator."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
topology=(root/'bgp02.clab.yml').read_text()
assert 'kind: nokia_srlinux' in topology
assert 'image: ghcr.io/nokia/srlinux:25.10.2' in topology
assert topology.count('endpoints:') == 4
nodes=('ce','isp-a','isp-b','origin')
for node in nodes:
    cfg=root/'configs'/f'{node}.cli'
    assert cfg.exists() and f'configs/{node}.cli' in topology
    body=cfg.read_text()
    assert 'protocols bgp autonomous-system ' in body
    assert 'protocols bgp afi-safi ipv4-unicast' in body
    assert re.search(r'neighbor 10\.0\.\d+\.\d+ peer-as',body)
    assert all(line.startswith(('set /','#')) or not line.strip() for line in body.splitlines())
print('PASS: 4 noduri SR Linux, 4 legaturi, 4 fisiere CLI, verificari structurale OK')
print('INFO: este un lint static, nu inlocuieste deploy + verify pe Containerlab')

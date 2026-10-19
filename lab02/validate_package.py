#!/usr/bin/env python3
from pathlib import Path
import ast
import subprocess
import sys
root=Path(__file__).resolve().parent
expected=['README.md','Makefile','docs/topology.svg','docs/topology.png','docs/topology.dot','docs/topology.mmd','manual/FRROUTING.md','manual/NOKIA-SRLINUX.md','frr/Makefile','frr/bgp02.clab.yml','srlinux/Makefile','srlinux/bgp02.clab.yml']
expected += [f'frr/{node}/frr.conf' for node in ['ce','isp-a','isp-b','origin']]
expected += [f'srlinux/configs/{node}.cli' for node in ['ce','isp-a','isp-b','origin']]
for path in expected:
    assert (root/path).is_file(), f'missing {path}'
for p in root.rglob('*.py'):
    ast.parse(p.read_text(),filename=str(p))
for p in root.rglob('*.sh'):
    subprocess.run(['bash','-n',str(p)],check=True)
assert (root/'README.md').read_text().count('### FRR ') == 4
assert sum(line.startswith(('### Nokia CE','### Nokia ISP-A','### Nokia ISP-B','### Nokia ORIGIN')) for line in (root/'README.md').read_text().splitlines()) == 4
try:
    import yaml
    for platform in ('frr','srlinux'):
        data=yaml.safe_load((root/platform/'bgp02.clab.yml').read_text())
        assert len(data['topology']['nodes'])==4
        assert len(data['topology']['links'])==4
except ImportError:
    print('PyYAML absent: YAML semantic parsing skipped')
print('PASS: documentatia, manualele, topologiile, BGP si scripturile prezente')

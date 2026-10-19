#!/usr/bin/env python3
"""Control CE's ISP-A data interface using SR Linux JSON-RPC (no container restart)."""
import argparse
import sys
from client import cli

parser=argparse.ArgumentParser()
parser.add_argument('state',choices=['enable','disable'])
args=parser.parse_args()
commands=['enter candidate',f'set / interface ethernet-1/1 admin-state {args.state}','commit now']
try:
    output=cli('ce',commands)
    state_output = cli('ce',['info from running interface ethernet-1/1 admin-state'])
    if f'admin-state {args.state}' not in state_output:
        raise RuntimeError(f'Configuratia nu s-a aplicat: {state_output}')
    print(f'CE ethernet-1/1 admin-state = {args.state}. {output.strip()}')
except Exception as exc:
    print(f'Eroare: {exc}',file=sys.stderr)
    sys.exit(1)

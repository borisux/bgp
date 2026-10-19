#!/usr/bin/env python3
"""Wait for eBGP and enforce the expected best-path decision in CE."""
import argparse
import re
import sys
import time
from client import cli

p=argparse.ArgumentParser()
p.add_argument('--mode',choices=['primary','backup'],default='primary')
p.add_argument('--wait',type=int,default=180)
args=p.parse_args()
peers={'ce': ['10.0.13.2'] + (['10.0.12.2'] if args.mode=='primary' else []),
       'isp-a':['10.0.24.2'] if args.mode=='primary' else [],
       'isp-b':['10.0.34.2'],
       'origin':['10.0.34.1'] + (['10.0.24.1'] if args.mode=='primary' else [])}
expected_peer='10.0.12.2' if args.mode=='primary' else '10.0.13.2'
expected_pref='200' if args.mode=='primary' else '100'
last_error=''

# A specific-prefix view has a Path N: <Best,Valid,Used> entry on SR Linux 25.10.
def selected_path(text):
    # split records by 'Path N:' instead of parsing a version-specific table shape
    records=re.split(r'(?=\bPath\s+\d+\s*:)',text)
    for record in records:
        if re.search(r'\bPath\s+\d+\s*:\s*<[^>]*\bBest\b',record,re.I):
            return record
    return ''

def is_up(node,peer):
    text=cli(node,[f'show network-instance default protocols bgp neighbor {peer} detail'])
    return bool(re.search(r'session-state\s+is\s+established',text,re.I))

end=time.monotonic()+args.wait
while True:
    try:
        failed=[f'{node}->{peer}' for node,nbrs in peers.items() for peer in nbrs if not is_up(node,peer)]
        if failed:
            raise RuntimeError('Sesiuni neestablished: '+', '.join(failed))
        if args.mode=='backup' and is_up('ce','10.0.12.2'):
            raise RuntimeError('CE->ISP-A inca este Established; failover incomplet')
        view=cli('ce',['show network-instance default protocols bgp routes ipv4 prefix 203.0.113.0/24'])
        best=selected_path(view)
        if not best:
            raise RuntimeError('CE nu arata un Best path pentru 203.0.113.0/24\n'+view)
        if not re.search(r'Route source\s*:\s*neighbor\s+'+re.escape(expected_peer)+r'\b',best,re.I):
            raise RuntimeError('Best path nu este prin '+expected_peer+'\n'+view)
        if not re.search(r'LocalPref\s+is\s+'+expected_pref+r'\b',best,re.I):
            raise RuntimeError('LOCAL_PREF nu este '+expected_pref+'\n'+view)
        print('PASS: sesiuni BGP asteptate sunt established')
        print(f'PASS: CE prefera {expected_peer} cu LOCAL_PREF {expected_pref}')
        print('PASS: ruta 203.0.113.0/24 este activa in BGP CE')
        break
    except Exception as error:
        last_error=str(error)
        if time.monotonic()>=end:
            print('FAIL: Testele au expirat:',last_error,file=sys.stderr)
            sys.exit(1)
        time.sleep(5)

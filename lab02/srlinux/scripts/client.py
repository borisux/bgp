#!/usr/bin/env python3
"""Minimal, dependency-free SR Linux management client over Containerlab's JSON-RPC."""
import base64
import json
import os
import subprocess
import urllib.error
import urllib.request

LAB = 'bgp02-srl'

def node_ip(node):
    container = f'clab-{LAB}-{node}'
    raw = subprocess.check_output(['docker', 'inspect', container], text=True)
    data = json.loads(raw)[0]
    networks = data['NetworkSettings']['Networks']
    if 'clab' in networks and networks['clab'].get('IPAddress'):
        return networks['clab']['IPAddress']
    for values in networks.values():
        if values.get('IPAddress'):
            return values['IPAddress']
    raise RuntimeError(f'Nu gasesc adresa IPv4 a containerului {container}')

def cli(node, commands):
    """Return joined output; throw on HTTP or JSON-RPC failures."""
    host = node_ip(node)
    payload = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'cli',
                          'params': {'commands': commands, 'output-format': 'text'}}).encode()
    user = os.environ.get('SRL_USER', 'admin')
    password = os.environ.get('SRL_PASSWORD', 'NokiaSrl1!')
    token = base64.b64encode(f'{user}:{password}'.encode()).decode('ascii')
    request = urllib.request.Request(f'http://{host}/jsonrpc', data=payload,
        headers={'Content-Type':'application/json','Authorization':f'Basic {token}'}, method='POST')
    with urllib.request.urlopen(request,timeout=12) as response:
        reply=json.load(response)
    if reply.get('error'):
        raise RuntimeError(f'JSON-RPC {node}: {reply["error"]}')
    result=reply.get('result')
    if not isinstance(result,list) or len(result)!=len(commands):
        raise RuntimeError(f'Unexpected JSON-RPC response from {node}: {reply!r}')
    messages=[]
    for item in result:
        if isinstance(item,dict):
            if item.get('error'):
                raise RuntimeError(f'SR Linux CLI {node}: {item["error"]}')
            messages.append(str(item.get('text',item)))
        else:
            messages.append(str(item))
    return '\n'.join(messages)

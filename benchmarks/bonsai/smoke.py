#!/usr/bin/env python3
"""Check fixed answers with thinking enabled on a temporary local server."""
import argparse
import json
from pathlib import Path
import socket
import subprocess
import time
import urllib.request

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--runtime', required=True, type=Path)
p.add_argument('--model', required=True, type=Path)
p.add_argument('--output', required=True, type=Path)
p.add_argument('--max-tokens', type=int, default=512, help='Completion budget, including reasoning')
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)
# Refuse an occupied port; never interact with an existing user's server.
with socket.socket() as probe:
    probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    probe.bind(('127.0.0.1', 18082))
base = 'http://127.0.0.1:18082'
command = [str(a.runtime / 'bonsai-server'), '-m', str(a.model),
           '-c', '4096', '-ngl', '99', '-b', '256', '-ub', '128',
           '-fa', 'on', '-np', '1', '--no-mmproj', '--host', '127.0.0.1',
           '--port', '18082', '--chat-template-kwargs',
           '{"enable_thinking":true,"reasoning_effort":"medium"}']
tests = [
    ('arithmetic', 'Compute 17 * 19. Reply with only the integer.', '323'),
    ('python', 'What does print(sum(x*x for x in range(5))) output? Reply with only the integer.', '30'),
    ('filter', 'In Python, what does [x for x in [0,1,2,3,4] if x % 2] evaluate to? Reply with only the list literal.', '[1,3]'),
]
results = []
with (a.output / 'server.log').open('w') as log:
    proc = subprocess.Popen(command, stdout=log, stderr=log)
    try:
        for _ in range(300):
            if proc.poll() is not None:
                raise RuntimeError('Server exited before becoming ready; see server.log')
            try:
                with urllib.request.urlopen(base + '/health', timeout=1) as response:
                    if response.status == 200:
                        break
            except (OSError, urllib.error.HTTPError):
                time.sleep(.2)
        else:
            raise TimeoutError('Server did not become ready')
        for name, prompt, expected in tests:
            body = {'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': 0, 'seed': 123, 'max_tokens': a.max_tokens,
                    'chat_template_kwargs': {'enable_thinking': True, 'reasoning_effort': 'medium'}}
            request = urllib.request.Request(base + '/v1/chat/completions',
                data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
            with urllib.request.urlopen(request, timeout=120) as response:
                data = json.load(response)
            (a.output / f'{name}.json').write_text(json.dumps(data, indent=2))
            answer = data['choices'][0]['message'].get('content') or ''
            passed = ''.join(answer.split()) == expected
            row = {'name': name, 'answer': answer, 'expected': expected,
                   'passed': passed, 'finish_reason': data['choices'][0]['finish_reason']}
            results.append(row)
            print(json.dumps(row), flush=True)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
(a.output / 'summary.json').write_text(json.dumps(results, indent=2))
if not all(r['passed'] for r in results):
    raise SystemExit(1)

#!/usr/bin/env python3
"""Compare a GPU target with optional CPU drafting; never changes launchers."""
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
p.add_argument('--draft', type=Path)
p.add_argument('--mode', choices=['none', 'draft-simple', 'ngram-simple'], default='none')
p.add_argument('--output', required=True, type=Path)
p.add_argument('--draft-tokens', type=int, default=3)
p.add_argument('--cases', nargs='+', choices=['arithmetic', 'code', 'explanation'], default=['arithmetic', 'code', 'explanation'])
p.add_argument('--max-tokens', type=int, default=384)
a = p.parse_args()
if a.mode == 'draft-simple' and not a.draft:
    p.error('draft-simple requires --draft')
a.output.mkdir(parents=True, exist_ok=True)
with socket.socket() as probe:
    probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    probe.bind(('127.0.0.1', 18083))
base = 'http://127.0.0.1:18083'
command = [str(a.runtime / 'bonsai-server'), '-m', str(a.model),
           '-c', '4096', '-ngl', '99', '-b', '256', '-ub', '128', '-t', '8',
           '-fa', 'on', '-np', '1', '--no-mmproj', '--host', '127.0.0.1',
           '--port', '18083', '--metrics', '--spec-type', a.mode,
           '--chat-template-kwargs', '{"enable_thinking":true,"reasoning_effort":"medium"}']
if a.mode == 'draft-simple':
    command += ['--spec-draft-model', str(a.draft), '--spec-draft-ngl', '0',
                '--spec-draft-device', 'none', '--spec-draft-threads', '8',
                '--spec-draft-n-max', str(a.draft_tokens)]
tests = [
    ('arithmetic', 'Compute 17 * 19. Reply with only the integer.', 512),
    ('code', 'Write a Python function that merges two sorted lists without sorting again. Include a short explanation and three tests.', 384),
    ('explanation', 'Explain why a hash table can have collisions and how separate chaining resolves them. Give a concrete example.', 384),
]
tests = [(name, prompt, min(limit, a.max_tokens)) for name, prompt, limit in tests if name in a.cases]
(a.output / 'command.json').write_text(json.dumps(command, indent=2))
results = []
with (a.output / 'server.log').open('w') as log:
    proc = subprocess.Popen(command, stdout=log, stderr=log)
    try:
        for _ in range(1200):
            if proc.poll() is not None:
                raise RuntimeError('Server exited; see server.log')
            try:
                with urllib.request.urlopen(base + '/health', timeout=1) as r:
                    if r.status == 200:
                        break
            except OSError:
                time.sleep(.2)
        else:
            raise TimeoutError('Server startup timed out')
        # Same warm-up for every configuration; request caching is disabled.
        for name, prompt, limit in [('warmup', 'Hello.', 32)] + tests:
            body = {'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': 0, 'seed': 123, 'max_tokens': limit,
                    'cache_prompt': False,
                    'chat_template_kwargs': {'enable_thinking': True, 'reasoning_effort': 'medium'}}
            request = urllib.request.Request(base + '/v1/chat/completions',
                data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
            start = time.monotonic()
            with urllib.request.urlopen(request, timeout=300) as r:
                data = json.load(r)
            elapsed = time.monotonic() - start
            (a.output / f'{name}.json').write_text(json.dumps(data, indent=2))
            row = {'name': name, 'elapsed_seconds': elapsed, 'timings': data.get('timings'),
                   'usage': data.get('usage'), 'finish_reason': data['choices'][0]['finish_reason']}
            results.append(row)
            (a.output / 'summary.json').write_text(json.dumps(results, indent=2))
            print(json.dumps(row), flush=True)
        with urllib.request.urlopen(base + '/metrics', timeout=5) as r:
            (a.output / 'metrics.txt').write_bytes(r.read())
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
(a.output / 'summary.json').write_text(json.dumps(results, indent=2))

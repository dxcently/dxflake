#!/usr/bin/env python3
"""Alternate baseline and candidate decode measurements; never run them together."""
import argparse
import json
from pathlib import Path
import subprocess

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--baseline', required=True, type=Path, help='Baseline runtime bin directory')
p.add_argument('--candidate', required=True, type=Path, help='Candidate runtime bin directory')
p.add_argument('--model', required=True, type=Path)
p.add_argument('--output', required=True, type=Path)
p.add_argument('--tokens', type=int, default=256)
p.add_argument('--rounds', type=int, default=2)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)
summary = []
for round_number in range(a.rounds):
    # Reverse order on the next round to reduce ordering/temperature bias.
    order = [('baseline', a.baseline), ('candidate', a.candidate)]
    if round_number % 2:
        order.reverse()
    for label, runtime in order:
        name = f'{round_number + 1}-{label}'
        command = [str(runtime / 'bonsai-bench'), '-m', str(a.model),
                   '-ngl', '99', '-p', '0', '-n', str(a.tokens),
                   '-b', '256', '-ub', '128', '-t', '8', '-fa', 'on',
                   '-r', '1', '-o', 'json']
        (a.output / f'{name}.command.json').write_text(json.dumps(command, indent=2))
        with (a.output / f'{name}.json').open('w') as stdout, (a.output / f'{name}.log').open('w') as stderr:
            subprocess.run(command, stdout=stdout, stderr=stderr, check=True)
        result = json.loads((a.output / f'{name}.json').read_text())
        if len(result) != 1 or result[0]['n_gen'] != a.tokens:
            raise RuntimeError('Unexpected benchmark result')
        row = {'round': round_number + 1, 'runtime': label,
               'tokens_per_second': result[0]['avg_ts']}
        summary.append(row)
        (a.output / 'summary.json').write_text(json.dumps(summary, indent=2))
        print(json.dumps(row), flush=True)

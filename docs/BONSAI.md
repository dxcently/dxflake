# Bonsai on Osaka

The `bonsai` dendrite installs a separate PrismML llama.cpp runtime with HIP
support. Only Osaka selects it. It exposes `bonsai-server`, `bonsai-cli`, and
`bonsai-bench`; the existing Ollama and llama.cpp installations remain available.
It starts no service and does not change GPU drivers.

## Model

This trial uses the text-only PTQ1_0 packing of **Ternary Bonsai 2 27B**:

- Repository: `prism-ml/Ternary-Bonsai-2-27B-gguf`
- Revision: `b072e1d3b35a0a630cece372c2127528e0994386`
- File: `Ternary-Bonsai-2-27B-PTQ1_0.gguf`
- Size: 5,946,648,928 bytes (5.54 GiB)
- SHA-256: `53107f530aa52eb00912263ab1ee29bd199261c87cd7b4ad4ca1318c1fe33ee3`

The verified copy is saved at
`~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0.gguf`.
Weights are not committed to the flake. The tested runtime is retained by the
Nix GC root `~/.local/share/bonsai/runtime`. The optimized build is retained
separately at `~/.local/share/bonsai/runtime-optimized`, and both chat launchers
now use it. Both work before a system rebuild and survive garbage collection.

The matching PrismML runtime is required. Stock llama.cpp recognizing the GGUF
container does not mean it implements Bonsai 2's activation transforms.

## Run now

Interactive terminal chat, using the saved runtime and verified model:

```sh
~/.local/share/bonsai/chat
```

This machine-local launcher uses a 4,096-token context, full GPU offload, batch size 256,
physical batch size 128, Flash Attention, and medium reasoning. Extra CLI arguments can be appended.

For an API client, run this in a terminal and stop it with Ctrl-C:

```sh
~/.local/share/bonsai/runtime-optimized/bin/bonsai-server \
  -m ~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0.gguf \
  --host 127.0.0.1 --port 18081 --cors-origins localhost \
  -c 4096 -ngl 99 -b 256 -ub 128 -np 1 -fa on --no-mmproj \
  --chat-template-kwargs '{"enable_thinking":true,"reasoning_effort":"medium"}'
```

Use `http://127.0.0.1:18081/v1` as the client's OpenAI-compatible base URL.
This minimal build has no bundled browser UI; `/` returns 404. The chat endpoint
is `/v1/chat/completions`. Both launchers retain medium reasoning. Disabling
reasoning gave an incorrect answer in one earlier check, and reducing reasoning
is not part of the throughput tuning. Allow enough output tokens for both
reasoning and the final answer when using an API client.

Osaka has 8 GiB of GPU memory shared with its desktop. Model-file size excludes
context state, work buffers, and desktop allocations. Start with the 4,096-token
context and small batches above; check actual memory before increasing them.
Only run one Bonsai model process at a time on this card.

After your normal Osaka rebuild, the three `bonsai-*` binaries are on PATH.
To rebuild only this package from the repository root:

```sh
nix build --impure --expr '
  let flake = builtins.getFlake ("path:" + toString ./.);
  in flake.nixosConfigurations.osaka.pkgs.callPackage ./pkgs/bonsai { }
' --max-jobs 1 --out-link /tmp/bonsai-runtime
```

## Measured on Osaka, 2026-09-28

- Source: PrismML llama.cpp `9a9394a895b96003ca842a6041cb28ac49a108f7`
  (`prism-b10709-9a9394a`), compiled with HIP for `gfx1102`.
- Native ROCm device detection: **AMD Radeon RX 7600**. No gfx override was
  needed for this build; that does not change Ollama's separate configuration.
- **65/65 layers offloaded to the GPU**, with a 265 MiB CPU-mapped model buffer
  also reported by the loader.
- Reported GPU buffers in the CLI test: model 5,395 MiB, KV 256 MiB, recurrent
  state 150 MiB, compute 20 MiB. Total device usage sampled during the server
  trial was about 7.5 GiB, including desktop and driver allocations.
- API checks with a concise system prompt returned `323` for `17 * 19` and
  `30` for `sum(x*x for x in range(5))`. A separate nonthinking CLI check with
  a short output budget incorrectly returned `10` for the Python question.
  Medium reasoning returned `30` in both API and saved-launcher checks; the
  launcher's final smoke test measured 13.9 generation tokens/second.
  These small checks do not establish broader coding quality.
- A bounded 256-token generation measured **14.09 tokens/second** in the
  server's decode timing; the request took about 19.8 seconds end to end
  (approximately 13 output tokens/second including prompt processing).
  This is a short local smoke benchmark, not a coding-quality evaluation or a
  guarantee for longer prompts.
- The package built, Osaka's full system derivation evaluated, and inventory
  selected Bonsai only on Osaka. Selection tests: 41 passed; templates: 28 passed.
- Temporary test servers were stopped. No NixOS switch was performed.

Raw trial logs are in `/tmp/bonsai-trial/` for this session, including
`cli.log`, `server.log`, `final-smoke.jsonl`, `final-server.log`, and
`chat-final.out`.

## Upstream references

- [Runtime backend support](https://github.com/PrismML-Eng/Bonsai-demo/blob/main/BACKEND-SUPPORT.md)
- [Model formats](https://github.com/PrismML-Eng/Bonsai-demo/blob/main/MODEL-FORMATS.md)
- [Pinned model files](https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/tree/b072e1d3b35a0a630cece372c2127528e0994386)

## Throughput tuning, 2026-09-28

Stock PTQ1_0 model, native HIP, full GPU offload. `bonsai-bench` measured
128-token prompt processing and 64-token generation separately, with warmup;
the thread sweep used two repetitions, other rows three. This short synthetic
benchmark does not include model loading or chat reasoning lengths.

| Configuration | Prompt tokens/s | Generation tokens/s |
| --- | ---: | ---: |
| b128 / ub64, FA on, 2 CPU threads | 72.19 | 13.67 |
| b128 / ub64, FA on, 8 CPU threads | 72.00 | 13.87 |
| b128 / ub64, FA on, 16 CPU threads | 72.10 | 13.64 |
| b128 / ub64, FA off, 8 CPU threads | 72.40 | 13.61 |
| b256 / ub128, FA on, 8 CPU threads | 122.90 | 13.60 |
| b128 / ub64, FA on, 8 threads, optional graph optimization | 71.57 | 13.42 |

The larger physical batch improves prompt processing by about 71% in this test;
none of these settings establishes a meaningful generation-speed improvement.
The optional `GGML_CUDA_GRAPH_OPT=1` experiment was not retained. Ordinary HIP
graphs and native `gfx1102` compilation were already enabled in the runtime.
Reasoning remains enabled at medium effort. Logs: `/tmp/bonsai-speed/`.

## Abliterated trial

The separate launcher keeps medium reasoning enabled:

```sh
~/.local/share/bonsai/chat-abliterated
```

- Repository: [Override-6/Ternary-Bonsai-2-27B-abliterated-gguf](https://huggingface.co/Override-6/Ternary-Bonsai-2-27B-abliterated-gguf/tree/44c04249654a3956f1cd0cfcbf4553257bf9f4f7)
- Revision: `44c04249654a3956f1cd0cfcbf4553257bf9f4f7`
- File: `Ternary-Bonsai-2-27B-PTQ1_0-abliterated.gguf`
- Size: 5,946,648,928 bytes
- Verified SHA-256: `0b3106548351a309b080951705cf978bf3d49288df127d8f99e39d7af47378ed`
- Saved under `~/.local/share/bonsai/models/` alongside the original model.

Uses the same pinned ROCm runtime and 4,096-token context, with full GPU offload
requested, b256/ub128, Flash Attention on, and medium reasoning. The original
`chat` command still selects the original model. Run one at a time.

The arithmetic check returned `323` at 13.7 generation tokens/second. The Python
sum check returned `30` at 14.1 generation tokens/second. These two smoke tests
verify basic operation, not broad capability or the author's behavioral claims.
Logs: `/tmp/bonsai-abliterated/`.

This variant was selected because its author reports thinking-mode evaluation.
The initially considered BoldingBuilds variant reports reasoning-loop issues in
its [model card](https://huggingface.co/BoldingBuilds/Ternary-Bonsai-2-27B-Abliterated-PTQ1_0-GGUF),
so it was not installed. Abliteration itself did not establish a speed gain.

## Sustained load and GPU profile, 2026-09-28

Tested the Override-6 abliterated PTQ1_0 with the existing runtime, full GPU
offload, b256/ub128, Flash Attention, and eight CPU threads. Three 512-token
synthetic generation runs measured **14.1457, 14.1641, and 14.1918 tokens/s**
(mean 14.1672). This measures decode throughput; the chat launchers still use
medium reasoning and were not changed by this test.

One-second telemetry samples during steady load (after the first ten seconds,
GPU utilization at least 95%) showed:

| Measurement | Observed range |
| --- | --- |
| GPU utilization | 98–100% |
| GPU core clock | 2,503–2,514 MHz |
| GPU package power | 144–145 W |
| Configured/default/maximum exposed power cap | 145 W |
| Edge temperature | 68–69 °C |
| Junction temperature | 93–95 °C |
| Memory temperature | 74–76 °C |
| Total device VRAM used | 6.96–7.15 GiB |

There was no sustained clock or throughput decline in this roughly two-minute
run. Power draw was close to the configured cap; these observations alone do
not measure how much speed a different power limit would buy. Hardware power,
clock, and fan settings were not changed.

A separate 64-token trace with ROCm `rocprofiler-sdk` 7.2.3 captured 125,495
kernel dispatches. The three dominant `mul_mat_vec_q` specializations for
`GGML_TYPE_PTQ1_0` accounted for **88.5% of summed traced GPU kernel duration**.
This percentage includes initialization/warmup in the traced process and is
not a percentage of end-to-end application time. Profiler timings are not used
as the uninstrumented speed result above.

The pinned source's `ggml/src/ggml-cuda/vecdotq.cuh` has separate implementations:
HIP uses scalar trit decoding and accumulation, while the non-HIP path uses
packed-byte operations and `dp4a`. This makes an AMD-specific packed dot-product
implementation a concrete next experiment. A source patch would still require
arithmetic equivalence checks, output-quality checks, and repeat benchmarks;
the trace does not promise a particular speedup.

Raw command, telemetry, benchmark, CSV trace, and aggregated kernel results:
`/tmp/bonsai-profile/`. No persistent server or system switch was introduced.

## Packed HIP kernel installed, 2026-09-29

Both existing chat launchers now select the tested packed-v2 runtime, with
medium reasoning, the same weights, full GPU offload, 4,096-token context,
b256/ub128, eight CPU threads, and Flash Attention. The patch changes HIP
PTQ1_0 dot products using AMD byte-permute and packed signed-dot instructions.
It does not change the model format, weights, or reasoning effort.

| Model | Baseline, 256-token runs | Packed-v2 | Gain |
| --- | ---: | ---: | ---: |
| Stock PTQ1_0 | 14.08 tok/s | 26.06 tok/s | 85.1% |
| Override-6 abliterated PTQ1_0 | 14.08 tok/s | 26.02 tok/s | 84.8% |

Each row averages two runs per binary, alternating execution order. A separate
three-run, 512-token sustained test of the abliterated model measured 25.68,
25.08, and 25.35 tok/s (mean **25.37**). The earlier baseline sustained test
averaged 14.17 tok/s. The 30–40 tok/s stretch target has not been reached.

The original and both candidate kernels passed 65,537 bit-exact GPU/CPU checks;
an intentionally broken lookup was rejected. Final stock and abliterated chat
checks each passed arithmetic, Python sum, and Python filtering with medium
reasoning. These are numerical and regression checks, not broad model-quality
evaluations. Sustained optimized junction temperature reached 95 °C and power
remained at 144–145 W; no hardware power or clock settings were changed.

The original runtime remains a rollback option:

```sh
BONSAI_RUNTIME="$HOME/.local/share/bonsai/runtime" \
  ~/.local/share/bonsai/chat-abliterated
```

The same override works with `chat`. `BONSAI_MODEL` still selects a different
model file. No NixOS switch was performed. The system dendrite's package remains
the baseline; the machine-local chat launchers select the optimized GC root.
`pkgs/bonsai/experimental.nix` reproducibly builds the optimized package.

Build/test instructions: [benchmarks/bonsai/README.md](../benchmarks/bonsai/README.md).
Saved measurements are under `benchmarks/bonsai/results/`;
raw logs are in `/tmp/bonsai-ab-v2-*`, `/tmp/bonsai-smoke-v2-*`, and
`/tmp/bonsai-profile-packed-v2/`. The temporary test servers have been stopped.

## Remaining headroom and smaller-model trial, 2026-09-29

A fresh 64-token ROCm trace of packed-v2 still puts **78.82% of summed GPU
kernel duration** in the PTQ1_0 matrix-vector kernels (previously 88.5%).
This identifies where further same-model optimization should be measured;
it does not establish the hardware ceiling or promise another speedup.
The trace includes startup/warmup and is not end-to-end latency.
See `benchmarks/bonsai/results/packed-v2-profile.json`.

The smaller-model comparison uses Qwen3.5 4B and 9B Q4_K_M text GGUFs from
[Unsloth 4B](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF) and
[Unsloth 9B](https://huggingface.co/unsloth/Qwen3.5-9B-GGUF).
Their embedded templates support `enable_thinking` but do not consume
`reasoning_effort`; these trials enable thinking and do not claim a medium
effort setting. Using a smaller model changes capability even when thinking
is enabled. Three basic answer checks cannot establish reasoning parity.
The PTQ1_0 patch does not accelerate their Q4_K weights; these use the other
kernels in the same ROCm runtime.

| Model | Quantization | Decode, 256 tokens | Prompt processing, 128 tokens |
| --- | --- | ---: | ---: |
| Qwen3.5 4B | Q4_K_M | **53.55 tok/s** | 1,144.91 tok/s |
| Qwen3.5 9B | Q4_K_M | **35.71 tok/s** | 838.95 tok/s |
| Bonsai 27B abliterated | PTQ1_0, packed-v2 | **26.02 tok/s** | Not remeasured in this comparison |

Qwen numbers average two repetitions each on the RX 7600, using full GPU
offload, b256/ub128, eight CPU threads, Flash Attention and the packed-v2
runtime. Decode and prompt processing are separate synthetic benchmark tests;
they do not measure time to a finished answer or long-context speed. Bonsai's
row is the earlier two-run measurement on the same runtime and hardware.
Raw JSONs are `benchmarks/bonsai/results/qwen35-{4,9}b-q4km.json`.

Separate machine-local text chat launchers (thinking enabled, 4,096 context):

```sh
~/.local/share/bonsai/chat-qwen9b
~/.local/share/bonsai/chat-qwen4b
```

Existing `chat` and `chat-abliterated` defaults are unchanged. These Qwen
models are standard releases, not abliterated variants. Only the text GGUFs
were downloaded; no vision projector is installed.

Both Qwen models passed arithmetic, Python sum, and Python filter checks with
nonempty thinking and normally completed answers. The initial 512-token cap
truncated two 4B answers during thinking; rerunning with `--max-tokens 2048`
allowed all answers to finish without disabling thinking. Their generation
times were roughly 7–14 seconds for these prompts, versus 3–6 seconds for the
earlier Bonsai abliterated checks: faster tokens did not produce faster answers
here because Qwen generated more thinking tokens. These few prompts are not a
representative quality or latency suite.

Pinned download revisions, sizes and SHA256 values are saved in
`benchmarks/bonsai/results/qwen35-models.json`; completed-answer timings and
checks are in `qwen35-smoke.json`. Weights occupy about 2.55 GiB (4B) and
5.29 GiB (9B) on disk; these are file sizes, not total runtime VRAM usage.

## CPU speculative decoding trial, 2026-09-29

Tested the existing optimized abliterated 27B target on RX 7600 with
`unsloth/Qwen3.5-0.8B-GGUF` Q4_K_M drafting entirely on the Xeon (eight CPU
threads, zero draft GPU layers, draft device `none`). The 532,517,120-byte draft
was pinned and SHA256-verified; provenance and commands are saved in
`benchmarks/bonsai/results/cpu-speculation.json`. Runtime tokenizer compatibility
checks passed. Target weights, medium thinking and GPU offload stayed unchanged.

| Configuration | Arithmetic decode | Code decode, 128-token budget |
| --- | ---: | ---: |
| GPU-only control after trial | 25.93 tok/s | 25.34 tok/s |
| CPU draft, one token ahead | 8.23 tok/s | 7.47 tok/s |
| CPU draft, three tokens ahead | 3.61 tok/s | Stopped early |

The initial GPU-only arithmetic control was 24.95 tok/s. Three-token drafting
accepted 26/126 proposed arithmetic tokens (20.6%). One-token drafting accepted
31/38 (81.6%) on arithmetic and 50/76 (65.8%) on code, yet remained substantially
slower. This demonstrates that acceptance alone does not repay CPU drafting and
verification overhead. Arithmetic wall time was about 3.85 seconds GPU-only,
9.66 seconds with one-token drafting, and 20.30 seconds with three-token drafting.
The completed arithmetic response was identical across these configurations.

A default `ngram-simple` trial proposed no tokens on the three diagnostic
prompts and stayed around baseline speed. This does not rule out benefits on
repetitive workloads. The three-token trial was stopped during its long code
request after the completed arithmetic slowdown; incomplete output is excluded.
Long code/explanation samples deliberately use a token cap and are throughput
checks, not finished-answer quality evaluations. Temperature zero was used only
for the tests. Existing launchers were not changed, and temporary servers were
stopped. GPU-only remains the recommended configuration for this tested pairing.

## Two-wave RDNA3 launch geometry, 2026-09-29

The local `runtime-optimized` GC-root symlink now selects the tested two-wave
candidate. It retains the packed-v2 dot product and changes only the PTQ1_0
single-column RDNA3 matrix-vector launch from one wave to two waves per row.
The normal local launchers pick it up automatically. This patch does not change
Qwen Q4_K kernels, weights, context, or reasoning settings. The system package
and NixOS generation remain unchanged.

Alternating abliterated-model benchmarks:

| Decode length | Packed-v2 mean | Two-wave mean | Gain |
| --- | ---: | ---: | ---: |
| 256 tokens, two runs per binary | 25.47 tok/s | 26.37 tok/s | 3.52% |
| 512 tokens, two runs per binary | 25.64 tok/s | 26.26 tok/s | 2.43% |

This is a modest gain with run-to-run variation, not evidence that 30–40 tok/s
is attainable. All six thinking-enabled answer checks passed (arithmetic,
Python sum, and filtering, on stock and abliterated models). The two-wave
mapping covers each K block once, synchronizes the partial sums, and retains
one writer per output row. Floating-point addition order changes, so the old
bit-exact dot-product harness does not certify full-kernel bitwise equivalence.
These answer checks are limited regression coverage, not a broad quality eval.

The previous optimized runtime is preserved:

```sh
BONSAI_RUNTIME="$HOME/.local/share/bonsai/runtime-packed-v2" \
  ~/.local/share/bonsai/chat-abliterated
```

Reproduce the current candidate with `benchmarks/bonsai/two-waves.nix` (see
benchmark README); `pkgs/bonsai/experimental.nix` still builds its packed-v2
base. Patch and result records live under `benchmarks/bonsai/patches/` and
`benchmarks/bonsai/results/two-waves*.json`. Raw logs are in
`/tmp/bonsai-ab-two-waves*` and `/tmp/bonsai-two-waves-smoke-*`.

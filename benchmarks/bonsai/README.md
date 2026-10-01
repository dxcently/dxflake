# AMD PTQ1_0 kernel experiment

The experiment changes only the HIP PTQ1_0 dot product in the pinned PrismML
runtime. Model files, scales, sampling, and reasoning settings are unchanged.
The baseline remains `pkgs/bonsai/default.nix`; the opt-in candidate is
`pkgs/bonsai/experimental.nix`. Neither building nor testing switches NixOS.

Run commands from the dxflake repository root. Close other GPU model sessions
first; these tests deliberately run one model process at a time.

## Build the candidate

```sh
nix build --impure --expr '
  let f = builtins.getFlake ("path:" + toString ./.);
  in f.nixosConfigurations.osaka.pkgs.callPackage ./pkgs/bonsai/experimental.nix {}
' --max-jobs 1 --out-link /tmp/bonsai-experimental -L
```

## GPU arithmetic validation

Enter the compiler environment from the same pinned package set:

```sh
nix develop --impure --expr '
  let f = builtins.getFlake ("path:" + toString ./.);
  in import ./benchmarks/bonsai/shell.nix { pkgs = f.nixosConfigurations.osaka.pkgs; }
'
```

Obtain the source used by the baseline package, copy it to a writable temporary
directory, and apply the candidate patch:

```sh
bonsai_source=$(nix eval --impure --raw --expr '
  let f = builtins.getFlake ("path:" + toString ./.);
  in toString (f.nixosConfigurations.osaka.pkgs.callPackage ./pkgs/bonsai {}).src
')
bonsai_work=$(mktemp -d /tmp/bonsai-check.XXXXXX)
cp -R "$bonsai_source/." "$bonsai_work/"
chmod -R u+w "$bonsai_work"
patch -p1 -d "$bonsai_work" < pkgs/bonsai/patches/hip-ptq1-packed-dot.patch
python3 benchmarks/bonsai/check_ptq1_hip.py \
  --source "$bonsai_source/ggml/src/ggml-cuda/vecdotq.cuh"
python3 benchmarks/bonsai/check_ptq1_hip.py \
  --source "$bonsai_work/ggml/src/ggml-cuda/vecdotq.cuh"
```

The harness extracts the actual production function, uses the same RDNA3 signed
packed-dot intrinsic as `common.cuh`, and compares against a separate scalar
CPU decoder. It covers all 65,536 tail-byte pairs, varied block bytes and half
scales, signed Q8 extremes, multiple block/activation offsets, and a partial
workgroup. Both sides use contraction disabled for a bit-exact arithmetic
comparison; full-runtime chat comparisons separately exercise release flags.
This harness intentionally targets `gfx1102`; it does not certify other GPUs.

## Model speed and correctness

```sh
python3 benchmarks/bonsai/compare.py \
  --baseline ~/.local/share/bonsai/runtime/bin \
  --candidate /tmp/bonsai-experimental/bin \
  --model ~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0.gguf \
  --output /tmp/bonsai-ab-stock

python3 benchmarks/bonsai/smoke.py \
  --runtime /tmp/bonsai-experimental/bin \
  --model ~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0.gguf \
  --output /tmp/bonsai-smoke-stock
```

Repeat with `Ternary-Bonsai-2-27B-PTQ1_0-abliterated.gguf` and separate output
directories. `compare.py` alternates execution order across rounds and records
commands, raw timings, and summaries. The smoke script keeps medium reasoning,
uses a temporary loopback server on port 18082, refuses an occupied port, and
stops only the process it created. Its three questions are regression smoke
checks, not a general model-quality evaluation.

## Compiler evidence

`results/standalone-isa.json` records device-only assembly of the extracted
function with ROCm 7.2.3, `-O3`, and `gfx1102`. The baseline test kernel used 117
VGPRs; packed-v1 used 58; packed-v2 used 60. All had zero scratch spill storage.
The candidates emitted 32 `v_dot4_i32_iu8` instructions; v2 also emitted 65
`v_perm_b32` instructions. These are static counts for the standalone test
kernel, not dynamic instruction counts or full-model occupancy measurements.
The source review and actual GPU correctness checks support the transformation;
model benchmarks determine whether it is useful.

## Smaller reasoning models

The same runtime runs Qwen3.5 Q4_K_M through its ordinary Q4 kernels; the
PTQ1_0 patch is specific to Bonsai. Pinned model metadata is saved in
`results/qwen35-models.json`. Reproduce throughput, substituting 9B for 4B:

```sh
~/.local/share/bonsai/runtime-optimized/bin/bonsai-bench \
  -m ~/.local/share/bonsai/models/Qwen3.5-4B-Q4_K_M.gguf \
  -ngl 99 -p 128 -n 256 -b 256 -ub 128 -t 8 -fa on -r 2 -o json
python3 benchmarks/bonsai/smoke.py \
  --runtime ~/.local/share/bonsai/runtime-optimized/bin \
  --model ~/.local/share/bonsai/models/Qwen3.5-4B-Q4_K_M.gguf \
  --output /tmp/qwen4b-smoke --max-tokens 2048
```

Qwen's template consumes `enable_thinking` but ignores `reasoning_effort`;
this is thinking on, not a claimed medium effort. The larger completion budget
allows thinking to finish; it is not a speed tweak. Read generation rate
alongside completion length and time to answer when comparing models.

## CPU drafting with GPU verification

`speculate.py` starts a temporary loopback server on port 18083 and cleans it
up on exit. It refuses an occupied port. Close other inference processes before
running it. The target stays on GPU; `draft-simple` explicitly selects zero GPU
layers and device `none` for the draft. Thinking remains enabled on the target.
Temperature zero makes comparisons reproducible; normal launcher settings are
not modified. Long answers deliberately hit a token cap for throughput testing,
so these runs are not a general quality evaluation.

```sh
python3 benchmarks/bonsai/speculate.py \
  --runtime ~/.local/share/bonsai/runtime-optimized/bin \
  --model ~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0-abliterated.gguf \
  --cases arithmetic code --max-tokens 128 \
  --output /tmp/spec-control
python3 benchmarks/bonsai/speculate.py \
  --runtime ~/.local/share/bonsai/runtime-optimized/bin \
  --model ~/.local/share/bonsai/models/Ternary-Bonsai-2-27B-PTQ1_0-abliterated.gguf \
  --mode draft-simple \
  --draft ~/.local/share/bonsai/models/Qwen3.5-0.8B-Q4_K_M.gguf \
  --draft-tokens 1 --cases arithmetic code --max-tokens 128 \
  --output /tmp/spec-cpu-draft
```

The CPU draft download is pinned in `results/cpu-speculation.json`. The runtime
checks vocabulary/BOS/EOS compatibility before drafting and accepts a proposed
token only when it matches the target's sampled token. Different compute
batching can still introduce numerical differences; this is not a blanket
bitwise-output guarantee. Inspect draft acceptance and wall time as well as
generation throughput. The experiment does not install a persistent server.

## Two-wave RDNA3 candidate

The current machine-local runtime adds this launch-geometry candidate to the
packed-v2 base. Build it independently with:

```sh
nix build --impure --expr '
  let f = builtins.getFlake ("path:" + toString ./.);
  in f.nixosConfigurations.osaka.pkgs.callPackage ./benchmarks/bonsai/two-waves.nix {}
' --max-jobs 1 --out-link /tmp/bonsai-two-waves -L
```

Use `compare.py` with `--baseline ~/.local/share/bonsai/runtime-packed-v2/bin`
and `--candidate /tmp/bonsai-two-waves/bin`; the `runtime-optimized` symlink
now points to the candidate and must not be used as its own control. Test both
256- and 512-token runs. Run `smoke.py` on stock and abliterated models.
Results and numerical-validation limitations are recorded in `docs/BONSAI.md`.
The new geometry changes floating-point reduction order; the bit-exact dot
harness validates the unchanged inner dot function, not the full reduction.

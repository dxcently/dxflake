#!/usr/bin/env python3
"""Compile and run a small HIP correctness check for PTQ1_0 x Q8_1.

The device function is extracted from the production vecdotq.cuh supplied by
the caller.  This intentionally does not reimplement the packed kernel in the
test: only the scalar reference below knows how to decode the format.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import tempfile


FUNCTION = "vec_dot_ptq1_0_q8_1"


def extract_function(source: str) -> str:
    marker = re.compile(
        r"static\s+__device__\s+__forceinline__\s+float\s+"
        + FUNCTION
        + r"\s*\("
    )
    match = marker.search(source)
    if not match:
        raise SystemExit(f"could not find {FUNCTION} in production header")
    start = match.start()
    brace = source.find("{", match.end())
    if brace < 0:
        raise SystemExit(f"could not find body of {FUNCTION}")
    depth = 0
    for pos in range(brace, len(source)):
        if source[pos] == "{":
            depth += 1
        elif source[pos] == "}":
            depth -= 1
            if depth == 0:
                return source[start : pos + 1]
    raise SystemExit(f"unterminated body of {FUNCTION}")


PREAMBLE = r'''
#include <hip/hip_runtime.h>
#include <hip/hip_fp16.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define GGML_USE_HIP 1
#define QK_PTQ1_0 128
#define QK8_1 32
typedef __half ggml_half;
typedef struct { uint8_t qs[24]; uint8_t qh[2]; ggml_half d; } block_ptq1_0;
typedef struct { union { struct { ggml_half d; ggml_half s; }; __half2 ds; }; int8_t qs[32]; } block_q8_1;
static_assert(sizeof(block_ptq1_0) == 28, "PTQ1 layout changed");
static_assert(sizeof(block_q8_1) == 36, "Q8_1 layout changed");
static __device__ __forceinline__ int get_int_b4(const void *p, int i) {
    return ((const int *)p)[i];
}
// Same gfx1102 intrinsic as production common.cuh's RDNA3 branch.
static __device__ __forceinline__ int ggml_cuda_dp4a(int a, int b, int c) {
#if defined(__HIP_DEVICE_COMPILE__)
    return __builtin_amdgcn_sudot4(true, a, true, b, c, false);
#else
    return 0;
#endif
}

'''

KERNEL = r'''
extern "C" __global__ void run_cases(const block_ptq1_0 *x, const block_q8_1 *y,
                                      const int *xb, const int *yb, const int *iqs,
                                      float *out, int n) {
    int i = (int)(blockIdx.x * blockDim.x + threadIdx.x);
    if (i < n) out[i] = vec_dot_ptq1_0_q8_1(x, y + yb[i], xb[i], iqs[i]);
}
'''

HOST = r'''
static uint32_t rng_state = 0x9e3779b9u;
static uint32_t rng32() { rng_state ^= rng_state << 13; rng_state ^= rng_state >> 17; rng_state ^= rng_state << 5; return rng_state; }
static float scale_for(int i) {
    static const float edge[] = { -8.0f, -3.25f, -1.0f, -0.125f, 0.03125f, 0.5f, 1.0f, 7.5f, 31.0f };
    if (i < (int)(sizeof(edge) / sizeof(edge[0]))) return edge[i];
    return ((int)(rng32() % 2001) - 1000) / 257.0f;
}
static int8_t q8_for(int i) {
    static const int edge[] = { -128, -127, -1, 0, 1, 126, 127 };
    if (i < (int)(sizeof(edge) / sizeof(edge[0]))) return (int8_t)edge[i];
    return (int8_t)(rng32() & 255);
}
static int trit(const block_ptq1_0 &b, int e) {
    if (e < 80) {
        int m = e & 15, t = e >> 4, v = b.qs[m];
        while (t--) v = (v * 3) & 255;
        return ((v * 3) >> 8) - 1;
    }
    if (e < 120) {
        int z = e - 80, m = 16 + (z & 7), t = z >> 3, v = b.qs[m];
        while (t--) v = (v * 3) & 255;
        return ((v * 3) >> 8) - 1;
    }
    int h = e & 1, t = (e - 120) >> 1, v = b.qh[h];
    while (t--) v = (v * 3) & 255;
    return ((v * 3) >> 8) - 1;
}
static float reference(const block_ptq1_0 &b, const block_q8_1 *q, int iqs) {
    int sums[4] = {0, 0, 0, 0};
    for (int e = 0; e < 128; ++e) sums[e >> 5] += trit(b, e) * q[iqs + (e >> 5)].qs[e & 31];
    float acc = 0.0f;
    for (int k = 0; k < 4; ++k) acc += __half2float(q[iqs + k].d) * (float)sums[k];
    return __half2float(b.d) * acc;
}
static uint32_t bits(float x) { uint32_t u; memcpy(&u, &x, sizeof(u)); return u; }

int main() {
    const int n = 65537, nx = 65536, ny = 3, ni = 4;
    block_ptq1_0 *hx = (block_ptq1_0*)calloc(nx, sizeof(*hx));
    block_q8_1 *hy = (block_q8_1*)calloc(ny * (ni + 4), sizeof(*hy));
    int *hxb = (int*)malloc(n * sizeof(*hxb)), *hyb = (int*)malloc(n * sizeof(*hyb));
    int *hi = (int*)malloc(n * sizeof(*hi));
    float *hout = (float*)malloc(n * sizeof(*hout));
    for (int b = 0; b < nx; ++b) {
        for (int j = 0; j < 24; ++j) hx[b].qs[j] = (uint8_t)rng32();
        for (int j = 0; j < 2; ++j) hx[b].qh[j] = (uint8_t)((b >> (8 * j)) & 255);
        hx[b].d = __float2half(scale_for(b));
    }
    /* Include every byte value in the packed fields across the fixture. */
    for (int b = 0; b < 256; ++b) for (int j = 0; j < 24; ++j) hx[b].qs[j] = (uint8_t)((b + j) & 255);
    /* Adjacent zero/positive trits catch byte-walk and cross-byte carry bugs. */
    for (int j = 0; j < 24; ++j) hx[0].qs[j] = (uint8_t)((j & 1) ? 2 : 1);
    for (int row = 0; row < ny; ++row) for (int k = 0; k < ni + 4; ++k) {
        block_q8_1 &q = hy[row * (ni + 4) + k];
        q.d = __float2half(scale_for(20 + row * 8 + k)); q.s = __float2half(0.0f);
        for (int j = 0; j < 32; ++j) q.qs[j] = (int)(row * (ni + 4) * 32 + k * 32 + j) < 7 ? q8_for((int)(row * (ni + 4) * 32 + k * 32 + j)) : (int8_t)((row * (ni + 4) * 32 + k * 32 + j) & 255);
    }
    for (int i = 0; i < n; ++i) { hxb[i] = i % nx; hyb[i] = (int)(rng32() % ny) * (ni + 4); hi[i] = (int)(rng32() % (ni + 1)); }
    block_ptq1_0 *dx; block_q8_1 *dy; int *dxb, *dyb, *di; float *do_; size_t sx = nx*sizeof(*hx), sy = ny*(ni+4)*sizeof(*hy);
    if (hipMalloc(&dx, sx) || hipMalloc(&dy, sy) || hipMalloc(&dxb, n*sizeof(*dxb)) || hipMalloc(&dyb, n*sizeof(*dyb)) || hipMalloc(&di, n*sizeof(*di)) || hipMalloc(&do_, n*sizeof(*do_))) return 2;
    if (hipMemcpy(dx, hx, sx, hipMemcpyHostToDevice) || hipMemcpy(dy, hy, sy, hipMemcpyHostToDevice) || hipMemcpy(dxb, hxb, n*sizeof(*dxb), hipMemcpyHostToDevice) || hipMemcpy(dyb, hyb, n*sizeof(*dyb), hipMemcpyHostToDevice) || hipMemcpy(di, hi, n*sizeof(*di), hipMemcpyHostToDevice)) return 3;
    hipLaunchKernelGGL(run_cases, dim3((n + 127) / 128), dim3(128), 0, 0, dx, dy, dxb, dyb, di, do_, n);
    if (hipDeviceSynchronize() != hipSuccess || hipMemcpy(hout, do_, n*sizeof(*hout), hipMemcpyDeviceToHost) != hipSuccess) return 4;
    for (int i = 0; i < n; ++i) { float want = reference(hx[hxb[i]], hy + hyb[i], hi[i]); if (bits(want) != bits(hout[i])) { fprintf(stderr, "mismatch case=%d block=%d q8=%d iqs=%d want=%08x got=%08x\n", i, hxb[i], hyb[i], hi[i], bits(want), bits(hout[i])); return 1; } }
    printf("ptq1 hip correctness: %d cases, bit exact\n", n);
    return 0;
}
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", type=pathlib.Path, required=True, help="patched production vecdotq.cuh")
    ap.add_argument("--hipcc", default=shutil.which("hipcc") or "hipcc")
    ap.add_argument("--arch", choices=["gfx1102"], default="gfx1102")
    args = ap.parse_args()
    fn = extract_function(args.source.read_text())
    with tempfile.TemporaryDirectory(prefix="bonsai-ptq1-") as td:
        td = pathlib.Path(td)
        src = td / "check.cu"
        exe = td / "check"
        src.write_text(PREAMBLE + "\n" + fn + "\n" + KERNEL + HOST)
        cmd = [args.hipcc, "-x", "hip", "-O2", "-ffp-contract=off", f"--offload-arch={args.arch}", str(src), "-o", str(exe)]
        subprocess.run(cmd, check=True)
        subprocess.run([str(exe)], check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

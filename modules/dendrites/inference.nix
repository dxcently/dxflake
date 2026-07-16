{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Strix Halo's iGPU is RDNA 3.5 = gfx1151. ROCm ships tuned kernels only for a
  # handful of gfx targets; gfx1151 rides on the gfx11 (11.0.0) tensile libs via
  # HSA_OVERRIDE_GFX_VERSION. If a future ROCm gains native gfx1151 support, drop
  # the override. This is the single knob most likely to need tuning on new silicon.
  gfxOverride = "11.0.0";

  # Client-side AI tooling. torch-rocm is intentionally OMITTED: it isn't in the
  # binary cache for the ROCm 7.x stack and needs a multi-hour from-source build
  # (drags in rccl/rocprofiler/torch). If you want torch on this box, add it out
  # of band via uv/venv (a pip rocm wheel), not this system env. Rest is light + cached.
  aiPython = pkgs.python3.withPackages (
    ps: with ps; [
      numpy
      requests
      openai
      huggingface-hub
    ]
  );
in
{
  options.dx.inference.enable = lib.mkEnableOption "local AI inference stack (Ollama + Open-WebUI, ROCm)";

  config = lib.mkIf config.dx.inference.enable {
    # Requires an AMD GPU wired up (ROCm userspace, amdgpu). The desktop hosts
    # that turn this on also flip dx.gpu-amd.enable; assert so a misconfigured
    # host fails loudly at eval instead of silently falling back to CPU.
    assertions = [
      {
        assertion = config.dx.gpu-amd.enable;
        message = "dx.inference requires dx.gpu-amd.enable = true (ROCm/amdgpu).";
      }
    ];

    # ── Ollama: model server, ROCm-accelerated ──────────────────────────────
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      rocmOverrideGfx = gfxOverride;
      host = "127.0.0.1";
      port = 11434;
      # Strix Halo has a huge unified-memory pool; let Ollama keep models warm.
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = gfxOverride;
        OLLAMA_KEEP_ALIVE = "30m";
        OLLAMA_FLASH_ATTENTION = "1";
      };
    };

    # ── Open-WebUI: browser frontend, talks to the local Ollama ─────────────
    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = 8080;
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        # Local single-user box; skip the OpenAI passthrough and telemetry.
        ENABLE_OPENAI_API = "False";
        ANONYMIZED_TELEMETRY = "False";
        WEBUI_AUTH = "False";
      };
    };

    # ── Extras: llama.cpp (ROCm) + a light Python AI-client env ─────────────
    environment.systemPackages = [
      (pkgs.llama-cpp.override { rocmSupport = true; })
      aiPython
      pkgs.rocmPackages.rocminfo # `rocminfo` / `rocm-smi` to confirm the GPU is seen
      pkgs.rocmPackages.rocm-smi
    ];
  };
}

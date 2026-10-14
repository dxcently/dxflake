{
  pkgs,
  config,
  lib,
  ...
}:
let
  # ROCm ships tuned tensile kernels for only a handful of gfx targets — gfx1100
  # chief among gfx11 parts. Every other RDNA3/3.5 chip rides those gfx1100
  # kernels via HSA_OVERRIDE_GFX_VERSION: yomi-strix's Strix Halo iGPU (gfx1151)
  # and osaka's discrete Navi 33 (gfx1102) both need it. If a future ROCm gains
  # native support for a given target, drop the override for that host.
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
  options.dx.inference = {
    igpu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        This host's ROCm GPU is integrated (unified memory) rather than discrete.
        Ollama drops integrated GPUs unless told otherwise, so this flips
        OLLAMA_IGPU_ENABLE. Leave off for a discrete card.
      '';
    };
  };

  config = {
    # Requires an AMD GPU wired up (ROCm userspace, amdgpu). The desktop hosts
    # that turn this on also import dx.gpu-amd; assert on the driver it
    # actually sets so a misconfigured host fails loudly at eval instead of
    # silently falling back to CPU.
    assertions = [
      {
        assertion = lib.elem "amdgpu" config.services.xserver.videoDrivers;
        message = "dx.inference requires the gpu-amd dendrite imported (amdgpu in services.xserver.videoDrivers).";
      }
    ];

    # ── Ollama: model server, ROCm-accelerated ──────────────────────────────
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      rocmOverrideGfx = gfxOverride;
      host = "127.0.0.1";
      port = 11434;
      # Single-user local box; let Ollama keep models warm rather than reloading
      # them every request.
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = gfxOverride;
        OLLAMA_KEEP_ALIVE = "30m";
        OLLAMA_FLASH_ATTENTION = "1";
      }
      // lib.optionalAttrs config.dx.inference.igpu {
        # Without this, an iGPU host silently runs CPU-only (verified in logs).
        OLLAMA_IGPU_ENABLE = "1";
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

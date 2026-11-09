# lact — LACT, the GPU control daemon and GUI: clocks, voltage offset, power
# limit, fan curve. Overdrive opens the amdgpu knobs it writes; tuning lives in
# LACT's own /etc/lact/config.yaml, written from the GUI, not here.
{
  config = {
    services.lact.enable = true;
    hardware.amdgpu.overdrive.enable = true;
  };
}

# Enter with the same pkgs as nixosConfigurations.osaka.
{ pkgs }:
pkgs.mkShell {
  packages = [
    pkgs.python3
    pkgs.rocmPackages.clr
    pkgs.patch
  ];
  HIP_DEVICE_LIB_PATH = "${pkgs.rocmPackages.rocm-device-libs}/amdgcn/bitcode";
}

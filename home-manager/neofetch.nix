{ pkgs, config, ... }:

{
  home.file.".config/neofetch/config.conf".text = ''
    print_info() {
        info "$(color 1)󰫢  dxflake" distro
        info underline
        info "$(color 2)✿  hoa" model
        info "$(color 3)  ver" kernel
        info "$(color 4)  pkg" packages
        info "$(color 5)󰧲  wm " de
        info "$(color 6)  ter" term
        info "$(color 7)󰻠  cpu" cpu
        info "$(color 8)  gpu" gpu
        info "$(color 0)󰍛  mem" memory
        prin " "
        prin "$(color 1)󰝤 $(color 2)󰝤 $(color 3)󰝤 $(color 4)󰝤 $(color 5)󰝤 $(color 6)󰝤 $(color 7)󰝤 $(color 8)󰝤 "
    }
    distro_shorthand="on"
    memory_unit="gib"
    cpu_temp="C"
    separator=" $(color 4)>"
    stdout="off"
  '';
}

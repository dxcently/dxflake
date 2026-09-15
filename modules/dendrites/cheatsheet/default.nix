# cheatsheet — a yad window listing the Hyprland, Neovim and Yazi keybinds.
#
# Its own dendrite rather than part of the keybinds it documents: Hyprland is
# only the key that opens it (SUPER+B), the content is hand-maintained and
# describes three capabilities at once, and nothing about it needs a compositor.
# It is reached by NAME — any dendrite may `exec cheatsheet` — so no file points
# at another file's path.
{
  homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "cheatsheet";
          runtimeInputs = with pkgs; [
            yad
            findutils # the EXIT trap pipes `jobs -p` into xargs
          ];
          text = builtins.readFile ./cheatsheet.sh;
        })
      ];
    };
}

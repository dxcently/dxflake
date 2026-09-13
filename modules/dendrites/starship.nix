{
  nixos = { username, ... }: {
    home-manager.users.${username} = { ... }: {
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
        settings = {
          add_newline = true;

          format = ''
            ═𝄞═══ $directory𝅘𝅥𝅮 $git_branch$git_status
            ═𓏲𝄢═══ $username@$hostname$character'';

          directory = {
            truncation_length = 3;
            truncate_to_repo = false;
            read_only = " ♯";
          };

          username = {
            show_always = true;
            format = "[$user]($style)";
          };

          hostname = {
            ssh_only = false;
            format = "[$hostname]($style) ";
          };

          git_branch = {
            symbol = "♬ ";
          };

          git_status = {
            format = "[♭$all_status$ahead_behind]($style) ";
            ahead = "𝄪\${count}";
            behind = "𝄫\${count}";
            modified = "𝅗𝅥";
            staged = "𝅘𝅥";
            untracked = "𝅝";
            conflicted = "𝄢";
          };

          character = {
            success_symbol = "♪";
            error_symbol = "𝄽";
          };
        };
      };
    };
  };
}

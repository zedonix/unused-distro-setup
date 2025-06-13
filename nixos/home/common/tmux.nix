{
  pkgs,
  ...
}:
{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on';
          set -g @continuum-save-interval '15';
        '';
      }
    ];
    extraConfig = "
      set -g mouse on
      set -g base-index 1
      setw -g pane-base-index 1
      set -g status-bg black
      set -g status-fg white
      set -sg escape-time 0
      set -g status-left ''
      set -g status-right ''
    ";
  };
}

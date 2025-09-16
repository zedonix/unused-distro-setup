{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      PS1="\n \[\e[38;5;40m\]\w\[\e[38;5;51m\] > \[\e[0m\]"
      set -o vi
      HISTCONTROL=ignoreboth
      export EDITOR=nvim
      export VISUAL=nvim
      eval "$(direnv hook bash)"
    '';

    shellAliases = {
      l = "eza -l --icons=always";
      ll = "eza -la --icons=always";
      vi = "nvim ~/vimwiki/index.md";
      nb = "newsboat";
      pic = "swayimg";
      speed = "speedtest-cli --bytes";
      record = "asciinema rec";
      play = "asciinema play";
      yt = "yt-dlp";
      fzf = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    };
  };
}

{
  programs.newsboat = {
    enable = true;
    urls = [
      # {
      #   title = "FOSS Linux";
      #   url = "https://www.fosslinux.com/#";
      # }
      {
        title = "Crazy Programmer";
        url = "https://www.thecrazyprogrammer.com/feed";
      }
      {
        title = "Linux HandBook";
        url = "https://linuxhandbook.com/rss";
      }
      {
        title = "Bog";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCZXW8E1__d5tZb-wLFOt8TQ";
      }
      {
        title = "Brodie Robertson";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCld68syR8Wi-GY_n4CaoJGA";
      }
      {
        title = "Vimjoyer";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC_zBdZ0_H_jn41FDRG7q4Tw";
      }
      {
        title = "The Linux Cast";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCylGUf9BvQooEFjgdNudoQg";
      }
      {
        title = "The Linux Experiment";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC5UAwBUum7CPN5buc-_N1Fw";
      }
      {
        title = "Core Dumped";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCGKEMK3s-ZPbjVOIuAV8clQ";
      }
    ];
    extraConfig = ''
      unbind-key j
      unbind-key k
      unbind-key h
      unbind-key H
      unbind-key L
      unbind-key c
      unbind-key ,

      prepopulate-query-feeds yes
      refresh-on-startup yes
      ignore-mode "display"

      bind-key ; macro-prefix
      bind-key h quit
      bind-key BACKSPACE quit
      bind-key j down
      bind-key k up
      bind-key l open
      bind-key H prev-feed
      bind-key L next-feed
      bind-key c toggle-show-read-feeds

      color background default default
      color listnormal default default
      color listnormal_unread default default
      color listfocus color16 cyan
      color listfocus_unread color16 cyan
      color info default black
      color article default default

      highlight article "(^Feed:.*|^Title:.*|^Author:.*)" cyan default bold
      highlight article "(^Link:.*|^Date:.*)" default default
      highlight article "https?://[^ ]+" green default

      highlight article "^(Title):.*$" blue default
      highlight article "\\[[0-9][0-9]*\\]" magenta default bold
      highlight article "\\[image\\ [0-9]+\\]" green default bold
      highlight article "\\[embedded flash: [0-9][0-9]*\\]" green default bold
      highlight article ":.*\\(link\\)$" cyan default
      highlight article ":.*\\(image\\)$" blue default
      highlight article ":.*\\(embedded flash\\)$" magenta default
    '';
  };

}

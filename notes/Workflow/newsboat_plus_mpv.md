---
date: 2022-01-08T23:25
title: Distraction-Free Setup Using Newsboat And mpv
---

# Intro
Recently I got frustrated from getting distracted by recommendations while
watching YouTube videos or reading articles. The solution that I've found
(although not really new) is very elegant. In this post I'll talk about it and
share system configuration snippets in the *Nix* language.

# Enter Newsboat
Newsboat is a battle-tested RSS reader that works really well, you can define
and tag URLs of blogs you usually read and it will automatically search for new
posts and allows you to read them.

# Enter mpv
Mpv is an awesome libre commandline video player, and it can also leverage of
*youtube-dl* in order to play videos from YouTube, without the need of opening
it in your browser.

## Installing Newsboat and mpv Through Home-Manager
```nix
{ pkgs, ... }:
let
  mpv = "${pkgs.mpv}/bin/mpv";
in
{
  programs.newsboat = {
    enable = true;
    autoReload = true;
    urls = [
      {
        url = "https://hnrss.org/newest";
        title = "Hacker News";
        tags = [ "tech" ];
      }

      # Reddit
      {
        url = "https://www.reddit.com/r/neovim/.rss";
        title = "/r/neovim";
        tags = [ "neovim" "reddit" ];
      }

      # Youtube
      {
        title = "Computerphile";
        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC9-y-6csu5WGm29I7JiwpnA";
        tags = [ "tech" "youtube" ];
      }
    ];
    extraConfig = ''
      # misc
      refresh-on-startup yes

      # display
      feed-sort-order unreadarticlecount-asc
      text-width      72

      # unbind keys
      unbind-key ENTER
      unbind-key j
      unbind-key k
      unbind-key J
      unbind-key K

      # bind keys - vim style
      bind-key j down
      bind-key k up
      bind-key l open
      bind-key h quit
      bind-key g home
      bind-key G end

      # colorscheme
      color listnormal        white black
      color listnormal_unread white black
      color listfocus         white black bold reverse
      color listfocus_unread  white black bold reverse
      color info              white black reverse bold
      color background        white black
      color article           white black

      # macros
      macro v set browser "${mpv} %u" ; open-in-browser ; set browser "firefox %u" -- "Open video on mpv"
    '';
  };
}
```
Having this setup, you can now just hover a YouTube entry in newsboat and press
`,v`, and it will open a window playing the video.

# Conclusion
Now I can open newsboat whenever I want to check if there's any new good media
to consume, without having to fire up a browser and opening something such as
YouTube or Blogs.

# Resources
- [Newsboat](https://newsboat.org)
- [mpv](https://github.com/mpv-player/mpv)
- [youtube-dl](https://github.com/ytdl-org/youtube-dl)


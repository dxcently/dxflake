{
  pkgs,
  config,
  ...
}: {
  programs.librewolf = {
    enable = true;
    settings = {
      "webgl.disabled" = false;
      "identity.fxaccounts.enabled" = true;
      "browser..sessionstore.resume_from_crash" = true;
      "privacy.clearOnShutdown.cookies" = false;
      "privacy.clearOnShutdown.history" = false;
      "dom.event.contextmenu.enabled" = true;
      "widget.use-xdg-desktop-portal.file-picker" = 1;
      "browser.urlbar.suggest.searches" = false;
      "browser.urlbar.shortcuts.bookmarks" = false;
      "browser.urlbar.shortcuts.history" = false;
      "browser.urlbar.shortcuts.tabs" = false;
      "browser.urlbar.showSearchSuggestionsFirst" = false;
      "browser.urlbar.speculativeConnect.enabled" = false;
      "browser.urlbar.trimURLs" = false;
      "browser.disableResetPrompt" = true;
      "browser.onboarding.enabled" = false;
      "browser.aboutConfig.showWarning" = false;
    };
  };
}

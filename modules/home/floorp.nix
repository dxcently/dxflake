{
  pkgs,
  config,
  ...
}: {
  programs.floorp = {
    enable = true;
    /*
    profiles.dx = {
    name = "dx";
    isDefault = true;
    /*
      settings = {
      "extensions.autoDisableScopes" = 0;
    };
    */
    /*
        extraConfig = ''
        user_pref("accessibility.typeaheadfind.flashBar", 0);
        user_pref("app.normandy.first_run", false);
        user_pref("app.normandy.migrationsApplied", 12);
        user_pref("app.update.lastUpdateTime.addon-background-update-timer", 1741800184);
        user_pref("app.update.lastUpdateTime.browser-cleanup-thumbnails", 1741809048);
        user_pref("app.update.lastUpdateTime.region-update-timer", 1741808041);
        user_pref("app.update.lastUpdateTime.services-settings-poll-changes", 1741800184);
        user_pref("app.update.lastUpdateTime.xpi-signature-verification", 1741800184);
        user_pref("browser.aboutConfig.showWarning", false);
        user_pref("browser.bookmarks.defaultLocation", "t5e6EQKs4Xo7");
        user_pref("browser.bookmarks.editDialog.confirmationHintShowCount", 3);
        user_pref("browser.bookmarks.restore_default_bookmarks", false);
        user_pref("browser.bookmarks.showMobileBookmarks", true);
        user_pref("browser.contentblocking.category", "standard");
        user_pref("browser.contextual-services.contextId", "{b2b24016-15f2-456e-9201-62140f66f149}");
        user_pref("browser.download.autohideButton", false);
        user_pref("browser.download.lastDir", "/home/khoa/Downloads");
        user_pref("browser.download.panel.shown", true);
        user_pref("browser.download.useDownloadDir", false);
        user_pref("browser.download.viewableInternally.typeWasRegistered.avif", true);
        user_pref("browser.download.viewableInternally.typeWasRegistered.jxl", true);
        user_pref("browser.download.viewableInternally.typeWasRegistered.webp", true);
        user_pref("browser.engagement.downloads-button.has-used", true);
        user_pref("browser.engagement.fxa-toolbar-menu-button.has-used", true);
        user_pref("browser.engagement.sidebar-button.has-used", true);
        user_pref("browser.firefox-view.view-count", 8);
        user_pref("browser.laterrun.bookkeeping.profileCreationTime", 1737480581);
        user_pref("browser.laterrun.bookkeeping.sessionCount", 1);
        user_pref("browser.migrate.interactions.history", true);
        user_pref("browser.migration.version", 148);
        user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", true);
        user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
        user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
        user_pref("browser.newtabpage.activity-stream.floorp.background.image.path", "/home/khoa/Pictures/wallhaven-d67qq3.jpg");
        user_pref("browser.newtabpage.activity-stream.floorp.background.images.folder", "/home/khoa/dxflake/extras/wallpapers");
        user_pref("browser.newtabpage.activity-stream.floorp.background.type", 3);
        user_pref("browser.newtabpage.activity-stream.impressionId", "{9289ca88-b6e1-4211-9605-377a6e782921}");
        user_pref("browser.newtabpage.activity-stream.showSearch", false);
        user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
        user_pref("browser.newtabpage.pinned", "[{\"url\":\"https://amazon.com\",\"label\":\"@amazon\",\"searchTopSite\":true,\"baseDomain\":\"amazon.com\"},{\"url\":\"https://google.com\",\"label\":\"@google\",\"searchTopSite\":true}]");
        user_pref("browser.newtabpage.storageVersion", 1);
        user_pref("browser.pageActions.persistedActions", "{\"ids\":[\"bookmark\",\"_e1cad622-f77c-4035-8137-33b8296e5c9d_\"],\"idsInUrlbar\":[\"_e1cad622-f77c-4035-8137-33b8296e5c9d_\",\"bookmark\"],\"idsInUrlbarPreProton\":[],\"version\":1}");
        user_pref("browser.pagethumbnails.storage_version", 3);
        user_pref("browser.policies.applied", true);
        user_pref("browser.proton.toolbar.version", 3);
        user_pref("browser.rights.3.shown", true);
        user_pref("browser.safebrowsing.provider.google4.lastupdatetime", "1740298075872");
        user_pref("browser.safebrowsing.provider.google4.nextupdatetime", "1740299860872");
        user_pref("browser.safebrowsing.provider.mozilla.lastupdatetime", "1741794480305");
        user_pref("browser.safebrowsing.provider.mozilla.nextupdatetime", "1741816080305");
        user_pref("browser.sessionstore.upgradeBackup.latestBuildID", "20250306174312");
        user_pref("browser.shell.didSkipDefaultBrowserCheckOnFirstRun", true);
        user_pref("browser.shell.mostRecentDateSetAsDefault", "1741806950");
        user_pref("browser.startup.couldRestoreSession.count", 1);
        user_pref("browser.startup.homepage_override.buildID", "20250306174312");
        user_pref("browser.startup.homepage_override.mstone", "128.9.0");
        user_pref("browser.startup.lastColdStartupCheck", 1741806948);
        user_pref("browser.tabs.inTitlebar", 1);
        user_pref("browser.tabs.tabMinWidth", 64);
        user_pref("browser.tabs.warnOnClose", false);
        user_pref("browser.theme.toolbar-theme", 1);
        user_pref("browser.translations.panelShown", true);
        user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[\"profile-manager\",\"fxa-toolbar-menu-button\"],\"unified-extensions-area\":[\"_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action\",\"sponsorblocker_ajay_app-browser-action\",\"dfyoutube_example_com-browser-action\",\"firefox_tampermonkey_net-browser-action\",\"jid1-bofifl9vbdl2zq_jetpack-browser-action\",\"_799c0914-748b-41df-a25c-22d008f9e83f_-browser-action\",\"_6ac85730-7d0f-4de0-b3fa-21142dd85326_-browser-action\",\"emoji_saveriomorelli_com-browser-action\",\"leechblockng_proginosko_com-browser-action\",\"_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action\",\"treestyletab_piro_sakura_ne_jp-browser-action\",\"_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"customizableui-special-spring1\",\"customizableui-special-spring2\",\"save-to-pocket-button\",\"_3c078156-979c-498b-8990-85f7987dd929_-browser-action\",\"stop-reload-button\",\"urlbar-container\",\"downloads-button\",\"sidebar-button\",\"unified-extensions-button\",\"ublock0_raymondhill_net-browser-action\",\"addon_darkreader_org-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\",\"firefox-view-button\"],\"PersonalToolbar\":[\"personal-bookmarks\"],\"statusBar\":[\"screenshot-button\",\"fullscreen-button\",\"status-text\"]},\"seen\":[\"developer-button\",\"sidebar-reverse-position-toolbar\",\"undo-closed-tab\",\"profile-manager\",\"workspaces-toolbar-button\",\"dfyoutube_example_com-browser-action\",\"sponsorblocker_ajay_app-browser-action\",\"firefox_tampermonkey_net-browser-action\",\"jid1-bofifl9vbdl2zq_jetpack-browser-action\",\"_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action\",\"_799c0914-748b-41df-a25c-22d008f9e83f_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"_6ac85730-7d0f-4de0-b3fa-21142dd85326_-browser-action\",\"_3c078156-979c-498b-8990-85f7987dd929_-browser-action\",\"emoji_saveriomorelli_com-browser-action\",\"leechblockng_proginosko_com-browser-action\",\"_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action\",\"treestyletab_piro_sakura_ne_jp-browser-action\",\"_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action\",\"addon_darkreader_org-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"statusBar\",\"TabsToolbar\",\"PersonalToolbar\",\"unified-extensions-area\",\"toolbar-menubar\",\"widget-overflow-fixed-list\"],\"currentVersion\":20,\"newElementCount\":5}");
        user_pref("browser.urlbar.placeholderName", "Google");
        user_pref("browser.urlbar.quicksuggest.migrationVersion", 2);
        user_pref("browser.urlbar.quicksuggest.scenario", "history");
        user_pref("browser.urlbar.tipShownCount.searchTip_onboard", 4);
        user_pref("browser.warnOnQuitShortcut", false);
        user_pref("browser.zoom.full", false);
        user_pref("devtools.everOpened", true);
        user_pref("devtools.selfxss.count", 5);
        user_pref("devtools.toolbox.selectedTool", "webconsole");
        user_pref("devtools.toolsidebar-height.inspector", 350);
        user_pref("devtools.toolsidebar-width.inspector", 700);
        user_pref("devtools.toolsidebar-width.inspector.splitsidebar", 350);
        user_pref("distribution.iniFile.exists.appversion", "128.9.0");
        user_pref("distribution.iniFile.exists.value", true);
        user_pref("distribution.nixos.bookmarksProcessed", true);
        user_pref("dom.forms.autocomplete.formautofill", true);
        user_pref("dom.push.userAgentID", "65f1cb3c868d4020806ba1047aa673fb");
        user_pref("extensions.activeThemeID", "{4f8988cc-a4f1-4676-89b2-a3f352d004d5}");
        user_pref("extensions.blocklist.pingCountVersion", -1);
        user_pref("extensions.databaseSchema", 36);
        user_pref("extensions.formautofill.creditCards.reauth.optout", "MDIEEPgAAAAAAAAAAAAAAAAAAAEwFAYIKoZIhvcNAwcECH9pek/HQ79gBAjAg0bCviJoOg==");
        user_pref("extensions.getAddons.cache.lastUpdate", 1741800184);
        user_pref("extensions.getAddons.databaseSchema", 6);
        user_pref("extensions.lastAppBuildId", "20250306174312");
        user_pref("extensions.lastAppVersion", "128.9.0");
        user_pref("extensions.lastPlatformVersion", "128.9.0");
        user_pref("extensions.pendingOperations", false);
        user_pref("extensions.pictureinpicture.enable_picture_in_picture_overrides", true);
        user_pref("extensions.quarantinedDomains.list", "autoatendimento.bb.com.br,ibpf.sicredi.com.br,ibpj.sicredi.com.br,internetbanking.caixa.gov.br,www.ib12.bradesco.com.br,www2.bancobrasil.com.br");
        user_pref("extensions.systemAddonSet", "{\"schema\":1,\"addons\":{}}");
        user_pref("extensions.ui.dictionary.hidd
    "application/pdf" = "firefox.desktop";
    "image/png" = [
      "sxiv.desktop"
      "gimp.desktop"
    ];en", true);
        user_pref("extensions.ui.extension.hidden", false);
        user_pref("extensions.ui.lastCategory", "addons://list/extension");
        user_pref("extensions.ui.locale.hidden", true);
        user_pref("extensions.ui.sitepermission.hidden", true);
        user_pref("extensions.ui.theme.hidden", false);
        user_pref("extensions.webcompat.enable_shims", true);
        user_pref("extensions.webcompat.perform_injections", true);
        user_pref("extensions.webcompat.perform_ua_overrides", true);
        user_pref("findbar.highlightAll", true);
        user_pref("floorp.browser.nora.csk.data", "{}");
        user_pref("floorp.browser.note.backup.latest.time", "1740507480653");
        user_pref("floorp.browser.note.memos", "{\"titles\":[\"Welcome!\",\"FLOORP SETTINGS SETUP\"],\"contents\":[\"Welcome to Floorp Notes! Here are some instructions on how to use it!\\n\\nFloorp Notes is a notepad that lets you store multiple notes that sync across devices. To enable synchronization, you need to sign in to Floorp with your Firefox account.\\nFloorp Notes will be saved in your Floorp settings and synchronized across devices using Firefox Sync. Firefox Sync encrypts the contents of the sync with your Firefox account password, so no one but you know its contents.\",\"\"]}");
        user_pref("floorp.browser.sidebar.is.displayed", false);
        user_pref("floorp.browser.sidebar.right", false);
        user_pref("floorp.browser.sidebar2.data", "{\"data\":{\"floorp__bmt\":{\"url\":\"floorp//bmt\",\"width\":600},\"floorp__bookmarks\":{\"url\":\"floorp//bookmarks\",\"width\":415},\"floorp__history\":{\"url\":\"floorp//history\",\"width\":415},\"floorp__downloads\":{\"url\":\"floorp//downloads\",\"width\":415},\"floorp__notes\":{\"url\":\"floorp//notes\",\"width\":550},\"w202502116126\":{\"url\":\"https://calendar.google.com/calendar/u/1/r/tasks?pli=1\",\"usercontext\":-1,\"width\":1000},\"w0\":{\"url\":\"https://translate.google.com\"},\"w202502116117\":{\"url\":\"https://chatgpt.com/\",\"usercontext\":-1,\"width\":700}},\"index\":[\"floorp__bmt\",\"floorp__bookmarks\",\"floorp__history\",\"floorp__downloads\",\"floorp__notes\",\"w202502116126\",\"w0\",\"w202502116117\"]}");
        user_pref("floorp.browser.sidebar2.global.webpanel.width", 444);
        user_pref("floorp.browser.ssb.toolbars.disabled", false);
        user_pref("floorp.browser.tabbar.multirow.max.row", 2);
        user_pref("floorp.browser.workspace.manageOnBMS", true);
        user_pref("floorp.download.notification", 3);
        user_pref("floorp.extensions.webextensions.sidebar-action", "{\"data\":{\"treestyletab@piro.sakura.ne.jp\":{\"title\":\"Tree Style Tab\",\"panel\":\"moz-extension://f05c3126-b3a1-4f82-9164-1f26fd581e95/sidebar/sidebar.html\",\"icon\":\"moz-extension://f05c3126-b3a1-4f82-9164-1f26fd581e95/resources/32x32.svg#default\"}}}");
        user_pref("floorp.lepton.interface", 1);
        user_pref("floorp.startup.oldVersion", "11.24.0");
        user_pref("floorp.tabsleep.enabled", true);
        user_pref("font.name.monospace.x-western", "Lekton Nerd Font Mono");
        user_pref("font.name.sans-serif.x-western", "Lekton Nerd Font");
        user_pref("font.name.serif.x-western", "Lekton Nerd Font");
        user_pref("font.size.variable.x-western", 12);
        user_pref("gecko.handlerService.defaultHandlersVersion", 1);
        user_pref("identity.fxaccounts.account.device.name", "dxpad floorp");
        user_pref("identity.fxaccounts.account.telemetry.sanitized_uid", "439898d11ce834bc62e55088c4fb1f39");
        user_pref("identity.fxaccounts.commands.missed.last_fetch", 1741801247);
        user_pref("identity.fxaccounts.lastSignedInUserHash", "/RMEGDu6mLhSj0mHj/zuc7s3FTZOpjyT1y3UmUm7xpo=");
        user_pref("identity.fxaccounts.toolbar.accessed", true);
        user_pref("idle.lastDailyNotification", 1741800949);
        user_pref("media.eme.enabled", true);
        user_pref("media.gmp-gmpopenh264.abi", "x86_64-gcc3");
        user_pref("media.gmp-gmpopenh264.hashValue", "53a58bfb4c8124ad4f7655b99bfdea290033a085e0796b19245b33b91c0948fdac9f0c3e817130b352493a65d9a7a0fc8a7c1eedc618cdaa2b4580734a11cd9c");
        user_pref("media.gmp-gmpopenh264.lastDownload", 1737480613);
        user_pref("media.gmp-gmpopenh264.lastInstallStart", 1737480612);
        user_pref("media.gmp-gmpopenh264.lastUpdate", 1737480613);
        user_pref("media.gmp-gmpopenh264.version", "2.3.2");
        user_pref("media.gmp-manager.buildID", "20250306174312");
        user_pref("media.gmp-manager.lastCheck", 1741794523);
        user_pref("media.gmp-manager.lastEmptyCheck", 1741794523);
        user_pref("media.gmp-widevinecdm.abi", "x86_64-gcc3");
        user_pref("media.gmp-widevinecdm.hashValue", "9f1fe2c912897bc644f936170eaa6a2cb13772e9456e377ebcb489ae58b85ce8095d7584c8e51658857e90e06b33f7e8005af58f6e91fe93bae752f3fe561ec6");
        user_pref("media.gmp-widevinecdm.lastDownload", 1737480690);
        user_pref("media.gmp-widevinecdm.lastDownloadFailReason", "Error: Failed downloading via ServiceRequest, status: 0, channelStatus: 2152398878, errorCode: 2, reason: error");
        user_pref("media.gmp-widevinecdm.lastDownloadFailed", 1738259053);
        user_pref("media.gmp-widevinecdm.lastInstallStart", 1738259053);
        user_pref("media.gmp-widevinecdm.lastUpdate", 1737480690);
        user_pref("media.gmp-widevinecdm.version", "4.10.2830.0");
        user_pref("media.gmp.storage.version.observed", 1);
        user_pref("media.videocontrols.picture-in-picture.video-toggle.first-seen-secs", 1737494360);
        user_pref("media.videocontrols.picture-in-picture.video-toggle.has-used", true);
        user_pref("network.dns.disablePrefetch", true);
        user_pref("network.http.speculative-parallel-limit", 0);
        user_pref("network.predictor.enabled", false);
        user_pref("network.prefetch-next", false);
        user_pref("pdfjs.enabledCache.state", true);
        user_pref("pdfjs.migrationVersion", 2);
        user_pref("places.database.lastMaintenance", 1741623131);
        user_pref("pref.downloads.disable_button.edit_actions", false);
        user_pref("print_printer", "Samsung-C48x-Series");
        user_pref("privacy.bounceTrackingProtection.hasMigratedUserActivationData", true);
        user_pref("privacy.clearHistory.cookiesAndStorage", false);
        user_pref("privacy.donottrackheader.enabled", true);
        user_pref("privacy.globalprivacycontrol.enabled", true);
        user_pref("privacy.globalprivacycontrol.was_ever_enabled", true);
        user_pref("privacy.purge_trackers.date_in_cookie_database", "0");
        user_pref("privacy.purge_trackers.last_purge", "1741800949519");
        user_pref("privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs2", true);
        user_pref("privacy.sanitize.cpd.hasMigratedToNewPrefs2", true);
        user_pref("privacy.sanitize.pending", "[{\"id\":\"newtab-container\",\"itemsToClear\":[],\"options\":{}}]");
        user_pref("privacy.sanitize.timeSpan", 0);
        user_pref("privacy.userContext.extension", "treestyletab@piro.sakura.ne.jp");
        user_pref("security.sandbox.content.tempDirSuffix", "57163e2b-261c-461b-aeff-769e835532c5");
        user_pref("services.settings.blocklists.addons-bloomfilters.last_check", 1741809951);
        user_pref("services.settings.blocklists.gfx.last_check", 1741809951);
        user_pref("services.settings.clock_skew_seconds", 0);
        user_pref("services.settings.last_etag", "\"1741810158578\"");
        user_pref("services.settings.last_update_seconds", 1741810556);
        user_pref("services.settings.main.addons-manager-settings.last_check", 1741809951);
        user_pref("services.settings.main.anti-tracking-url-decoration.last_check", 1741809951);
        user_pref("services.settings.main.cfr.last_check", 1741809951);
        user_pref("services.settings.main.cookie-banner-rules-list.last_check", 1741809951);
        user_pref("services.settings.main.devtools-compatibility-browsers.last_check", 1741809951);
        user_pref("services.settings.main.devtools-devices.last_check", 1741809951);
        user_pref("services.settings.main.doh-config.last_check", 1741809951);
        user_pref("services.settings.main.doh-providers.last_check", 1741809951);
        user_pref("services.settings.main.fingerprinting-protection-overrides.last_check", 1741809951);
        user_pref("services.settings.main.fxmonitor-breaches.last_check", 1741809951);
        user_pref("services.settings.main.hijack-blocklists.last_check", 1741809951);
        user_pref("services.settings.main.language-dictionaries.last_check", 1741809951);
        user_pref("services.settings.main.message-groups.last_check", 1741809951);
        user_pref("services.settings.main.normandy-recipes-capabilities.last_check", 1741809951);
        user_pref("services.settings.main.partitioning-exempt-urls.last_check", 1741809951);
        user_pref("services.settings.main.password-recipes.last_check", 1741809951);
        user_pref("services.settings.main.password-rules.last_check", 1741809951);
        user_pref("services.settings.main.pioneer-study-addons-v1.last_check", 1741809951);
        user_pref("services.settings.main.public-suffix-list.last_check", 1741809951);
        user_pref("services.settings.main.query-stripping.last_check", 1741809951);
        user_pref("services.settings.main.search-config-icons.last_check", 1741809951);
        user_pref("services.settings.main.search-config-overrides-v2.last_check", 1741809951);
        user_pref("services.settings.main.search-config-overrides.last_check", 1741809951);
        user_pref("services.settings.main.search-config-v2.last_check", 1741809951);
        user_pref("services.settings.main.search-config.last_check", 1741809951);
        user_pref("services.settings.main.search-default-override-allowlist.last_check", 1741809951);
        user_pref("services.settings.main.search-telemetry-v2.last_check", 1741809951);
        user_pref("services.settings.main.sites-classification.last_check", 1741809951);
        user_pref("services.settings.main.tippytop.last_check", 1741809951);
        user_pref("services.settings.main.top-sites.last_check", 1741809951);
        user_pref("services.settings.main.translations-models.last_check", 1741809951);
        user_pref("services.settings.main.translations-wasm.last_check", 1741809951);
        user_pref("services.settings.main.url-classifier-skip-urls.last_check", 1741809951);
        user_pref("services.settings.main.websites-with-shared-credential-backends.last_check", 1741809951);
        user_pref("services.settings.security-state.cert-revocations.last_check", 1741809951);
        user_pref("services.settings.security-state.intermediates.last_check", 1741809951);
        user_pref("services.settings.security-state.onecrl.last_check", 1741809951);
        user_pref("services.sync.addons.lastSync", "1741800647.15");
        user_pref("services.sync.addons.syncID", "G4XytdtAmV-z");
        user_pref("services.sync.addresses.lastSync", "1723685339.78");
        user_pref("services.sync.addresses.syncID", "ymvFcG70RE8w");
        user_pref("services.sync.client.GUID", "1gUyhK541rMr");
        user_pref("services.sync.client.syncID", "2va9QUtMOxih");
        user_pref("services.sync.clients.devices.desktop", 3);
        user_pref("services.sync.clients.devices.mobile", 1);
        user_pref("services.sync.clients.lastRecordUpload", 1741810225);
        user_pref("services.sync.clients.lastSync", "1741810225.37");
        user_pref("services.sync.clients.syncID", "iuUcxRJ9xzaV");
        user_pref("services.sync.creditcards.lastSync", "1738541169.58");
        user_pref("services.sync.creditcards.syncID", "dsI1ZOtpMZ79");
        user_pref("services.sync.declinedEngines", "");
        user_pref("services.sync.engine.addresses", true);
        user_pref("services.sync.engine.addresses.available", true);
        user_pref("services.sync.engine.creditcards", true);
        user_pref("services.sync.engine.prefs", true);
        user_pref("services.sync.engine.prefs.modified", false);
        user_pref("services.sync.forms.lastSync", "1741809656.16");
        user_pref("services.sync.forms.syncID", "07Qs509ExPjr");
        user_pref("services.sync.globalScore", 11);
        user_pref("services.sync.lastPing", 1741800087);
        user_pref("services.sync.lastSync", "Wed Mar 12 2025 16:10:31 GMT-0400 (Eastern Daylight Time)");
        user_pref("services.sync.lastTabFetch", 1741810231);
        user_pref("services.sync.nextSync", 1741810831);
        user_pref("services.sync.prefs.lastSync", "1741800646.75");
        user_pref("services.sync.prefs.sync-seen.browser.contentblocking.category", true);
        user_pref("services.sync.prefs.sync-seen.browser.download.useDownloadDir", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.activity-stream.feeds.section.highlights", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.activity-stream.feeds.section.topstories", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.activity-stream.feeds.topsites", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.activity-stream.section.highlights.includePocket", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.activity-stream.showSearch", true);
        user_pref("services.sync.prefs.sync-seen.browser.newtabpage.pinned", true);
        user_pref("services.sync.prefs.sync-seen.extensions.activeThemeID", true);
        user_pref("services.sync.prefs.sync-seen.floorp.browser.note.memos", true);
        user_pref("services.sync.prefs.sync-seen.floorp.browser.sidebar.right", true);
        user_pref("services.sync.prefs.sync-seen.general.autoScroll", true);
        user_pref("services.sync.prefs.sync-seen.media.eme.enabled", true);
        user_pref("services.sync.prefs.sync-seen.pref.downloads.disable_button.edit_actions", true);
        user_pref("services.sync.prefs.sync-seen.privacy.donottrackheader.enabled", true);
        user_pref("services.sync.prefs.sync-seen.privacy.globalprivacycontrol.enabled", true);
        user_pref("services.sync.prefs.sync-seen.privacy.userContext.enabled", true);
        user_pref("services.sync.prefs.syncID", "SPUBF23M9D5k");
        user_pref("services.sync.syncInterval", 600000);
        user_pref("services.sync.syncThreshold", 300);
        user_pref("services.sync.username", "dxcently@gmail.com");
        user_pref("signon.management.page.os-auth.optout", "MDIEEPgAAAAAAAAAAAAAAAAAAAEwFAYIKoZIhvcNAwcECDV/JUqA6YXSBAiuLlLIF0TVvw==");
        user_pref("storage.vacuum.last.content-prefs.sqlite", 1740283764);
        user_pref("storage.vacuum.last.index", 2);
        user_pref("storage.vacuum.last.places.sqlite", 1740090143);
        user_pref("toolkit.startup.last_success", 1741806945);
        user_pref("toolkit.telemetry.cachedClientID", "788d3812-a9c8-42bf-a310-73f1838dcd39");
        user_pref("toolkit.telemetry.pioneer-new-studies-available", true);
        user_pref("userChrome.autohide.navbar", false);
        user_pref("userChrome.autohide.page_action", false);
        user_pref("userChrome.autohide.tab", false);
        user_pref("userChrome.centered.bookmarkbar", false);
        user_pref("userChrome.centered.tab", false);
        user_pref("userChrome.centered.urlbar", false);
        user_pref("userChrome.hidden.bookmarkbar_icon", false);
        user_pref("userChrome.hidden.bookmarkbar_label", false);
        user_pref("userChrome.hidden.sidebar_header", true);
        user_pref("userChrome.hidden.tab_icon", false);
        user_pref("userChrome.hidden.tabbar", false);
        user_pref("userChrome.hidden.urlbar_iconbox", false);
        user_pref("userChrome.icon.disabled", false);
        user_pref("userChrome.icon.panel_full", false);
        user_pref("userChrome.icon.panel_photon", true);
        user_pref("userChrome.rounding.square_tab", true);
        user_pref("userChrome.sidebar.overlap", false);
        user_pref("userChrome.tab.bottom_rounded_corner", false);
        user_pref("userChrome.tab.box_shadow", false);
        user_pref("userChrome.tab.dynamic_separator", false);
        user_pref("userChrome.tab.lepton_like_padding", false);
        user_pref("userChrome.tab.newtab_button_like_tab", false);
        user_pref("userChrome.tab.newtab_button_smaller", true);
        user_pref("userChrome.tab.photon_like_contextline", true);
        user_pref("userChrome.tab.photon_like_padding", true);
        user_pref("userChrome.tab.static_separator", true);
        user_pref("userChrome.tabbar.as_titlebar", false);
        user_pref("userChrome.tabbar.one_liner", true);
        user_pref("userChrome.urlView.always_show_page_actions", false);
        user_pref("userChrome.urlView.go_button_when_typing", false);
        user_pref("userChrome.urlView.move_icon_to_left", false)
      '';
    */
    #};
  };
}

/** THEMES ***/
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("onebar.disable-single-tab", true);
user_pref("onebar.disable-autohide-of-URLbar-icons", true);

/** UI LAYOUT ***/
user_pref("browser.uiCustomization.state", '{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["_testpilot-containers-browser-action","sponsorblocker_ajay_app-browser-action","_e1c38463-46f4-46c7-bc71-1b82125a8fc4_-browser-action","_e58d3966-3d76-4cd9-8552-1582fbc800c1_-browser-action","_ublacklist-browser-action","_eac6e624-97fa-4f28-9d24-c06c9b8aa713_-browser-action","_333f4540-f467-419b-8410-233078ae8813_-browser-action","_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action","_b7f9d2cd-d772-4302-8c3f-eb941af36f76_-browser-action","amptra_keepa_com-browser-action","_2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c_-browser-action","_copyalltabs-browser-action","_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action","ademking_betterviewer-browser-action","cashback_letyshops_letyshops-browser-action","addon_fastforward_team-browser-action","linkgopher_oooninja_com-browser-action","_5f9861fa-6b08-4eff-b035-f448d0f3a2bc_-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","urlbar-container","downloads-button","unified-extensions-button","ublock0_raymondhill_net-browser-action","addon_darkreader_org-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"vertical-tabs":[],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","_e1c38463-46f4-46c7-bc71-1b82125a8fc4_-browser-action","_e58d3966-3d76-4cd9-8552-1582fbc800c1_-browser-action","_ublacklist-browser-action","_eac6e624-97fa-4f28-9d24-c06c9b8aa713_-browser-action","_333f4540-f467-419b-8410-233078ae8813_-browser-action","ublock0_raymondhill_net-browser-action","_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action","_b7f9d2cd-d772-4302-8c3f-eb941af36f76_-browser-action","amptra_keepa_com-browser-action","_2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c_-browser-action","_copyalltabs-browser-action","_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action","ademking_betterviewer-browser-action","cashback_letyshops_letyshops-browser-action","addon_fastforward_team-browser-action","linkgopher_oooninja_com-browser-action","_testpilot-containers-browser-action","addon_darkreader_org-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","sponsorblocker_ajay_app-browser-action","_5f9861fa-6b08-4eff-b035-f448d0f3a2bc_-browser-action"],"dirtyAreaCache":["nav-bar","vertical-tabs","PersonalToolbar","toolbar-menubar","TabsToolbar","unified-extensions-area"],"currentVersion":20,"newElementCount":5}');

/** DISABLE POCKET ***/
user_pref("extensions.pocket.enabled", false);
user_pref("extensions.pocket.onSaveRecs", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.sendToPocket.enabled", false);
user_pref("browser.urlbar.suggest.pocket", false);
user_pref("browser.urlbar.pocket.featureGate", false);
user_pref("extensions.pocket.showHome", false);

/** GENERAL ***/
user_pref("content.notify.interval", 100000);
user_pref("general.autoScroll", true);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false); // Pocket > Sponsored Stories
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false); // Sponsored shortcuts
user_pref("browser.newtabpage.activity-stream.default.sites", ""); // blocks default start sites
user_pref("browser.aboutConfig.showWarning", false); // blocks warning when trying to change about:config
user_pref("browser.startup.page", 1);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");

/** GFX ***/
user_pref("gfx.canvas.accelerated.cache-items", 4096);
user_pref("gfx.canvas.accelerated.cache-size", 512);
user_pref("gfx.content.skia-font-cache-size", 20);

/** DISK CACHE ***/
user_pref("browser.cache.disk.enable", true);

/** MEDIA CACHE ***/
user_pref("media.memory_cache_max_size", 65536);
user_pref("media.cache_readahead_limit", 7200);
user_pref("media.cache_resume_threshold", 3600);

/** IMAGE CACHE ***/
user_pref("image.mem.decode_bytes_at_a_time", 32768);

/** NETWORK ***/
user_pref("network.http.max-connections", 1800);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.max-urgent-start-excessive-connections-per-host", 5);
user_pref("network.http.pacing.requests.enabled", false);
user_pref("network.dnsCacheExpiration", 3600);
user_pref("network.ssl_tokens_cache_capacity", 10240);

/** SPECULATIVE LOADING ***/
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);



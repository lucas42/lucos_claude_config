# SRE Ops Checks Tracking

## Monthly Check Last Run Dates

ci_status: 2026-03-14
info_endpoint_quality: 2026-03-14
external_deps: 2026-03-14

## Container Log Review History

lucos_comhra_agent: 2026-03-20
lucos_comhra_llm: 2026-03-20
lucos_schedule_tracker: 2026-03-19
lucos_media_weightings: 2026-03-18
lucos_photos_worker: 2026-03-18
lucos_arachne_explore: 2026-03-15
lucos_arachne_web: 2026-03-16
lucos_backups: 2026-04-03
lucos_authentication: 2026-04-03
lucos_repos_app: 2026-03-16
lucos_dns_bind: 2026-04-03
lucos_loganne: 2026-04-03
lucos_configy: 2026-04-03
lucos_contacts_app: 2026-03-17
lucos_contacts_db: 2026-03-16
lucos_contacts_googlesync_import: 2026-03-16
lucos_contacts_web: 2026-03-17
lucos_creds: 2026-03-20
lucos_creds_configy_sync: 2026-03-17
lucos_creds_ui: 2026-03-17
lucos_dns_sync: 2026-03-19
lucos_eolas_app: 2026-03-17
lucos_eolas_db: 2026-03-18
lucos_eolas_web: 2026-03-18
lucos_locations_mosquitto: 2026-04-02
lucos_locations_otfrontend: 2026-04-02
lucos_locations_otrecorder: 2026-04-02
lucos_mail_smtp: 2026-03-19
lucos_photos_api: 2026-04-02
lucos_arachne_ingestor: 2026-03-19
lucos_arachne_search: 2026-03-19
lucos_arachne_triplestore: 2026-03-19
lucos_mail_docs: 2026-03-21
lucos_photos_postgres: 2026-03-15
lucos_photos_redis: 2026-03-21
lucos_scenes: 2026-03-15
lukeblaney_co_uk: 2026-03-21
lucos_media_manager: 2026-03-21
lucos_media_metadata_api: 2026-03-21
lucos_monitoring: 2026-03-18
lucos_media_seinn: 2026-03-15
tfluke: 2026-03-15
lucos_media_metadata_api_exporter: 2026-03-19
lucos_media_metadata_manager: 2026-03-20
lucos_notes: 2026-03-19
lucos_root: 2026-03-20
lucos_router: 2026-03-19
semweb: 2026-03-20
lucos_time: 2026-03-16
lucos_arachne_mcp: 2026-03-19
lukeblaney_blog: 2026-04-02

## SSH Hostname Note

Always use `avalon.s.l42.eu` (not the alias `avalon`) for SSH. The SSH config uses `*.s.l42.eu` pattern. `ssh avalon` fails with host key verification error.

## Notes

- ops-checks.md was previously corrupted (null bytes). Rewritten 2026-03-06.
- Container names corrected 2026-04-02: authentication→lucos_authentication, bind→lucos_dns_bind, loganne→lucos_loganne, media_manager→lucos_media_manager, media_metadata_api→lucos_media_metadata_api, media_metadata_api_exporter→lucos_media_metadata_api_exporter, media_metadata_manager→lucos_media_metadata_manager, monitoring→lucos_monitoring, notes→lucos_notes, root→lucos_root, router→lucos_router, seinn→lucos_media_seinn, time→lucos_time, lukeblaney.co.uk→lukeblaney_co_uk. New container lukeblaney_blog added.
- Container list as of 2026-04-02 (avalon): lucos_authentication, lucos_dns_bind, lucos_loganne, lucos_arachne_explore, lucos_arachne_ingestor, lucos_arachne_search, lucos_arachne_triplestore, lucos_arachne_web, lucos_backups, lucos_comhra_agent, lucos_comhra_llm, lucos_configy, lucos_contacts_app, lucos_contacts_db, lucos_contacts_googlesync_import, lucos_contacts_web, lucos_creds, lucos_creds_configy_sync, lucos_creds_ui, lucos_dns_sync, lucos_eolas_app, lucos_eolas_db, lucos_eolas_web, lucos_locations_mosquitto, lucos_locations_otfrontend, lucos_locations_otrecorder, lucos_mail_docs, lucos_mail_smtp, lucos_media_weightings, lucos_photos_api, lucos_photos_postgres, lucos_photos_redis, lucos_photos_worker, lucos_repos_app, lucos_scenes, lucos_schedule_tracker, lukeblaney_co_uk, lukeblaney_blog, lucos_media_manager, lucos_media_metadata_api, lucos_media_metadata_api_exporter, lucos_media_metadata_manager, lucos_monitoring, lucos_notes, lucos_root, lucos_router, lucos_media_seinn, semweb, tfluke, lucos_time, lucos_arachne_mcp

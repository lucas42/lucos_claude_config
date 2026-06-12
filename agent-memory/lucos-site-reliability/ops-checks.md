# SRE Ops Checks Tracking

## Monthly Check Last Run Dates

ci_status: 2026-06-03
info_endpoint_quality: 2026-06-03
external_deps: 2026-06-03

## Container Log Review History

lucos_schedule_tracker: 2026-06-03
lucos_media_weightings: 2026-06-01
lucos_photos_worker: 2026-06-12
lucos_arachne_explore: 2026-06-12
lucos_arachne_web: 2026-05-29
lucos_backups: 2026-06-06
lucos_authentication: 2026-06-08
lucos_repos_app: 2026-05-29
lucos_dns_bind: 2026-06-11
lucos_loganne: 2026-06-09
lucos_configy: 2026-06-09
lucos_contacts_app: 2026-05-29
lucos_contacts_db: 2026-05-29
lucos_contacts_googlesync_import: 2026-05-31
lucos_contacts_web: 2026-05-31
lucos_creds: 2026-06-04
lucos_creds_configy_sync: 2026-05-31
lucos_creds_ui: 2026-05-31
lucos_dns_sync: 2026-06-01
lucos_eolas_app: 2026-05-29
lucos_eolas_db: 2026-06-01
lucos_eolas_web: 2026-06-01
lucos_locations_mosquitto: 2026-06-08
lucos_locations_otfrontend: 2026-06-09
lucos_locations_otrecorder: 2026-06-09
lucos_mail_smtp: 2026-06-02
lucos_photos_api: 2026-06-08
lucos_arachne_ingestor: 2026-06-06
lucos_arachne_search: 2026-06-03
lucos_arachne_triplestore: 2026-06-02
lucos_mail_docs: 2026-06-06
lucos_photos_postgres: 2026-06-11
lucos_photos_redis: 2026-06-06
lucos_scenes: 2026-06-11
lukeblaney_co_uk: 2026-06-09
lucos_media_manager: 2026-06-03
lucos_media_metadata_api: 2026-06-08
lucos_monitoring: 2026-06-02
lucos_media_seinn: 2026-06-12
tfluke: 2026-06-12
lucos_media_metadata_api_exporter: 2026-06-03
lucos_media_metadata_manager: 2026-06-04
lucos_notes: 2026-06-04
lucos_root: 2026-06-06
lucos_router: 2026-06-02
semweb: 2026-06-06
lucos_time: 2026-06-11
lucos_aithne: 2026-06-11
lucos_arachne_mcp: 2026-06-04
lukeblaney_blog: 2026-06-06
lucos_docker_health_app: 2026-06-03

lucos_docker_mirror_web: 2026-06-12
lucos_docker_mirror_registry: 2026-05-31
lucos_docker_mirror_info: 2026-06-01
lucos_firewall: 2026-06-02

## SSH Hostname Note

Always use `avalon.s.l42.eu` (not the alias `avalon`) for SSH. The SSH config uses `*.s.l42.eu` pattern. `ssh avalon` fails with host key verification error.

## Notes

- ops-checks.md was previously corrupted (null bytes). Rewritten 2026-03-06.
- Container names corrected 2026-04-02: authentication→lucos_authentication, bind→lucos_dns_bind, loganne→lucos_loganne, media_manager→lucos_media_manager, media_metadata_api→lucos_media_metadata_api, media_metadata_api_exporter→lucos_media_metadata_api_exporter, media_metadata_manager→lucos_media_metadata_manager, monitoring→lucos_monitoring, notes→lucos_notes, root→lucos_root, router→lucos_router, seinn→lucos_media_seinn, time→lucos_time, lukeblaney.co.uk→lukeblaney_co_uk. New container lukeblaney_blog added.
- Container list as of 2026-05-25 (avalon, 52 containers): lucos_arachne_explore, lucos_arachne_ingestor, lucos_arachne_mcp, lucos_arachne_search, lucos_arachne_triplestore, lucos_arachne_web, lucos_authentication, lucos_backups, lucos_configy, lucos_contacts_app, lucos_contacts_db, lucos_contacts_googlesync_import, lucos_contacts_web, lucos_creds, lucos_creds_configy_sync, lucos_creds_ui, lucos_dns_bind, lucos_dns_sync, lucos_docker_health_app, lucos_docker_mirror_info, lucos_docker_mirror_registry, lucos_docker_mirror_web, lucos_eolas_app, lucos_eolas_db, lucos_eolas_web, lucos_locations_mosquitto, lucos_locations_otfrontend, lucos_locations_otrecorder, lucos_loganne, lucos_mail_docs, lucos_mail_smtp, lucos_media_manager, lucos_media_metadata_api, lucos_media_metadata_api_exporter, lucos_media_metadata_manager, lucos_media_seinn, lucos_media_weightings, lucos_monitoring, lucos_notes, lucos_photos_api, lucos_photos_postgres, lucos_photos_redis, lucos_photos_worker, lucos_repos_app, lucos_root, lucos_router, lucos_scenes, lucos_schedule_tracker, lucos_time, lukeblaney_blog, lukeblaney_co_uk, semweb, tfluke
- 2026-05-25: lucos_comhra_agent and lucos_comhra_llm decommissioned (no longer present on avalon; loganne system map no longer includes lucos_comhra). UNRECOVERED monitoring alerts for those systems are stale window artefacts.
- 2026-06-03 Check 6 (/_info): `dns.l42.eu/_info` returns empty body but `lucos_dns` is healthy in monitoring — monitoring polls lucos_dns's /_info from a different endpoint than the public dns.l42.eu host. NOT a defect; don't re-chase. Six services omit Tier-1 checks/metrics (configy, scenes, static_media, private, semweb, lukeblaney.co.uk) — tracked in lucas42/lucos#212 (P3 hygiene, zero runtime impact). `title` is Tier-2 (optional) — missing-title is never a defect.
- 2026-06-03 Check 5: deriving service domains for /_info checks — use configy `config/systems.yaml` (31 mappings); `installation/repositories` for the repo list (NOT orgs/lucas42 — 404).
- 2026-06-11: lucos_aithne is a NEW service (replacing lucos_authentication, tracking lucos_aithne#12) under heavy active development (v1.1.x→v1.12.0, 30+ deploys 06-09→06-11). Its 06-09→06-10 flaps (fetch-info/tls/db) = deploy churn + new-service cert latency (lucos_router#95). Its new volume `lucos_aithne_credential_store` appearing on avalon before being declared in configy caused the backups volume-config/volume-host flaps 06-09 23:08-23:53 (same root cause; now declared with recreate_effort: considerable, green). Don't re-investigate these as separate incidents while aithne is being stood up. Bootstrap warning (BOOTSTRAP_ADMIN_CONTACT_ID still set post-enrolment) is lucas42's WIP — he set it.

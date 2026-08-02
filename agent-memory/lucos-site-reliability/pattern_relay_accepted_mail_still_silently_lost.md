---
name: pattern-relay-accepted-mail-still-silently-lost
description: "A 2xx from our own postfix relay is NOT delivery — Gmail can bounce afterwards and quarantine the DSN, so the sender logs success while the mail is gone; check lucos_mail_smtp per queue-id, not the app's logs"
metadata:
  type: reference
---

When asking "did that notification email actually arrive?", the sending app's logs are worthless. Our services hand mail to `lucos_mail_smtp` (postfix on avalon), postfix assigns a queue-id and returns 2xx **immediately**, and only *then* relays to Gmail. If Gmail rejects at that point, the app already logged success.

The bounce doesn't help either: postfix sends a DSN to the envelope sender, and Gmail has been accepting those with `250 2.0.0 OK DMARC:Quarantine` — i.e. straight to spam. Net result: **mail vanishes with no trace in the app, no trace in monitoring, and a "delivered" DSN nobody reads.**

**How to check properly** — parse the postfix log per queue-id, not line-by-line (one message spans `smtpd`/`cleanup`/`qmgr`/`smtp`/`bounce` lines sharing a hex queue-id):

```bash
ssh avalon.s.l42.eu "docker logs --since <date> lucos_mail_smtp 2>&1 \
  | grep -E 'message-id=|status=|from=<'" > /tmp/mail.txt
# then group by /\b([0-9A-F]{8,}):/ in python and tally status= per queue-id
```

Useful one-liners: `grep -oE 'status=(sent|bounced|deferred|expired)' | sort | uniq -c` for the delivery mix, and `grep -c 'message-id=<>'` for RFC-5322-noncompliant senders.

**Known trap — `message-id=<>` means the *client* omitted the header.** `always_add_missing_headers = no` (postfix default, confirmed on our relay), so postfix does not backfill one. Proof of which side is at fault: postfix's own generated bounces *do* carry `message-id=<YYYYMMDDHHMMSS.QUEUEID@avalon.s.l42.eu>`.

**Volume of "err-ish" lines in this container is meaningless** — ~108k of 944k lines over 3 weeks are external SASL/TLS brute-force noise. Go straight to `status=` counts and let the ratio tell you (466 sent / 2 bounced was the real signal in 944k lines).

First found 2026-08-02 ops checks → lucas42/lucos_monitoring#294: every `monitoring@l42.eu` alert email lacks `Message-ID`, Gmail bounced 2 of 466, and both were real `lucos_docker_health` notifications inside the 2026-07-19 configy_sync incident window. Same file also flags `Date:` being emitted as RFC 3339 rather than RFC 5322.

Related: [[feedback_silent_fallbacks_are_a_security_risk]] — same family, a path that fails without saying so.

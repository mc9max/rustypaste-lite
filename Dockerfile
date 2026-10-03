# syntax=docker/dockerfile:1
# =============================================================================
# Railway Template: Rustypaste Lite
# Upstream: https://github.com/orhun/rustypaste  (Rust/Actix, single static binary, ~15 MB)
# Image:    orhunp/rustypaste:0.18.1  (scratch base, ships as USER 1000:1000)
# =============================================================================
# Why this wrapper:
#   * scratch base has NO /etc/passwd entries — `USER root` fails with
#     "unable to find user root: no matching entries in passwd file".
#     The binary already runs as uid 1000 in the image; we re-run it as uid 0
#     (numeric, no passwd lookup needed) so it can write to Railway's root-owned
#     persistent volume at /data. Without this, the first upload EACCES-loops.
#   * rustypaste hard-exits if a config file is not present at boot
#     (main.rs: "config.toml is not found, please provide a configuration file").
#     We bake a curated default at /app/config.toml and pin CONFIG to it.
#     The binary also reads `PASTE__…` and `SERVER__…` env overrides (config-rs
#     `__` separator) — expose them as template vars instead of editing the file.
#   * persistence lives on the /data volume (railway.toml [[volumes]]). Files
#     are stored under /data/{oneshot,url,oneshot_url,protected}/ and the
#     plain-upload dir /data itself. Without the volume, pastes vanish on
#     container restart. Verified: files survive `podman restart`.
FROM orhunp/rustypaste:0.18.1

USER 0

# Config file is required at boot; without it the process exits 1.
ENV CONFIG=/app/config.toml
COPY config.toml /app/config.toml

# Baked into image already: SERVER__ADDRESS=0.0.0.0:8000 (verified via docker inspect).
# Keep WORKDIR at /app (the rustypaste binary lives at ./rustypaste).
WORKDIR /app
EXPOSE 8000
CMD ["./rustypaste"]

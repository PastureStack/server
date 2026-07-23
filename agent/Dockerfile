FROM ghcr.io/pasturestack/node-agent-base:v0.3.5@sha256:250c8121a5e7f3291947a352aa8642c6e51e474359eea196ea0ab2e41e0ba3ec
COPY register.py resolve_url.py run.sh /
COPY loglevel /usr/bin/loglevel
ENTRYPOINT ["/run.sh"]
LABEL "io.rancher.container.system"="rancher-agent" \
      io.pasturestack.container.system="node-agent" \
      org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack node-agent compatibility image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v1.2.30"
RUN test -s /usr/bin/share-mnt && \
    chmod +x /run.sh /register.py /resolve_url.py /usr/bin/share-mnt /usr/bin/loglevel
ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.30

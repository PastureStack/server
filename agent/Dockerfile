FROM ghcr.io/pasturestack/node-agent-base:v0.3.6@sha256:1179c549a501551941c3435969ecbd5d6bacc1d9e327895c3f75b9019b461ec9
ARG VCS_REF
COPY control_plane_url.py register.py resolve_url.py run.sh /
COPY loglevel /usr/bin/loglevel
ENTRYPOINT ["/run.sh"]
LABEL "io.rancher.container.system"="rancher-agent" \
      io.pasturestack.container.system="node-agent" \
      org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack node-agent compatibility image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v1.2.32" \
      org.opencontainers.image.revision=$VCS_REF
RUN test -s /usr/bin/share-mnt && \
    chmod +x /run.sh /register.py /resolve_url.py /usr/bin/share-mnt /usr/bin/loglevel && \
    chmod 0644 /control_plane_url.py
ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.32

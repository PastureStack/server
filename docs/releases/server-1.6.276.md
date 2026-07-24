# PastureStack Server v1.6.276

PastureStack Server `v1.6.276` refreshes the Web Console with a corrected Taiwan Traditional Chinese service label and a regression guard for stray middle-dot punctuation.

## Included runtime

- Orchestration Engine `v0.183.269`
- Web Console compatibility artifact `1.6.56`, built from `PastureStack/web-console` commit `9fa1a8712f7b2d72a83268376d4e6fcfdd46efaf`
- API Explorer `1.1.14`
- Node Agent `v1.2.31`
- Load Balancer Service `v0.9.25`
- Catalog commit `91f5910a44cb181051be2adc4c14f0e6ec7842ef`

The Web Console package version is `1.6.56-pasturestack.4`. Its Taiwan Traditional Chinese locale renders the service type as `服務` without an added punctuation mark. The localization gate rejects `·`, `•`, `・`, and `･` if they are introduced into that locale.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.276
```

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.

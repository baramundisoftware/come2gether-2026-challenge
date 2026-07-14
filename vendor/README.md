# vendor/

Vendored build inputs so `come2gether-2026-challenge` can build its images
**without** any sibling repositories.

## n8n-nodes-baramundi-management-suite-0.9.1.tgz

The baramundi n8n Connector, packed from source.

- **Source repo:** `n8n-bConnect-connector` (`package.json` version `0.9.1`)
- **Produced with:** `npm run build && npm pack`
- **Used by:** the n8n-demo image build (installed as an n8n community node)

### Refreshing to a new version

```bash
cd ../n8n-bConnect-connector      # the connector source repo
npm run build && npm pack
cp n8n-nodes-baramundi-management-suite-<version>.tgz \
   ../come2gether-2026-challenge/vendor/
# then update the reference in the n8n image Dockerfile/build to the new version
```

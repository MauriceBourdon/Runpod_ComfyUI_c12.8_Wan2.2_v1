# Drop-in V4.1.4c Auto-REF (patched deps)
- Dockerfile auto main/master + retries + tarball
- Entrypoint gère Jupyter, nodes, workflows, et modèles
- Deps python/OS patchées pour éviter les erreurs de build (opencv, sentencepiece, etc.)

Build:
docker buildx build -t test/comfy:dropin --platform linux/amd64 . --no-cache

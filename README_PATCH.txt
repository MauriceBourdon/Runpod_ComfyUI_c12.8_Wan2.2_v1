# Patch Dockerfile - Robust ComfyUI Clone

Ce patch corrige l'erreur `exit code 128` lors du `git clone`.

## Fonctionnement
- 3 tentatives de `git clone` avec pause.
- Si échec, fallback vers le tarball GitHub.

## Utilisation
1. Remplace ton `Dockerfile` par celui-ci (ou copie le bloc patché).
2. Commit & push :
   git add Dockerfile
   git commit -m "patch: robust ComfyUI clone (retry + tarball fallback)"
   git push origin main

3. Rebuild ton image.

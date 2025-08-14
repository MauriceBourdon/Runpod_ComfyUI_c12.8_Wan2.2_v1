# download_models.py
import sys, os
from huggingface_hub import hf_hub_download

def main():
    if len(sys.argv) < 3:
        print("Usage: download_models.py MODELS_MANIFEST DEST_DIR [HF_TOKEN]")
        return
    manifest, dest_root = sys.argv[1], sys.argv[2]
    token = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None

    os.makedirs(dest_root, exist_ok=True)

    with open(manifest, "r", encoding="utf-8") as f:
        for line in f:
            line=line.strip()
            if not line or line.startswith("#"): continue
            try:
                repo, path, sub = line.split("|", 3)
            except ValueError:
                print(f"[models] skip invalid line: {line}")
                continue

            dst_dir = os.path.join(dest_root, sub)
            os.makedirs(dst_dir, exist_ok=True)
            try:
                fp = hf_hub_download(repo_id=repo, filename=path, token=token, local_dir=dst_dir, local_dir_use_symlinks=False)
                print(f"[models] ok: {repo}|{path} -> {fp}")
            except Exception as e:
                print(f"[models] fail: {repo}|{path} -> {e}")

if __name__ == "__main__":
    main()

import os
import base64
import sys

# Try importing requested modules, and install them if missing
try:
    import requests
    from nacl import encoding, public
except ImportError:
    print("Installing required python libraries (requests, pynacl)...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "pynacl"])
    import requests
    from nacl import encoding, public

# Load variables from .env if it exists
def load_env():
    env_vars = {}
    if os.path.exists(".env"):
        with open(".env", "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        env_vars[parts[0].strip()] = parts[1].strip()
    return env_vars

env = load_env()

# Configuration
REPO = "ShabanEjupi1/SpaceRent"
GITHUB_TOKEN = env.get("GITHUB_ACCESS_TOKEN") or os.environ.get("GITHUB_ACCESS_TOKEN") or os.environ.get("GITHUB_TOKEN")

if not GITHUB_TOKEN:
    print("Error: GITHUB_ACCESS_TOKEN not found in .env or environment variables.")
    sys.exit(1)

# List of secrets we want to load from .env or environment
SECRET_KEYS = [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "PAYPAL_CLIENT_ID",
    "PAYPAL_CLIENT_SECRET",
    "PAYPAL_API_BASE",
    "SMTP_USER",
    "SMTP_PASS"
]

SECRETS = {}
for key in SECRET_KEYS:
    val = env.get(key) or os.environ.get(key)
    if not val:
        if key == "SUPABASE_URL":
            val = "https://rrjndmbihxblkwzwmhoi.supabase.co"
        elif key == "SUPABASE_ANON_KEY":
            val = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJyam5kbWJpaHhibGt3endtaG9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MzE2NDUsImV4cCI6MjA5NTEwNzY0NX0.-ZmVh41piYGFr93xaf4ks72c3fjC8gbRQdPm1l4Yn_Y"
        else:
            print(f"Error: Required secret {key} not found in .env or environment.")
            sys.exit(1)
    SECRETS[key] = val

def encrypt(public_key: str, secret_value: str) -> str:
    """Encrypt a Unicode string using the public key."""
    pub_key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder)
    sealed_box = public.SealedBox(pub_key)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")

def main():
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    # 1. Get repo public key
    print(f"Fetching public key for repository {REPO}...")
    url = f"https://api.github.com/repos/{REPO}/actions/secrets/public-key"
    r = requests.get(url, headers=headers)
    if r.status_code != 200:
        print(f"Error fetching public key (Status {r.status_code}): {r.text}")
        return

    key_data = r.json()
    key_id = key_data["key_id"]
    public_key = key_data["key"]
    print(f"Successfully fetched key: {key_id}")

    # 2. Encrypt and upload secrets
    for name, value in SECRETS.items():
        print(f"Encrypting and uploading secret {name}...")
        encrypted_val = encrypt(public_key, value)
        
        secret_url = f"https://api.github.com/repos/{REPO}/actions/secrets/{name}"
        data = {
            "encrypted_value": encrypted_val,
            "key_id": key_id
        }
        
        put_r = requests.put(secret_url, json=data, headers=headers)
        if put_r.status_code in (201, 204):
            print(f"Successfully set secret {name}!")
        else:
            print(f"Failed to set secret {name} (Status {put_r.status_code}): {put_r.text}")

if __name__ == "__main__":
    main()

import requests
import json

BASE_URL = "https://domainabus-production.up.railway.app"

# Test GET /tes-api
print("Testing GET /tes-api...")
response = requests.get(f"{BASE_URL}/tes-api")
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}\n")

# Test POST /ai-predict
print("Testing POST /ai-predict...")
payload = {
    "wave_number": 1,
    "weapon_telemetry": {
        "beta_lactam_shots": 10,
        "macrolide_pulse_shots": 5,
        "cipro_blast_shots": 3
    },
    "survived_pathogens": []
}

response = requests.post(
    f"{BASE_URL}/ai-predict",
    json=payload,
    headers={"Content-Type": "application/json"}
)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
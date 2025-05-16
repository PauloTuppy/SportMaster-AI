import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Firebase
cred_path = os.getenv("FIREBASE_CREDENTIALS", "service-account-key.json")
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

# Create test fighter document
fighter_ref = db.collection("fighters").document("test_fighter_001")
fighter_ref.set({
    "name": "Test Fighter",
    "weight_class": "Lightweight",
    "height_cm": 175,
    "reach_cm": 180,
    "stance": "Orthodox",
    "age": 29,
    "record": {
        "wins": 15,
        "losses": 3,
        "draws": 0
    },
    "last_fight_date": "2023-10-15"
})

print("Firestore collections and test data created successfully!")

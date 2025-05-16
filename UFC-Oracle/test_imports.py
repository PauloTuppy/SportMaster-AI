try:
    import firebase_admin
    from google.cloud import firestore
    from dotenv import load_dotenv
    print("All required packages are installed successfully!")
except ImportError as e:
    print(f"ImportError: {e}")

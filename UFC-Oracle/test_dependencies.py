try:
    from google.cloud import bigquery
    from dotenv import load_dotenv
    import firebase_admin
    print("All required packages are installed successfully!")
except ImportError as e:
    print(f"ImportError: {e}")
    print("Please install missing packages with:")
    print("pip install google-cloud-bigquery python-dotenv firebase-admin")

from crawler import crawl_gnu_cse

if __name__ == "__main__":
    print("🚀 Starting full export to Firebase...")
    try:
        crawl_gnu_cse(mode='all', headless=True)
        print("✅ Export completed successfully.")
    except Exception as e:
        print(f"❌ Export failed: {e}")

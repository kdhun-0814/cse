from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import time

options = webdriver.ChromeOptions()
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=options)

try:
    print("Connecting to list page...")
    driver.get("https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753")
    time.sleep(2)
    
    print("Attempting to go to page 2 via goPaging(2)...")
    driver.execute_script("goPaging(2)")
    time.sleep(2)
    
    # Check if URL changed or content changed
    # Often URL parameter changes or the content updates. 
    # Let's check the first notice title or just success of execution.
    print("Script executed. Checking execution status...")
    current_url = driver.current_url
    print(f"Current URL: {current_url}")
    
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    active_page = soup.select_one('strong.bbs_pge_num')
    if active_page:
        print(f"Active Page: {active_page.get_text(strip=True)}")
    else:
        print("Could not find active page element.")
        
    print("✅ Pagination script executed without crashing.")

except Exception as e:
    print(f"❌ Error during pagination test: {e}")

finally:
    driver.quit()

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import time
import os
import re

# Mock constants
START_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"
BASE_HOST = "https://www.gnu.ac.kr"

def test_scrape():
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    print("Go to list...")
    driver.get(START_URL)
    time.sleep(2)
    
    # Find first notice
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    rows = soup.select('tbody tr')
    target_link = None
    target_title = ""
    
    for r in rows:
        t = r.select_one('a.nttInfoBtn')
        if t:
            target_link = t['data-id']
            target_title = t.get_text(strip=True)
            print(f"Found notice: {target_title}")
            break
            
    if not target_link:
        print("No notice found")
        driver.quit()
        return

    full_url = f"{BASE_HOST}/cse/na/ntt/selectNttInfo.do?mi=17093&bbsId=4753&nttSn={target_link}"
    print(f"Go to detail: {full_url}")
    
    driver.get(full_url)
    time.sleep(2)
    
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    
    # Logic from crawler.py
    content_html = ""
    metadata = {'author': '학과사무실', 'views': 0, 'date': ''} 
    
    # 1. Main Content
    cont_row = soup.select_one('tr.cont')
    if cont_row:
         content_td = cont_row.select_one('td')
         if content_td:
             for img in content_td.select('img'):
                 src = img.get('src')
                 if src and src.startswith('/'):
                     img['src'] = BASE_HOST + src
             content_html = content_td.decode_contents()

    try:
        # Metadata Extraction
        author_tag = soup.find(string=re.compile("작성자"))
        if author_tag:
             author_td = author_tag.find_parent('th').find_next_sibling('td')
             if author_td:
                 metadata['author'] = author_td.get_text(strip=True)
        
        views_tag = soup.find(string=re.compile("조회수|조회"))
        if views_tag:
             views_td = views_tag.find_parent('th').find_next_sibling('td')
             if views_td:
                 try:
                     metadata['views'] = int(re.sub(r'[^0-9]', '', views_td.get_text()))
                 except: pass
        
        date_tag = soup.find(string=re.compile("등록일|작성일"))
        if date_tag:
             date_td = date_tag.find_parent('th').find_next_sibling('td')
             if date_td:
                 metadata['date'] = date_td.get_text(strip=True)
    except Exception as e:
        print(f"Meta parse error: {e}")

    content_text = ""
    if content_html:
        text_soup = BeautifulSoup(content_html, 'html.parser')
        content_text = text_soup.get_text(separator=' ', strip=True)[:100] + "..."

    print("\n--- [Extraction Result] ---")
    print(f"Title: {target_title}")
    print(f"Author: {metadata['author']}")
    print(f"Date: {metadata['date']}")
    print(f"Views: {metadata['views']}")
    print(f"Content Preview: {content_text}")
    print("---------------------------")
        
    driver.quit()

if __name__ == "__main__":
    test_scrape()

import requests
from bs4 import BeautifulSoup
import sys

url = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"
print(f"Connecting to {url}...")
try:
    resp = requests.get(url, timeout=10)
    print(f"Status: {resp.status_code}")
    print(f"Length: {len(resp.text)}")
    
    soup = BeautifulSoup(resp.text, 'html.parser')
    
    # pagination class might be different. Search for 'pageIndex' in href
    links = soup.find_all('a', href=True)
    count = 0
    for a in links:
        if 'pageIndex' in a['href'] or 'fn_egov_select_linkPage' in str(a.get('onclick', '')):
            print(f"Pagination Candidate: {a.get_text().strip()} | Href: {a['href']} | OnClick: {a.get('onclick')}")
            count += 1
            if count > 5: break
            
    if count == 0:
        print("No obvious pagination links found via simple search.")
        # Print all divs with class containing 'page' or 'paging'
        divs = soup.find_all('div', class_=lambda x: x and ('page' in x or 'paging' in x))
        for d in divs:
            print(f"Div Class: {d['class']}")
            print(d.prettify()[:200])

except Exception as e:
    print(f"Error: {e}")

from bs4 import BeautifulSoup

with open('page_source.html', 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f, 'html.parser')

print("--- Searching for pagination classes ---")
# Find any div with 'page' or 'paging' in class
divs = soup.find_all('div', class_=lambda c: c and ('page' in c or 'paging' in c))
for div in divs:
    print(f"Div Class: {div['class']}")
    print(div.prettify()[:1000])
    print("-" * 50)

print("\n--- Searching for links with page logic ---")
links = soup.select("a")
count = 0
for a in links:
    href = a.get('href', '')
    onclick = a.get('onclick', '')
    if 'page' in href.lower() or 'page' in onclick.lower():
        print(f"Text: {a.get_text().strip()} | Href: {href} | OnClick: {onclick}")
        count += 1
        if count > 10: break

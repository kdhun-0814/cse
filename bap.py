import requests
from bs4 import BeautifulSoup
import json
import datetime
import pytz


url = "https://www.gnu.ac.kr/main/ad/fm/foodmenu/selectFoodMenuView.do?mi=1341"

headers = {
    "Authorization": "",
    "Content-Type": "application/x-www-form-urlencoded",
    "Cookie": "1:138_1=1:138_1_to_10:6e22; 1:13b_0=1:13b_0_to_10:6e8e; JSESSIONID=0200F392B15A8B5DFCA98EBCDA16B51A.worker1"
}
days=0
schDt = (datetime.datetime.now(tz=pytz.timezone("Asia/Seoul"))+datetime.timedelta(days=days)).strftime("%Y-%m-%d")

jungang_data = {
    "restSeq": "5",
    "schDt": schDt,
    "schSysId": "main"
}

gyomunsen_data = {
    "restSeq": "63",
    "schDt": schDt,
    "schSysId": "main"
}

gyojikwon_data = {
    "restSeq": "4",
    "schDt": schDt,
    "schSysId": "main"
}

chillam_data = {
    "restSeq": "8",
    "schDt": schDt,
    "schSysId": "cdorm"
}

for data in [jungang_data, gyomunsen_data, gyojikwon_data, chillam_data]:
    if data["restSeq"] == "5":
        print("\n[중앙식당]")
    elif data["restSeq"] == "63":
        print("\n[교문센1층]")
    elif data["restSeq"] == "8":
        print("\n[칠암]")
    elif data["restSeq"] == "4":
        print("\n[교직원식당]")
    res = requests.post(url, headers=headers, data=data)
    soup = BeautifulSoup(res.text, "html.parser")

    # <div class="calr_top"> 부분 찾기
    calr_top_div = soup.find("div", class_="BD_table scroll_gr main")


    # 헤더 (요일 추출)
    headers_ = [th.get_text(" ", strip=True) for th in calr_top_div.find("thead").find_all("th")]


    # 각 row
    for tr in calr_top_div.find("tbody").find_all("tr"):
        row_header = tr.find("th").get_text(" ", strip=True)  # ex: "조식", "1식당 중식"
        if "고정메뉴" in row_header or "알레르기" in row_header or "더진국" in row_header:
            continue

        cells = tr.find_all("td")

        for idx, td in enumerate(cells, start=1):  # headers[0]은 '구분'
            day = headers_[idx]
            text = td.get_text("\n", strip=True)

            if day.split()[-1] != schDt:
                continue

            print(text if text else None)
        print("")

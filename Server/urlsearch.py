import pandas as pd

# 讀取數據
df = pd.read_csv("./data/NPA_WEBURL.csv", skiprows=[1])
url_dataset = set(df['WEBURL'])

def select_url(url):
    if not url.strip():
        return "輸入為空!"
    elif url in url_dataset:
        return f"{url} 可能為詐騙網址!!!"
    else:
        return f"{url} 不是詐騙網址"
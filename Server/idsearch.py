import pandas as pd

# 讀取數據
df = pd.read_csv("./data/NPA_LineID.csv")
line_id_dataset = set(df['帳號'])

def select_id(line_id):
    if not line_id.strip():
        return "輸入為空!"
    elif line_id in line_id_dataset:
        return f"{line_id} 可能為詐騙 ID!!!"
    else:
        return f"{line_id} 不是詐騙 ID"
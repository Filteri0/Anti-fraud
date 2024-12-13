# **反詐圖文掃描機**

## **專題介紹**
「反詐圖文掃描機」是一款基於人工智慧 (AI) 與自然語言處理 (NLP) 的跨平台應用程式，旨在透過圖文辨識和詐騙檢測功能，有效提升用戶防範詐騙的能力。

### **核心功能**
1. **圖文詐騙辨識**  
   利用 OCR 技術識別圖片文字，結合 BERT 模型進行詐騙訊息分類。
2. **詐騙 Line ID 查詢**  
   查詢目標 Line ID 是否曾被通報為詐騙。
3. **詐騙網址查詢**  
   檢測輸入網址是否為釣魚或詐騙網站。

### **技術架構**
- **前端技術**  
  - iOS：Swift (使用 Vision Framework 進行 OCR)
  - Android：Kotlin (使用 Google ML Kit OCR 模組)
  - Web：Python Flask (使用 Tesseract OCR)
- **後端技術**  
  - Flask 
  - Bert


## **團隊成員**
- 李睿凱  
- 林逸倫  
- 王紹丞  
- 林幸縈  

## **如何運行專案**
### **環境需求**
- Python 版本 >= 3.8

### **執行步驟**
1. Clone 本專案：
   ```bash
   git clone https://github.com/Filteri0/anti-fraud.git
   ```
2. 進入後端目錄並安裝依賴：
   ```bash
   cd Server
   pip install -r requirements.txt
   ```
3. 啟動 Flask 伺服器 + Http server：
   ```bash
   python main.py
   ```
4. 在前端應用程式中測試功能。


## **參考資料**
以下為專題開發過程中參考的資料與工具：
- **BERT 相關資料**  
  - Lee, M. (2019). 進擊的 BERT：NLP 界的巨人之力與遷移學習  
    [文章連結](https://leemeng.tw/attack_on_bert_transfer_learning_in_nlp.html)  
  - 李宏毅. (2019). ELMO, BERT, GPT [影片]  
    [影片連結](https://www.youtube.com/watch?v=UYPa347-DdE)  
  - HuggingFace. (n.d.). BERT-Base, Chinese  
    [模型連結](https://huggingface.co/google-bert/bert-base-chinese)

- **OCR 與技術支援**  
  - Tesseract OCR 官方倉庫  
    [GitHub 連結](https://github.com/tesseract-ocr/tesseract)  
  - 凱稱研究室：Tesseract-OCR 使用心得  
    [文章連結](https://kaichenlab.medium.com/%E5%AF%A6%E7%94%A8%E5%BF%83%E5%BE%97-tesseract-ocr-eef4fcd425f0)

- **其他技術與框架**  
  - Python Flask 入門指南  
    [文章連結](https://ithelp.ithome.com.tw/articles/10258223)  
  - Android Kotlin 基本概念課程  
    [官方課程連結](https://developer.android.com/courses/android-basics-kotlin/course?hl=zh-tw)

- **數據來源與範例**  
  - 警政統計通報 - 內政部警政署全球資訊網  
    [官方數據](https://www.npa.gov.tw/ch/app/data/list?module=wg057&id=2218)  

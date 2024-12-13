from flask import Flask, request, make_response, render_template_string
from flask_cors import CORS
from werkzeug.utils import secure_filename
import pytesseract
from PIL import Image
import os
import requests

# 設置Tesseract的路徑
pytesseract.pytesseract.tesseract_cmd = os.path.join(os.path.dirname(__file__), 'Tesseract-OCR', 'tesseract.exe')

app = Flask(__name__)
CORS(app)  # 啟用CORS
app.config['UPLOAD_FOLDER'] = 'uploads'

if not os.path.exists(app.config['UPLOAD_FOLDER']):
    os.makedirs(app.config['UPLOAD_FOLDER'])

# HTML_TEMPLATE 保持不變
with open('template.html', 'r', encoding='utf-8') as file:
    HTML_TEMPLATE = file.read()
@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'image' not in request.files:
        return 'error:沒有圖片被上傳', 400

    file = request.files['image']
    if file.filename == '':
        return 'error:沒有選擇圖片', 400

    x = float(request.form['x'])
    y = float(request.form['y'])
    width = float(request.form['width'])
    height = float(request.form['height'])
    lang = request.form.get('lang', 'chi_tra')  # 默認使用繁體中文

    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    try:
        img = Image.open(filepath)

        # 增加邊距參數
        margin = 5
        x = max(0, x - margin)
        y = max(0, y - margin)
        width = min(img.width - x, width + 2 * margin)
        height = min(img.height - y, height + 2 * margin)

        cropped_img = img.crop((x, y, x + width, y + height))
        text = pytesseract.image_to_string(cropped_img, lang=lang).replace('\n', '')
        os.remove(filepath)  # 清理上傳的文件
        return text
    except pytesseract.TesseractError as e:
        return 'error:Tesseract-OCR錯誤：' + str(e), 500
    except Exception as e:
        return '', 500

def forward_request(route):
    try:
        text = request.data.decode('utf-8')
        response = requests.post(f'http://127.0.0.1:8888/{route}', data=text.encode('utf-8'), timeout=5)
        response.raise_for_status()  # 如果狀態碼不是 200，這會拋出異常

        # 創建一個純文本響應
        resp = make_response(response.text)
        resp.headers['Content-Type'] = 'text/plain; charset=utf-8'
        return resp
    except requests.RequestException as e:
        app.logger.error(f"Error sending request to server: {str(e)}")
        return "Error: Failed to communicate with server", 500
    except Exception as e:
        app.logger.error(f"Unexpected error: {str(e)}")
        return "Error: An unexpected error occurred", 500

@app.route('/str_request', methods=['POST'])
def str_request_route():
    return forward_request('str_request')

@app.route('/lineid_request', methods=['POST'])
def lineid_request_route():
    return forward_request('lineid_request')

@app.route('/url_request', methods=['POST'])
def url_request_route():
    return forward_request('url_request')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
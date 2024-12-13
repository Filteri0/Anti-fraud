from http.server import BaseHTTPRequestHandler, HTTPServer
from model_loader import load_model_and_tokenizer
from predictor import predict
from idsearch import select_id
from urlsearch import select_url

HOST = "127.0.0.1"
PORT = 8888

model, tokenizer, ws_driver, DEVICE = load_model_and_tokenizer() # 載入模型和 tokenizer

# 處理文字預測
def str_request(post_data_str):
    try:
        response_message = predict(post_data_str, model, tokenizer, ws_driver, DEVICE)
    except Exception as e:
        print(f"錯誤代碼: {str(e)}")
        response_message = "失敗"
    return response_message

# 處理 line id 搜尋
def lineid_request(line_id_str):
    try:
        response_message = select_id(line_id_str)
    except Exception as e:
        print(f"錯誤代碼: {str(e)}")
        response_message = "失敗"
    return response_message

# 處理 url 搜尋
def url_request(url_str):
    try:
        response_message = select_url(url_str)
    except Exception as e:
        print(f"錯誤代碼: {str(e)}")
        response_message = "失敗"
    return response_message

# 定義請求處理類
class RequestHandler(BaseHTTPRequestHandler):
    # 重寫 log_message 方法以禁止日志記錄
    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length)
        post_data_str = post_data.decode("utf-8")

        if self.path == '/str_request':
            response_message = str_request(post_data_str)
        elif self.path == '/lineid_request':
            response_message = lineid_request(post_data_str)
        elif self.path == '/url_request':
            response_message = url_request(post_data_str)
        else:
            response_message = "無效的請求路徑"

        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(response_message.encode("utf-8"))

server = HTTPServer((HOST, PORT), RequestHandler) # 創建 HTTP 服務器並指定請求處理類

print("server 運行中...")
server.serve_forever()
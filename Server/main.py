import subprocess

# 启动 http_server.py
http_server_process = subprocess.Popen(['D:\Venv\Pytorch_venv\Scripts\python', 'server.py'])

# 启动 frf.py
flask_app_process = subprocess.Popen(['D:\Venv\Pytorch_venv\Scripts\python', 'flaskserver.py'])

try:
    # 等待两个子进程结束
    http_server_process.wait()
    flask_app_process.wait()
except KeyboardInterrupt:
    # 捕获 Ctrl+C 事件并终止子进程
    http_server_process.terminate()
    flask_app_process.terminate()
finally:
    http_server_process.wait()
    flask_app_process.wait()

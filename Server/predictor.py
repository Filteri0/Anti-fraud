import re
import torch

def predict(text, model, tokenizer, ws_driver, device):
    if not text.strip():
        return "輸入為空！請提供有效的文本。"
    
    try:
        text = re.sub(r'[^\w\s，。！？、]', '', text) # 保留常見標點符號，只去除特殊字符
        
        ws_result = ws_driver([text])
        tokens = ws_result[0]
        content = " ".join(tokens)  # 保留詞與詞之間的間隔
        
        # 編碼文本為張量
        tokens_tensor = tokenizer.encode(
            content,
            add_special_tokens=True,  # 加入特殊標記
            max_length=128,
            truncation=True,
            padding='max_length',
            return_tensors='pt'
        ).squeeze(0)  # 保持一維
        
        tokens_tensor = tokens_tensor.to(device)
        
        # 模型預測
        with torch.no_grad():
            outputs = model(input_ids=tokens_tensor.unsqueeze(0))
            logits = outputs.logits
            _, pred = torch.max(logits, 1)

        # 解讀預測結果
        prediction = pred.item()
        risk = "較低風險" if prediction == 0 else "較高風險!!!"
        return f"預測結果：{risk}"
    
    except Exception as e:
        return f"錯誤代碼: {str(e)}"

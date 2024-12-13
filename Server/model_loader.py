import torch
from transformers import BertTokenizer, BertForSequenceClassification
from ckip_transformers.nlp import CkipWordSegmenter

MODEL_PATH = './model_save/bert_classification_model.bin'
TOKENIZER_PATH = './model_save/bert_tokenizer/'
DEVICE = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

def load_model_and_tokenizer():
    tokenizer = BertTokenizer.from_pretrained(TOKENIZER_PATH)
    model = BertForSequenceClassification.from_pretrained("bert-base-chinese", num_labels=2)
    model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE), strict=False)
    model.to(DEVICE)
    model.eval()
    
    ws_driver = CkipWordSegmenter(model="bert-base", device=0)
    
    return model, tokenizer, ws_driver, DEVICE

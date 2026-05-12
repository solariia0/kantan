import fasttext
import numpy as np

model = fasttext.load_model("/home/kirra/code/kantan/assets/cc.en.300.bin")

def cosine(a, b):
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

def check_similarity(word1, word2):
    vec1 = model.get_word_vector(word1)
    vec2 = model.get_word_vector(word2)
    return cosine(vec1, vec2)
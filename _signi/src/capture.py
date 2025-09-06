import cv2
import mediapipe as mp
import numpy as np

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=1, min_detection_confidence=0.5)

def extract_landmarks(frame):
    img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(img)
    if results.multi_hand_landmarks:
        hand = results.multi_hand_landmarks[0]
        pts = np.array([[lm.x, lm.y, lm.z] for lm in hand.landmark])
        base = pts[0]
        pts = pts - base
        norm = np.linalg.norm(pts)
        if norm > 0: pts = pts / norm
        return pts.flatten()
    return np.zeros(21*3)

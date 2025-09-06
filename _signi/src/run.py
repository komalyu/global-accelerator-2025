import cv2
from collections import deque
import numpy as np
from capture import extract_landmarks
from model_infer import SignInterpreter

WINDOW_SIZE = 24
WINDOW = deque(maxlen=WINDOW_SIZE)

def main():
    cap = cv2.VideoCapture(0)
    interpreter = SignInterpreter()

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        lm = extract_landmarks(frame)
        WINDOW.append(lm)

        if len(WINDOW) == WINDOW_SIZE:
            window_np = np.array(WINDOW)
            prediction = interpreter.predict(window_np)
            cv2.putText(frame, prediction, (10, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

        cv2.imshow("Signi-Light", frame)
        if cv2.waitKey(1) & 0xFF == 27:
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()

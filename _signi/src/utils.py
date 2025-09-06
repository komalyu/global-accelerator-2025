def save_landmarks_to_file(landmarks, filename):
    with open(filename, "a") as f:
        f.write(",".join(map(str, landmarks)) + "\n")

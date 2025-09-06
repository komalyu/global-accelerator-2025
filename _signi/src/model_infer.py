import numpy as np
import tflite_runtime.interpreter as tflite

class SignInterpreter:
    def __init__(self, model_path="models/dummy_model.tflite"):
        self.interpreter = tflite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        self.labels = ["Hello", "Thanks", "Yes", "No", "I love you"]  # placeholder

    def predict(self, window):
        inp = np.expand_dims(window.flatten().astype(np.float32), axis=0)
        self.interpreter.set_tensor(self.input_details[0]['index'], inp)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details[0]['index'])
        return self.labels[int(np.argmax(output))]

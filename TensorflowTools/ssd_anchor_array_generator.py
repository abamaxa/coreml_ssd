import os
import sys
import argparse

print("This tool uses internal interfaces from the Tensorflow and has been tested with version 1.7 of Tensorflow")
print("It is very slow - expect it to take several minutes to complete")  

sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), "slim"))
sys.path.append(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

import tensorflow as tf

try :
    from object_detection.utils import config_util
    from object_detection.builders.model_builder import build
    from object_detection.exporter import _get_outputs_from_inputs, _image_tensor_input_placeholder
except Exception as e :
    print(e)
    print("Unable to import tensorflow object detection module.")
    print("Please ensure that a these modules and those from the dependant slim modules")
    print("are on your python path.")
    print("These modules can be obtained from github at:")
    print("https://github.com/tensorflow/models.git")
    print("Simply copy the object_detection and slim directories from the research directory into this directory.")
    sys.exit(1)
        
class TensorModel :
    def __init__(self, config_file) :
        self.detection_model = None
        self.tensor_outputs = None
        self.config_file = config_file
        self.anchors = None
                        
    def read_model(self) :     
        configs = config_util.get_configs_from_pipeline_file(self.config_file)        
        self.detection_model = build(configs['model'], False)
        self._build_detection_graph()
        
        with tf.Session() as session :
            boxes = self.detection_model.anchors.get()
            self.anchors = boxes.eval()
            
    def _build_detection_graph(self):
                
        placeholder_tensor, input_tensors = _image_tensor_input_placeholder()
        self.tensor_outputs = _get_outputs_from_inputs(
            input_tensors=input_tensors,
            detection_model=self.detection_model,
            output_collection_name='inference_op')
        
    def output_anchors_as_cplus(self) :
        with open("AnchorArray.h", "w") as anchor_file :
            anchor_file.write("// Generated file.\n")
            anchor_file.write("#ifndef AnchorArray_included\n")
            anchor_file.write("#define AnchorArray_included\n\n")
            anchor_file.write("const float _anchors[][4] = {\n")
            
            for idx, anchor in enumerate(self.anchors) :
                line = "\t{{ {:.8f}, {:.8f}, {:.8f}, {:.8f} }}".format(
                    anchor[0], anchor[1], anchor[2] ,anchor[3])
                if idx != len(self.anchors) - 1 :
                    line += ","
                line += "\n"
                anchor_file.write(line)

            anchor_file.write("};\n\n")
            anchor_file.write("#endif /* AnchorArray_included */\n")
    
    def output_anchors_as_swift(self) :
        with open("Anchors.swift", "w") as anchor_file :
            anchor_file.write("// Generated file.\n")
            anchor_file.write("struct Anchors {\n")
            anchor_file.write("  static let numAnchors = 1917\n")
            anchor_file.write("  static var ssdAnchors: [[Float32]] {\n")
            anchor_file.write("    var arr: [[Float32]] = Array(repeating: "
                              "Array(repeating: 0.0, count: 4), count: numAnchors)\n")
            
            for idx, anchor in enumerate(self.anchors) :
                anchor_file.write("    arr[{}] = [ {:.8f}, {:.8f}, {:.8f}, {:.8f} ]\n".format(
                    idx, anchor[0], anchor[1], anchor[2] ,anchor[3]))
                
            anchor_file.write("    return arr\n")
            anchor_file.write("    }\n")
            anchor_file.write("}\n")    

def main(args) :
    model = TensorModel(os.path.expanduser(args.config))
    model.read_model()
    model.output_anchors_as_cplus()
    model.output_anchors_as_swift()
    
if __name__ == "__main__" :
    parser = argparse.ArgumentParser(description='Generate anchor arrays from Tensorflow models')
             
    parser.add_argument('config', help="The path to the model's configuration file, "
                        "usually that's called pipeline.config")        
            
    args = parser.parse_args()    
    main(args)
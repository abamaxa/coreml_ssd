import os
import argparse

import tensorflow as tf
from tensorflow.python.tools import strip_unused_lib
from tensorflow.python.framework import dtypes
from tensorflow.python.platform import gfile

import tfcoreml 

class Convertor :
    def __init__(self, model_path) :
        self.tf_model_path = os.path.realpath(model_path)
        self.output_feature_names = ['concat:0', 'concat_1:0']
        self.input_name_shape_dict = {"Preprocessor/sub:0":[1,300,300,3]}
        self.original_gdef = None
        self.gdef = None
        self.frozen_model_file = "stripped_" + os.path.basename(self.tf_model_path)
        self.coreml_model = None

    def write(self) :
        try :
            output_path = os.path.splitext(self.tf_model_path)[0] + ".mlmodel"
            with gfile.GFile(self.frozen_model_file, "wb") as f:
                f.write(self.gdef.SerializeToString())
            
            self.coreml_model  = tfcoreml.convert(tf_model_path = self.frozen_model_file,
                mlmodel_path = output_path,
                output_feature_names = self.output_feature_names,
                input_name_shape_dict = self.input_name_shape_dict,
                image_input_names="Preprocessor/sub:0",
                image_scale=2./255.,
                red_bias=-1.0,
                green_bias=-1.0,
                blue_bias=-1.0)
        finally :
            if os.path.exists(self.frozen_model_file) :
                os.unlink(self.frozen_model_file)

    def read_graph(self) :
        with open(self.tf_model_path, 'rb') as f:
            serialized = f.read()
        tf.reset_default_graph()
        self.original_gdef = tf.GraphDef()
        self.original_gdef.ParseFromString(serialized)

        with tf.Graph().as_default() as _:
            tf.import_graph_def(self.original_gdef, name='')

    def strip_subgraphs(self) :
        input_node_names = ['Preprocessor/sub']
        output_node_names = ['concat', 'concat_1']
        self.gdef = strip_unused_lib.strip_unused(
            input_graph_def = self.original_gdef,
            input_node_names = input_node_names,
            output_node_names = output_node_names,
            placeholder_type_enum = dtypes.float32.as_datatype_enum)

    def save_stripped_graph(self) :
        # Save the feature extractor to an output file
        with gfile.GFile(self.frozen_model_file, "wb") as f:
            f.write(self.gdef.SerializeToString())
            
def main(args) :
    conv = Convertor(args.model)
    conv.read_graph()
    conv.strip_subgraphs()  
    conv.write()    
    
if __name__ == "__main__" :
    parser = argparse.ArgumentParser(description=
                                     'Converts a Tensorflow object detection model to CoreML') 
    parser.add_argument('model', help="The path to the model file, "
                        "usually that's called frozen_inference_graph.pb")        
            
    args = parser.parse_args()    
    main(args)



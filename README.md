# coreml_ssd

## Introduction

This Objective-C library provides support for using SSD object detector models with CoreML framework. The library provides the required post-processing support to generate bounding boxes from the raw predictions. It also provides support to render these predictions into either UIView or NSView, depending on the platform.

This project builds on the work of vonholst/SSDMobileNet_CoreML

https://github.com/vonholst/SSDMobileNet_CoreML

and also contains Objective-C implementations of hollance/CoreMLHelpers work

https://github.com/hollance/CoreMLHelpers

## Installation

The library can be installed by adding the following to your Podfile:

```
  use_frameworks!

  # Pods for SwiftStory
  pod "coreml_ssd", :git => 'https://github.com/abamaxa/coreml_ssd.git'

```

## Usage

Users of the library have to implement the SSDMobileNetDelegate protocol in order to receive prediction results.

```Objective-c
#import "SSDMobileNet.h"

@interface MyDetector : NSObject<SSDMobileNetDelegate>
```

```Objective-c

- (void) loadModel:(MLModel*) yourModel {
    self.detector = [[SSDMobileNet alloc]initWithModel:yourModel];
    self.detector.delegate = self;
}

// The SSDMobileNetDelegate protocol
- (void) visionRequestDidComplete:(SSDMobileNet*)model {
    const PredictionList &predictions = model.predictions;
    for (auto itr = predictions.begin();itr != predictions.end();++itr) {
        // do something with the predictions
    }
}
```

The predict method carries out a detection on a CMSampleBufferRef on iOS...

```Objective-c

-(void) predict:(CMSampleBufferRef) image {
    [self.detector predictWithSampleBuffer:self.image];
}
```

or CIImage (on OSX only) :

```Objective-c

-(void) predict:(CIImage*) image {
    [self.detector predictWithCIImage:self.image];
}
```

## Swift

This library now supports Swift 4.2.

```Swift
import CoreML
import coreml_ssd

class Detector : NSObject, SSDMobileNetDelegate {
    private var objectDetector: SSDMobileNet?
    private var queue = DispatchQueue(label: "com.abamaxa.swift_demo")    
    private var resultsLayer: BoxLayers?  
    private var currentView: UIView?
     
    override init() {
        super.init()
        self.objectDetector = SSDMobileNet(model:ssd_mobilenet_v2_coco().model)
        self.objectDetector?.delegate = self
    }
        
    func setView(view: UIView, resultsLayer: BoxLayers) {
        self.currentView = view
        self.resultsLayer = resultsLayer
    }
    
    func predict(sampleBuffer:CMSampleBuffer) {
        self.queue.async(execute: {
             self.objectDetector?.predict(with: sampleBuffer)
        })
    }
        
    func visionRequestDidComplete(_ model: SSDMobileNet!) {
        DispatchQueue.main.async {
            self.displayResults(model)
        }
    }
    
    func displayResults(_ model: SSDMobileNet) {
        guard let view = self.currentView else {
            print("The current view is not set, call setView() first")
            return
        }
        
        self.resultsLayer?.clear()
        
        for obj in model.predictions {
            let prediction = obj as! Predictions
            let rect = prediction.get_scaled_box(view.bounds.size)
            // Your method for getting class names
            let label = get_class_name(prediction.get_class_id())
            self.resultsLayer?.add(withLabel: rect, label: label)
        }
        
        self.resultsLayer?.draw(UIColor.red.cgColor)
    }
}


```

## Converting Tensorflow Models

CoreML cannot use models saved by Tensorflow. So, they have to be converted to a form that CoreML does support. One way to do this is to use the provided python script: TensorflowTools/tensorflow_to_coreml.py. To use, install the scripts dependancies by using pip:

```shell
pip install tensorflow tfcoreml

```

and then just pass it the path to the tensorflow model file to convert:

```shell
python tensorflow_to_coreml.py input/frozen_inference_graph.pb

```

The converted model will be saved to a subdirectory called "output", created by the script in the directory it is run from.

## Recreating Anchors

CoreML does not support the post-processing steps, hence the need for this library.

One of the tasks the library must perform is to map predictions to anchor boxes. These boxes are calculated from the Tensorflow object detection config file. Rather than shipping this file with your model and parsing it at run time, the anchor boxes are calculated ahead of time and written to a header file anchors.h. This file is specific to the model.

The one shipped with the library works with the default March 2018 version of SSDMobilenet v2. However, older models and models with different anchor box specs have different anchors.

So, the library ships with a tool, ssd_anchor_array_generator.py, that will regenerate the anchors.h file for a particular model. If you find that your model is not working as expected, please try regenerating the anchor.h file with this too.

The tool will also output a file Anchors.swift that can be used as a drop in replacement for the one in vonholst/SSDMobileNet_CoreML

To use, install version 1.7 of Tensorflow, including the slim and object_detection libraries.

The run the following command, passing the model's configuration file

```shell
$ python ssd_anchor_array_generator.py pipeline.config
```

## Licence

This software is released under the MIT licence.

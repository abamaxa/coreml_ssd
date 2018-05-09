# coreml_ssd

## Introduction

This Objective-C library provides support for using SSD object detector models with CoreML framework. The library provides the required post-processing support to generate bounding boxes from the raw predictions. It also provides support to render these predictions into either UIView or NSView, depending on the platform.

This project builds on the work of vonholst/SSDMobileNet_CoreML

https://github.com/vonholst/SSDMobileNet_CoreML

and also contains Objective-C implementations of hollance/CoreMLHelpers work

https://github.com/hollance/CoreMLHelpers

## Installation

The library can be installed by adding pod 'core_ssd' to your Podfile.

## Usage

Users of the library have to implement the SSDMobileNetDelegate protocol in order to receive prediction results. Furthermore, the library currently exposes C++ objects so must be called from an Objective-C++ module (i.e a .mm file).

```Objective-c
#import "SSDMobileNet.h"

@interface MyDetector : NSObject<SSDMobileNetDelegate>
```

```Objective-c

- (void) loadModel:(MLModel*) yourModel {
    self.detector = [[SSDMobileNet alloc]initWithModel:yourModel];
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

## Tensorflow Tools

CoreML does not support the post-processing steps, hence the need for this library.

These steps have been described in more detail by

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

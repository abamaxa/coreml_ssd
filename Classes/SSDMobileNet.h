//
//  SSDPostProcess.h
//  confital-ios


#ifndef SSDPostProcess_h
#define SSDPostProcess_h

#ifdef __cplusplus

#import <AVFoundation/AVFoundation.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

#import <vector>
#import <cmath>
#import <algorithm>

#import "Anchors.h"
#import "Prediction.h"

@class SSDMobileNet;

@protocol SSDMobileNetDelegate <NSObject>
- (void)visionRequestDidComplete:(SSDMobileNet*)model;
@end

@interface SSDMobileNet : NSObject {
}

@property (nonatomic, weak) id<SSDMobileNetDelegate> delegate;
@property (nonatomic) uint numClasses;
@property (nonatomic) uint imageSize;
@property (nonatomic) float detection_threshold;
@property (nonatomic) float iou_threshold;
@property (nonatomic) int limit;
@property (nonatomic) PredictionList predictions;

- (id) initWithModel:(MLModel *)model;
- (void) predictWithSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (void) predictWithCIImage:(CIImage*) image;
- (void) predictWithData:(NSData*) imageData;

@end

#endif /* __cplusplus */

#endif /* SSDPostProcess_h */

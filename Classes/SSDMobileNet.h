//
//  SSDPostProcess.h
//  confital-ios


#ifndef SSDPostProcess_h
#define SSDPostProcess_h

#import <AVFoundation/AVFoundation.h>
#import <CoreML/CoreML.h>
 
@class SSDMobileNet;

@protocol SSDMobileNetDelegate <NSObject>
- (void)visionRequestDidComplete:(SSDMobileNet*)model;
@end

@interface SSDMobileNet : NSObject {
}

- (id) initWithModel:(MLModel *)model;
- (void) predictWithSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (void) predictWithCIImage:(CIImage*) image;
- (void) predictWithData:(NSData*) imageData;

@property (nonatomic, weak) id<SSDMobileNetDelegate> delegate;
@property (nonatomic) uint numClasses;
@property (nonatomic) uint imageSize;
@property (nonatomic) float detection_threshold;
@property (nonatomic) float iou_threshold;
@property (nonatomic) int limit;
@property (nonatomic) NSMutableArray* predictions;

@end

#endif /* SSDPostProcess_h */

//  Created by Chris Morgan on 27/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.

#import "SSDMobileNet.h"
#include <iterator>

@interface SSDMobileNet () {
}

@property (nonatomic, strong) VNCoreMLModel * vnCoreModel;
@property (nonatomic, strong) VNCoreMLRequest *vnCoreMlRequest;
@property (nonatomic, strong) NSDate * detection_start_time;
@property (nonatomic, strong) NSDate * processing_start_time;
@property (nonatomic, weak) MLMultiArray* classes;
@property (nonatomic, weak) MLMultiArray* boxes;
@property (nonatomic) uint num_anchors;

@end

@implementation SSDMobileNet {
}

- (id) initWithModel:(MLModel *)model {
    self = [super init];
    if (self) {
        self.detection_threshold = 0.3;
        self.iou_threshold = 0.3;
        self.limit = 10;
        self.num_anchors = Anchor::get_number_of_anchors();
        [self setupModel:model];
    }
    return self;
}

-(void) setupModel:(MLModel *)model {
    self.vnCoreModel = [VNCoreMLModel modelForMLModel:model error:nil];
    self.vnCoreMlRequest = [[VNCoreMLRequest alloc] initWithModel:self.vnCoreModel
        completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error)
        {
            [self visionRequestDidComplete:request error:error];
        }];

    //self.vnCoreMlRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop;
    self.vnCoreMlRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
}

- (void) predictWithSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    self.detection_start_time = [NSDate date];
    NSDictionary *options_dict = [[NSDictionary alloc] init];

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    VNImageRequestHandler *vnImageRequestHandler = [[VNImageRequestHandler alloc]
                                                    initWithCVPixelBuffer:pixelBuffer
                                                    options:options_dict];
    [self performRequest:vnImageRequestHandler];
}

- (void) predictWithCIImage:(CIImage*) image {
    self.detection_start_time = [NSDate date];
    NSDictionary *options_dict = [[NSDictionary alloc] init];
    VNImageRequestHandler *vnImageRequestHandler = [[VNImageRequestHandler alloc]
                                                    initWithCIImage:image
                                                    options:options_dict];
    [self performRequest:vnImageRequestHandler];
}

- (void) predictWithData:(NSData*) imageData {
    self.detection_start_time = [NSDate date];
    NSDictionary *options_dict = [[NSDictionary alloc] init];
    VNImageRequestHandler *vnImageRequestHandler = [[VNImageRequestHandler alloc]
                                                    initWithData:imageData
                                                    options:options_dict];
    [self performRequest:vnImageRequestHandler];
}

-(void) performRequest:(VNImageRequestHandler *) vnImageRequestHandler {
    NSError *error = nil;
    [vnImageRequestHandler performRequests:@[self.vnCoreMlRequest] error:&error];

    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}

-(void) visionRequestDidComplete:(VNRequest *) request error:(NSError *)error {
    [self processResults:request.results];
    [self notifyMainThread];
}

-(void) processResults:(NSArray*) results {
    self.processing_start_time = [NSDate date];

    _predictions.clear();
    if (!results)
        return;

    VNCoreMLFeatureValueObservation *class_results = (VNCoreMLFeatureValueObservation *)results[0];
    VNCoreMLFeatureValueObservation *box_results = (VNCoreMLFeatureValueObservation *)results[1];

    self.classes = class_results.featureValue.multiArrayValue;
    self.boxes = box_results.featureValue.multiArrayValue;

    [self calculateBoundingBoxes];
    //NSLog(@"Found %lu possible classes before supression", _predictions.size());
    [self DoNonMaxSuppressionOp];
    //NSLog(@"Found %lu possible classes after supression", _predictions.size());

    self.classes = nil;
    self.boxes = nil;
}

-(void) calculateBoundingBoxes {
    float threshold_score = [self get_log_threshold];
    uint num_classes = [self get_number_classes];

    // The first class, 0, is the background class, so skip that.
    for (uint class_id = 1; class_id < num_classes;class_id++) {
        for (uint box_id = 0;box_id < self.num_anchors;box_id++) {
            float score = [self get_score:class_id box_id:box_id];
            if (score < threshold_score)
                continue;

            _predictions.push_back([self get_prediction:class_id box_id:box_id]);
        }
    }
}

-(uint) get_number_classes {
    return (uint)self.classes.count / self.num_anchors;
}

-(float) get_log_threshold {
    // An inverse of the sigmoid function.
    // The scores return by the model ought to have passed through the
    // sigmoid() function. However, this is computationally expensive
    // and unnecessary of the the threshold is converted to the value
    // it would have prior to being passed to sigmoid()
    return -log((1.0 / self.detection_threshold) - 1);
}

-(float) get_score:(uint) class_id box_id:(uint)box_id {
    const double* data = (const double*)self.classes.dataPointer;
    data += (self.num_anchors * class_id);
    data += box_id;
    return (float)*data;
}

-(Prediction) get_prediction:(uint) class_id box_id:(uint)box_id {
    const double* data = (const double*)self.boxes.dataPointer;
    const size_t ty = box_id;
    const size_t tx = ty + self.num_anchors;
    const size_t th = tx + self.num_anchors;
    const size_t tw = th + self.num_anchors;
    float score = [self get_score:class_id box_id:box_id];
    return Prediction(box_id, class_id, score, data[ty], data[tx], data[th], data[tw]);
}

// from
// https://github.com/tensorflow/tensorflow/blob/master/tensorflow/core/kernels/non_max_suppression_op.cc
- (void) DoNonMaxSuppressionOp
{
    long num_boxes = _predictions.size();
    if (!num_boxes)
        return;

    float iou_threshold = self.iou_threshold;
    const int output_size = self.limit;

    std::sort(_predictions.begin(), _predictions.end(),
      [](const Prediction & a, const Prediction & b) -> bool {
          return a.get_score() > b.get_score();
      });

    std::vector<float> scores_data(num_boxes);
    auto source = _predictions.begin();
    auto destination = scores_data.begin();
    for (;source != _predictions.end();++source, ++destination) {
        *destination = (*source).get_score();
    }

    std::vector<int> sorted_indices;
    DecreasingArgSort(scores_data, &sorted_indices);

    PredictionList selected;
    std::vector<int> selected_indices(output_size, 0);
    int num_selected = 0;
    for (int i = 0; i < num_boxes; ++i) {
        if (selected.size() >= output_size) break;
        bool should_select = true;
        const Prediction& test1 = _predictions[sorted_indices[i]];

        // Overlapping boxes are likely to have similar scores,
        // therefore we iterate through the selected boxes backwards.
        for (int j = num_selected - 1; j >= 0; --j) {
            const Prediction& test2 = _predictions[sorted_indices[selected_indices[j]]];
            if (test1.IOUGreaterThanThreshold(test2, iou_threshold))
            {
                should_select = false;
                break;
            }
        }
        if (should_select) {
            selected.push_back(test1);
            selected_indices[num_selected++] = i;
        }
    }

    _predictions.resize(selected.size());
    std::copy_n(selected.begin(), selected.size(), _predictions.data());
}

static inline void DecreasingArgSort(const std::vector<float>& values,
                                     std::vector<int>* indices) {
    indices->resize(values.size());
    for (int i = 0; i < values.size(); ++i) (*indices)[i] = i;
    std::sort(indices->begin(), indices->end(),
              [&values](const int i, const int j) { return values[i] > values[j]; });
}

-(void) notifyMainThread {
    auto strongDelegate = self.delegate;
    if (strongDelegate) {
        if ([strongDelegate respondsToSelector:@selector(visionRequestDidComplete:)])
            [strongDelegate visionRequestDidComplete:self];
    }

    NSTimeInterval detection = [[NSDate date] timeIntervalSinceDate:self.detection_start_time];
    NSTimeInterval processing = [[NSDate date] timeIntervalSinceDate:self.processing_start_time];
    NSLog(@"Completed detection in %.3f seconds, processing in %.3f seconds", detection, processing);
}

@end

//
//  Anchors.h
//  confital-ios
//
//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.
//

#ifndef Anchors_h
#define Anchors_h

#ifdef __cplusplus

#include "AnchorArray.h"

class Anchor {
public:
    Anchor(float y_center, float x_center, float h, float w) :
        ycenter_a(y_center),
        xcenter_a(x_center),
        ha(h),
        wa(w)
    {
        
    }
    
    static const Anchor get_center_coordinates_and_sizes(size_t index)
    {
        const float* p = &_anchors[index][0];
        
        float ymin = *p++;
        float xmin = *p++;
        float ymax = *p++;
        float xmax = *p++;
        
        return Anchor((ymin + ymax) / 2.0, (xmin + xmax) / 2.0,
                      ymax - ymin, xmax - xmin);
    }
    
    static uint get_number_of_anchors() {
        return sizeof(_anchors) / sizeof(_anchors[0]);
    }
    
    const float ycenter_a;
    const float xcenter_a;
    const float ha;
    const float wa;
};

#endif /* __cplusplus */
#endif /* Anchors_h */

//
//  NSBezierPath+QuartzPath.h
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (BezierPathQuartzUtilities)
    - (CGPathRef)quartzPath;
@end

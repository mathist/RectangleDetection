//
//  RectangleService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "RectangleService.h"

@implementation RectangleService

- (instancetype)init
{
    if (!(self = [super init])) return nil;
    
    return self;
}

-(void)dealloc
{
    NSLog(@"%@", @"RectangleService Dealloc");
}

-(void)request:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request , NSError * _Nullable error)
    {
        if (error)
        {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
      
        if(request.results && request.results.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(rectanglesFound:)])
            [self.delegate rectanglesFound:request.results];
    }];

    request.maximumObservations = 10;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:buffer orientation:kCGImagePropertyOrientationRight options:@{}];
    
    NSError *error;
    [handler performRequests:@[request] error:&error];

    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
}

//-(void)handleRectangles:(VNRequest *)request forError:(NSError * _Nullable)error
//{
//    if (error)
//    {
//        NSLog(@"%@", error.localizedDescription);
//        return;
//    }
//    
//    if(request.results && request.results.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(rectanglesFound:)])
//        [self.delegate rectanglesFound:request.results];
//}

-(CGPoint)convertToUIView:(CGPoint)point forSize:(CGSize)size
{
    CGPoint newPoint = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(size.width, size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeTranslation(0, -size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeScale(1, -1));
    
    return newPoint;
}

@end

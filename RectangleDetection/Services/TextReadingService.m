//
//  TextReadingService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 8/30/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "TextReadingService.h"

@implementation TextReadingService

-(void)readText:(UIImage *)image
{
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:[image CGImage] options:@{}];
    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc]  initWithCompletionHandler:^(VNRequest * _Nonnull request , NSError * _Nullable error)
    {
        if (error)
        {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        if(request.results && request.results.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(textFound:)])
            [self.delegate textFound:request.results];
    }];

    [request setRecognitionLevel:VNRequestTextRecognitionLevelAccurate];
    
    NSError *error;
    [handler performRequests:@[request] error:&error];

    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
}

@end

//
//  FaceViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/24/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "FaceViewController.h"
#import "CaptureVideoService.h"
#import "FaceDetectionService.h"

@interface FaceViewController () <CaptureVideoServiceDelegate, FaceDetectionServiceDelegate>

@property (nonatomic, retain) CaptureVideoService *captureVideoService;
@property (nonatomic, retain) FaceDetectionService *faceDetectionService;

@property (nonatomic, retain) CALayer *overlayLayer;

@end

@implementation FaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.captureVideoService = [[CaptureVideoService alloc] initWithDevicePosition:AVCaptureDevicePositionFront withOptions:kCaptureVideoServiceOptionOutput];
    [self.captureVideoService setDelegate:self];
    
    self.faceDetectionService = [FaceDetectionService new];
    [self.faceDetectionService setDelegate:self];
    
    [self.view.layer addSublayer:self.captureVideoService.captureLayer];
    
    self.overlayLayer = [CALayer new];
    [self.view.layer addSublayer:self.overlayLayer];
}

-(void)dealloc
{
    self.captureVideoService = nil;
    self.faceDetectionService = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.captureVideoService startCamera];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureVideoService stopCamera];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.captureVideoService.captureLayer.frame = self.view.bounds;
    self.overlayLayer.frame = self.view.bounds;
}

#pragma mark FaceDetectionServiceDelegate methods
-(void)facesFound:(NSArray<VNFaceObservation *> *)faces
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.overlayLayer.sublayers = nil;

        CGSize size = self.view.frame.size;

        for(VNFaceObservation *face in faces)
        {
            CGFloat width = size.width * face.boundingBox.size.width;
            CGFloat height = size.height * face.boundingBox.size.height;
            CGFloat y = size.height - (size.height * face.boundingBox.origin.y) - height;
            CGFloat x = size.width - (size.width * face.boundingBox.origin.x) - width;

            CGPoint topLeft = CGPointMake(x, y);
            CGPoint topRight = CGPointMake(x + width, y);
            CGPoint bottomLeft = CGPointMake(x, y+height);
            CGPoint bottomRight = CGPointMake(x + width, y+height);

            UIBezierPath *path = [[UIBezierPath alloc] init];
            [path moveToPoint:topLeft];
            [path addLineToPoint:topRight];
            [path addLineToPoint:bottomRight];
            [path addLineToPoint:bottomLeft];
            [path addLineToPoint:topLeft];

            CAShapeLayer *layer = [CAShapeLayer layer];
            [layer setPath:path.CGPath];
            [layer setFillRule:kCAFillRuleEvenOdd];
            [layer setFillColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5].CGColor];

            [self.overlayLayer addSublayer:layer];
        }
    });
}

#pragma mark CaptureVideoServiceDelegate methods

-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.faceDetectionService request:sampleBuffer];
}

@end

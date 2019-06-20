//
//  RectangleViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "RectangleViewController.h"
#import "CaptureVideoService.h"
#import "RectangleService.h"
#import "ImageCorrection.h"

@interface RectangleViewController () <RectangleServiceDelegate, CaptureVideoServiceDelegate>

@property (nonatomic, retain) CaptureVideoService *captureVideoService;
@property (nonatomic, retain) RectangleService *rectangleService;
@property (nonatomic, retain) CALayer *overlayLayer;

@end

@implementation RectangleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.captureVideoService = [CaptureVideoService new];
    [self.captureVideoService setDelegate:self];
    self.rectangleService = [RectangleService new];
    
    [self.rectangleService setDelegate:self];
    [self.view.layer addSublayer:self.captureVideoService.captureLayer];
    
    self.overlayLayer = [CALayer new];
    [self.view.layer addSublayer:self.overlayLayer];
}

-(void)dealloc
{
    [self.captureVideoService setDelegate:nil];
    self.captureVideoService = nil;
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

#pragma mark RectangleServiceDelegate methods

- (void)rectanglesFound:(nonnull NSArray<VNRectangleObservation *> *)rectangles
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.overlayLayer.sublayers = nil;
    
        CGSize size = self.view.frame.size;

        for(VNRectangleObservation *result in rectangles)
        {
            CGPoint topLeft = [self.rectangleService convertToUIView:result.topLeft forSize:size];
            CGPoint topRight = [self.rectangleService convertToUIView:result.topRight forSize:size];
            CGPoint bottomRight = [self.rectangleService convertToUIView:result.bottomRight forSize:size];
            CGPoint bottomLeft = [self.rectangleService convertToUIView:result.bottomLeft forSize:size];
            
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
    [self.rectangleService request:sampleBuffer];
}

@end

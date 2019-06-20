//
//  SimpleCameraViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "SimpleCameraViewController.h"
#import "VideoService.h"

@interface SimpleCameraViewController ()

@property (nonatomic, retain) VideoService *videoService;

@end

@implementation SimpleCameraViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
     self.videoService = [VideoService new];
    
    [self.view.layer addSublayer:self.videoService.captureLayer];
}

-(void)dealloc
{
    self.videoService = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.videoService startCamera];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.videoService stopCamera];
}


-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.videoService.captureLayer.frame = self.view.bounds;
}

@end

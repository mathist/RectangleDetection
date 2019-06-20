//
//  MenuTableViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/16/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "MenuTableViewController.h"
#import <Photos/Photos.h>
#import <Photos/PHPhotoLibrary.h>

@interface MenuTableViewController ()

@end

@implementation MenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
    
}


@end

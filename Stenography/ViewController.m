//
//  ViewController.m
//  Stenography
//
//  Created by App-Lab on 7/9/14.
//  Copyright (c) 2014 Eric Simon. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

-(void)viewDidLoad
{
    NSLog(@"viewDidLoad called");
    _reader = [[Reader alloc] init];
    NSString *message = @"hello world";
    _image2View.image = [_reader encodeMessage:_imgView.image:message];
    _label.text = [_reader decodeMessage:_image2View.image];
    NSLog(@"method passed");
}

@end

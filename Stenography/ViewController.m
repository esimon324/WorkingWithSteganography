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
   
    _reader = [[Reader alloc] init];
    
}

- (IBAction)encodeImage:(id)sender {
    [self.view endEditing:YES];
    _image2View.image = [_reader encodeMessage:_imgView.image:_textField.text];
}

- (IBAction)decodeImage:(id)sender {
    _label.text = [_reader decodeMessage:_image2View.image];
}
@end

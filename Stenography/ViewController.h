//
//  ViewController.h
//  Stenography
//
//  Created by App-Lab on 7/9/14.
//  Copyright (c) 2014 Eric Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reader.h"

@interface ViewController : UIViewController{

}
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIImageView *image2View;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) Reader *reader;
@end

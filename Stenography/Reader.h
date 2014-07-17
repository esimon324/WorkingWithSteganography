//
//  Reader.h
//  Stenography
//
//  Created by App-Lab on 7/9/14.
//  Copyright (c) 2014 Eric Simon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Reader : NSObject

@property (strong, nonatomic) UIImage *img;
@property (nonatomic) NSUInteger messageSize;

-(NSString *)decodeMessage:(UIImage *)img;
-(UIImage *)encodeMessage:(UIImage *)img :(NSString *) message;
@end

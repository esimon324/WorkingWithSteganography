//
//  CFBitVectorTransformer.h
//  SteganographyDemo
//
//  Created by App-Lab on 7/15/14.
//  Copyright (c) 2014 SteganosarusRextMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CFBitVectorTransformer : NSObject

@property (nonatomic) CFBitVectorRef transRef;
- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;

@end

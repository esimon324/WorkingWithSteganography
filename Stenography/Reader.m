//
//  Reader.m
//  Stenography
//
//  Created by App-Lab on 7/9/14.
//  Copyright (c) 2014 Eric Simon. All rights reserved.
//

#import "Reader.h"

@implementation Reader



-(NSString *)decodeMessage:(UIImage *)img
{
    CGImageRef imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    
    
    CFBitVectorRef dataBits = CFBitVectorCreate(kCFAllocatorDefault, data, _messageSize*8*(4/3)+8);
    CFMutableBitVectorRef codedString = CFBitVectorCreateMutableCopy(kCFAllocatorDefault, _messageSize, dataBits);
    CFBitVectorSetAllBits(codedString, 0);
    
    CFBit currentBit;
    
    
    for (int i = 0; i < _messageSize; i ++)
    {
            currentBit = CFBitVectorGetBitAtIndex(dataBits, (((i+1)*8)-1));
            if(currentBit == 0)
            {
            
                CFBitVectorSetBitAtIndex(codedString, i, currentBit);
            }
            if(currentBit == 1)
            {
                CFBitVectorSetBitAtIndex(codedString, i, currentBit);
            }
    }
    
    
    CFBitVectorSetCount(codedString, _messageSize);
    NSMutableData *bitData = [[NSMutableData alloc] init];
    NSUInteger numBits = CFBitVectorGetCount(codedString);
    uint8_t nextBytes;
    NSUInteger iterator = 0;
    for(int i =0; i < numBits; i++)
    {
        CFRange range = CFRangeMake(iterator, 8);
        CFBitVectorGetBits(codedString, range, &nextBytes);
        [bitData appendBytes:&nextBytes length:1];
        iterator = i+8;
    }
    
    NSData *newData = [NSData dataWithData:bitData];
    NSString *picString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    
    return picString;
}

-(UIImage *)encodeMessage:(UIImage *)img :(NSString *)message
{
    NSData *stringData = [message dataUsingEncoding:NSUTF8StringEncoding];
    UInt8 *stringBits = (UInt8 *)stringData.bytes;
    
    CFBitVectorRef stringRealBits = CFBitVectorCreate(NULL, stringBits, [stringData length]*8);
    
    
    CGImageRef imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    CFBit currentBit;
    _messageSize = CFBitVectorGetCount(stringRealBits);
    NSUInteger skippedSteps = 0;
    for (NSUInteger i = 0; i < _messageSize + skippedSteps; i ++)
    {
            currentBit = CFBitVectorGetBitAtIndex(stringRealBits, i);
            if(data[i]%2 < currentBit)
            {
                data[i]++;
            }
            if(data[i]%2 > currentBit)
            {
                data[i]--;
            }
        
    }
    
    bmContext = CGBitmapContextCreate(data, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *imageNew = [[UIImage alloc] initWithCGImage:newImageRef];
    return imageNew;
}
@end

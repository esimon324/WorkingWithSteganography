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
    NSData *forLengthPurposes = [[NSData alloc] initWithBytesNoCopy:data length:(img.size.height*img.size.width)];
    
    
    CFBitVectorRef dataBits = CFBitVectorCreate(kCFAllocatorDefault, data, [forLengthPurposes length]*8);
    CFMutableBitVectorRef codedString = CFBitVectorCreateMutableCopy(kCFAllocatorDefault, [forLengthPurposes length]*8, dataBits);
    CFBitVectorSetAllBits(codedString, 0);
    
    CFBit currentBit;
    
    for (int i = 0; i < [forLengthPurposes length]; i ++)
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
    
    UInt8 *bitDataBytes = (UInt8 *)bitData.bytes;
    NSUInteger lengthOfTextBytes = 0;
    for(int i = 0; i < [bitData length]; i++){
        if(bitDataBytes[i] == 3){
            lengthOfTextBytes ++;
            break;
        }
        else{
            lengthOfTextBytes ++;
        }
    }
    
    [bitData setLength:lengthOfTextBytes];
    
    NSData *newData = [NSData dataWithData:bitData];
    NSString *picString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    CGContextRelease(bmContext);
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
    for (NSUInteger i = 0; i < _messageSize ; i ++)
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
        if(i == _messageSize - 1)
        {
            for(NSUInteger j = 1; j < 9; j++)
            {
                if(j < 7)
                {
                    if(data[i+j]%2 == 1){
                        data[i+j] --;
                    }
                }
                else{
                    if(data[i+j]%2 == 0){
                        data[i+j] ++;
                    }
                }
            }
        }
        
        
    }
    
    bmContext = CGBitmapContextCreate(data, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *imageNew = [[UIImage alloc] initWithCGImage:newImageRef];
    CGContextRelease(bmContext);
    return imageNew;
}
@end

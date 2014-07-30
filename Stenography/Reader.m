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
    NSData *picData = UIImagePNGRepresentation(img);
    img = [[UIImage alloc] initWithData:picData];
    imageRef = img.CGImage;
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
    NSMutableData *bitData = [[NSMutableData alloc] init];
    NSUInteger numIterations = [forLengthPurposes length];
    uint8_t nextBytes;
    
    for (int i = 0; i < numIterations; i ++)
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
        if((i+1)%8 == 0)
        {
            CFRange range = CFRangeMake((i-7), 8);
            CFBitVectorGetBits(codedString, range, &nextBytes);
            if(nextBytes == 3)
            {
                break;
            }
            [bitData appendBytes:&nextBytes length:1];
            
        }
    }
    
    NSData *newData = [NSData dataWithData:bitData];
    NSString *picString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    CGContextRelease(bmContext);
    return picString;
}

-(UIImage *)encodeMessage:(UIImage *)img :(NSString *)message
{
    //get bits from input message
    
    NSData *stringData = [message dataUsingEncoding:NSUTF8StringEncoding];
    UInt8 *stringBits = (UInt8 *)stringData.bytes;
    
    CFBitVectorRef stringRealBits = CFBitVectorCreate(NULL, stringBits, [stringData length]*8);
    
    
    //grabs image input in function
    CGImageRef imageRef = img.CGImage;
    img = [[UIImage alloc] initWithCGImage:imageRef];
    NSData *picData = UIImagePNGRepresentation(img);
    img = [[UIImage alloc] initWithData:picData];
    imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    
    //gets bytes from image
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    CFBitVectorRef dataBits = CFBitVectorCreate(NULL, data, nBytesPerRow*nHeight*8);
    CFBit currentBit;
    
    _messageSize = CFBitVectorGetCount(stringRealBits);
    NSUInteger endOfString = _messageSize;
    //encodes message into picture
    for (NSUInteger i = 0; i <= _messageSize ; i ++)
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
        
        //adds end of line character to message
        
        dataBits = CFBitVectorCreate(NULL, data, nBytesPerRow*nHeight*8);
    }
    
    for(NSUInteger j = endOfString+1; j < endOfString+9; j++)
    {
        if(j < endOfString+6)
        {
            if(data[j]%2 == 1)
            {
                data[j] --;
            }
        }
        else
        {
            if(data[j]%2 == 0)
            {
                data[j] ++;
            }
        }
        dataBits = CFBitVectorCreate(NULL, data, nBytesPerRow*nHeight*8);
    }
    
    //draws new image from data, returns said image
    bmContext = CGBitmapContextCreate(data, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *imageNew = [[UIImage alloc] initWithCGImage:newImageRef];
    picData = UIImagePNGRepresentation(imageNew);
    imageNew = [[UIImage alloc] initWithData:picData];
    CGContextRelease(bmContext);
    return imageNew;
}
@end

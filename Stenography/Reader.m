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
    
    
    UInt8* imgBytes = (UInt8*)CGBitmapContextGetData(bmContext);
    NSUInteger numImgBits = (nBytesPerRow*nHeight)*8;
    CFBitVectorRef imgBits = CFBitVectorCreate(kCFAllocatorDefault, imgBytes, numImgBits);
    
    CFMutableBitVectorRef bitStream = CFBitVectorCreateMutableCopy(kCFAllocatorDefault, numImgBits, imgBits);
    CFBitVectorSetAllBits(bitStream, 0);
    
    NSMutableData *decodedDataMut = [[NSMutableData alloc] init];
    uint8_t currentByte = '\0';
    CFBit currentBit;
    NSUInteger i = 0;
    BOOL startDecoding = NO;
    
    while (currentByte != 3)
    {
        currentBit = CFBitVectorGetBitAtIndex(imgBits, (((i+1)*8)-1));
        CFBitVectorSetBitAtIndex(bitStream, i, currentBit);
        
        if(startDecoding == NO)
        {
            if((i+1)%4 == 0 && CFBitVectorGetCount(bitStream) > 4)
            {
                CFRange range = CFRangeMake((i-7), 8);
                CFBitVectorGetBits(bitStream, range, &currentByte);
                if(currentByte == 2)
                {
                    startDecoding = YES;
                }
            }
        }
        else
        {
            if((i+1)%8 == 0)
            {
                CFRange range = CFRangeMake((i-7), 8);
                CFBitVectorGetBits(bitStream, range, &currentByte);
                [decodedDataMut appendBytes:&currentByte length:1];
            }
        }
        i++;
    }
    
    NSData *decodedData = [NSData dataWithData:decodedDataMut];
    NSString *picString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    CGContextRelease(bmContext);
    return picString;
}

-(UIImage *)encodeMessage:(UIImage *)img :(NSString *)message
{
    const NSUInteger BIT_SIZE = 8;
    //get bits from input message
    NSData* stringData = [message dataUsingEncoding:NSUTF8StringEncoding];
    UInt8* stringBytes = (UInt8 *)stringData.bytes;
    CFBitVectorRef stringBits = CFBitVectorCreate(NULL, stringBytes, [stringData length]*8);
    
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
    UInt8* imgBytes = (UInt8*)CGBitmapContextGetData(bmContext);
    NSUInteger numImgBytes = (nBytesPerRow*nHeight);
    
    NSUInteger numStringBits = CFBitVectorGetCount(stringBits);
    
    NSUInteger numEncodes = numImgBytes/((numStringBits)+(2*BIT_SIZE));
    NSUInteger iter = 0;
    NSUInteger offset = 0;
    CFBit currentBit;
    
    //encodes the max number of times for the given image size
    for(NSUInteger curEncode = 0; curEncode < numEncodes; curEncode++)
    {
        //adding the UTF-8 start tag (value is 2) to the beginning of the message
        for(; iter < BIT_SIZE+offset; iter++)
        {
            if(iter == 6)
            {
                if(imgBytes[iter]%2 == 0)
                {
                    imgBytes[iter] ++;
                }
            }
            else
            {
                if(imgBytes[iter]%2 == 1)
                {
                    imgBytes[iter] --;
                }
            }
        }

        //encodeing message into image bits
        for (; iter < BIT_SIZE+numStringBits+offset; iter++)
        {
            currentBit = CFBitVectorGetBitAtIndex(stringBits, (iter-8));
            if(imgBytes[iter]%2 < currentBit)
            {
                imgBytes[iter]++;
            }
            if(imgBytes[iter]%2 > currentBit)
            {
                imgBytes[iter]--;
            }
        }
        
        //adding the UTF-8 start tag (value is 2) to the beginning of the message
        for(; iter < (BIT_SIZE*2)+numStringBits+offset; iter++)
        {
            if(iter < (numStringBits+8)+6)
            {
                if(imgBytes[iter]%2 == 1)
                {
                    imgBytes[iter] --;
                }
            }
            else
            {
                if(imgBytes[iter]%2 == 0)
                {
                    imgBytes[iter] ++;
                }
            }
        }
        //updating the offset value
        offset = iter;
    }
    //draws new image from data, returns said image
    bmContext = CGBitmapContextCreate(imgBytes, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *imageNew = [[UIImage alloc] initWithCGImage:newImageRef];
    picData = UIImagePNGRepresentation(imageNew);
    imageNew = [[UIImage alloc] initWithData:picData];
    CGContextRelease(bmContext);
    return imageNew;
}
@end

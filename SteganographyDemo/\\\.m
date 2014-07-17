//
//  Steganographer.m
//  SteganographyDemo
//
//  Created by App-Lab on 7/15/14.
//  Copyright (c) 2014 SteganosarusRextMessaging. All rights reserved.
//

#import "Steganographer.h"

@implementation Steganographer
/*
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
    
    NSData *picStringData = [NSData dataWithBytesNoCopy:data length:_messageSize freeWhenDone:(YES)];
    NSString *picString = [[NSString alloc] initWithData:picStringData encoding:NSUTF8StringEncoding];
    return picString;
}

-(UIImage *)encodeMessage:(UIImage *)img :(NSString *)message
{
    NSData *stringData = [message dataUsingEncoding:NSUTF8StringEncoding];
    UInt8 *stringBits = (UInt8 *)stringData.bytes;
    
    CGImageRef imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    _messageSize = stringData.length;

    for (NSUInteger i = 0; i < _messageSize; i++)
    {
        data[i] = stringBits[i];
    }
    CGImageRef newImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *imageNew = [[UIImage alloc] initWithCGImage:newImageRef];
    return imageNew;
}*/

-(UIImage *)encodeMessage:(UIImage *)img :(NSString *)message
{
    //---Creating a reference to the message bits--------------------------------------------------------------------//
    NSData *stringData = [message dataUsingEncoding:NSUTF8StringEncoding];
    UInt8 *stringBytes = (UInt8 *)stringData.bytes;
    NSUInteger numStringBits = stringData.length*8;
    CFBitVectorRef stringBits = CFBitVectorCreate(NULL,stringBytes,numStringBits);
    //CFMutableBitVectorRef stringBitsMut = CFBitVectorCreateMutableCopy(CFGetAllocator(stringBits), numStringBits, stringBits);
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Getting the image bytes-------------------------------------------------------------------------------------//
    CGImageRef imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    CFRetain(stringBits);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    //CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    //CFRetain(stringBits);
    UInt8 *imgBytes = (UInt8 *)CGBitmapContextGetData(bmContext);
    //CGContextRelease(bmContext);
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Getting a reference to the image bits-----------------------------------------------------------------------//
    CFBitVectorRef imgBits = CFBitVectorCreate(NULL,imgBytes,nHeight*nWidth*32);
    NSUInteger numImgBits = CFBitVectorGetCount(imgBits);
    CFMutableBitVectorRef imgBitsMut = CFBitVectorCreateMutableCopy(kCFAllocatorDefault, numImgBits, imgBits);
    CFRetain(imgBitsMut);
    //---------------------------------------------------------------------------------------------------------------//

    //---Encoding message bits into image bits-----------------------------------------------------------------------//
    NSUInteger imgBitsIter;
    _messageSize = CFBitVectorGetCount(stringBits);
    for (NSUInteger i = 0; i < CFBitVectorGetCount(stringBits); i++)
    {
        imgBitsIter = (8*(i+1))-1;
        CFBitVectorSetBitAtIndex(imgBitsMut, imgBitsIter, CFBitVectorGetBitAtIndex(stringBits, i));
        imgBits = CFBitVectorCreateCopy(CFGetAllocator(imgBitsMut), imgBitsMut);
    }
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Copying the contents of the non-mutable img bit array to NSData object--------------------------------------//
    _trans = [[CFBitVectorTransformer alloc] init];
    NSData *newImgData = [_trans transformedValue:(__bridge id)imgBits];
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Creating a new, encoded image from the modified bits--------------------------------------------------------//
    UIImage *imageNew = [[UIImage alloc] initWithData:newImgData];
    return imageNew;
    //---------------------------------------------------------------------------------------------------------------//
}

-(NSString *)decodeMessage:(UIImage *)img
{
    //---Getting a reference to the image bytes----------------------------------------------------------------------//
    CGImageRef imageRef = img.CGImage;
    NSUInteger nWidth = CGImageGetWidth(imageRef);
    NSUInteger nHeight = CGImageGetHeight(imageRef);
    NSUInteger nBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, img.size.width, img.size.height, 8,nBytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = nWidth, .size.height = nHeight}, imageRef);
    
    UInt8* imgBytes = (UInt8*)CGBitmapContextGetData(bmContext);
    CFBitVectorRef imgBits = CFBitVectorCreate(NULL,imgBytes,nHeight*nWidth*32);
    CFRetain(imgBits);
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Getting a reference to the image bits-----------------------------------------------------------------------//
    
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Create a bit vector, mutable and non-mutable for the decoded message----------------------------------------//
    CFBitVectorRef messageBits = CFBitVectorCreate(NULL, imgBytes, _messageSize);
    CFRetain(messageBits);
    CFMutableBitVectorRef messageBitsMut = CFBitVectorCreateMutableCopy(CFGetAllocator(messageBits), _messageSize, messageBits);
    //---------------------------------------------------------------------------------------------------------------//
    
    //---Decoding message from image to bit array--------------------------------------------------------------------//
    NSUInteger imgBitsIter;
    for (NSUInteger i = 0; i < _messageSize; i++)
    {
        imgBitsIter = (8*(i+1))-1;
        CFBitVectorSetBitAtIndex(messageBitsMut, i, CFBitVectorGetBitAtIndex(imgBits, imgBitsIter));
    }
    //---------------------------------------------------------------------------------------------------------------//
    NSData *picStringData = [_trans transformedValue:CFBridgingRelease(messageBits)];
    NSString *picString = [[NSString alloc] initWithData:picStringData encoding:NSUTF8StringEncoding];
    return picString;
}
@end

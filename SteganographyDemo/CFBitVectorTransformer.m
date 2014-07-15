//
//  CFBitVectorTransformer.m
//  SteganographyDemo
//
//  Created by App-Lab on 7/15/14.
//  Copyright (c) 2014 SteganosarusRextMessaging. All rights reserved.
//

#import "CFBitVectorTransformer.h"

#define kBitsPerByte    8


@implementation CFBitVectorTransformer


+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

/* CFBitVectorRef -> NSData */
- (id)transformedValue:(id)value
{
    if (!value) return nil;
    if ([value isKindOfClass:[NSData class]]) return value;
    
    /* Prepare the bit vector. */
    CFBitVectorRef bitVector = (__bridge CFBitVectorRef)value;
    CFIndex bitVectorCount = CFBitVectorGetCount(bitVector);
    
    /* Prepare the data buffer. */
    NSMutableData *bitData = [NSMutableData data];
    unsigned char bitVectorSegment = 0;
    NSUInteger bytesPerSegment = sizeof(char);
    NSUInteger bitsPerSegment = bytesPerSegment * kBitsPerByte;
    
    for (CFIndex bitIndex = 0; bitIndex < bitVectorCount; bitIndex++) {
        /* Shift the bit into the segment the appropriate number of places. */
        CFBit bit = CFBitVectorGetBitAtIndex(bitVector, bitIndex);
        int segmentShift = bitIndex % bitsPerSegment;
        bitVectorSegment |= bit << segmentShift;
        
        /* If this is the last bit we can squeeze into the segment, or it's the final bit, append the segment to the data buffer. */
        if (segmentShift == bitsPerSegment - 1 || bitIndex == bitVectorCount - 1) {
            [bitData appendBytes:&bitVectorSegment length:bytesPerSegment];
            bitVectorSegment = 0;
        }
    }
    
    return [NSData dataWithData:bitData];
}

/* NSData -> CFBitVectorRef */
- (id)reverseTransformedValue:(id)value
{
    if (!value) return NULL;
    if (![value isKindOfClass:[NSData class]]) return NULL;
    
    /* Prepare the data buffer. */
    NSData *bitData = (NSData *)value;
    char *bitVectorSegments = (char *)[bitData bytes];
    NSUInteger bitDataLength = [bitData length];
    
    /* Prepare the bit vector. */
    CFIndex bitVectorCapacity = bitDataLength * kBitsPerByte;
    CFMutableBitVectorRef bitVector = CFBitVectorCreateMutable(kCFAllocatorDefault, bitVectorCapacity);
    CFBitVectorSetCount(bitVector, bitVectorCapacity);
    
    for (NSUInteger byteIndex = 0; byteIndex < bitDataLength; byteIndex++) {
        unsigned char bitVectorSegment = bitVectorSegments[byteIndex];
        
        /* Store each bit of this byte in the bit vector. */
        for (NSUInteger bitIndex = 0; bitIndex < kBitsPerByte; bitIndex++) {
            CFBit bit = bitVectorSegment & 1 << bitIndex;
            CFIndex bitVectorBitIndex = (byteIndex * kBitsPerByte) + bitIndex;
            CFBitVectorSetBitAtIndex(bitVector, bitVectorBitIndex, bit);
        }
    }
    
    return (__bridge_transfer id)bitVector;
}


@end
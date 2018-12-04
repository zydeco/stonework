//
//  PBWBitmap.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 25/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWObject.h"
#import "PBWGraphics.h"

@class PBWGraphicsContext;

typedef struct GBitmapDataRowInfo {
    uint32_t data; // pointer to first pixel in row
    int16_t min_x;
    int16_t max_x;
} GBitmapDataRowInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PBWBitmap : PBWObject

@property (nonatomic, assign) GRect bounds;
@property (nonatomic, assign) uint16_t bytesPerRow;
@property (nonatomic, assign) GBitmapFormat format;
@property (nonatomic, assign) uint32_t dataPtr;
@property (nonatomic, assign) uint32_t pixelPtr;
@property (nonatomic, assign) uint32_t palettePtr;
@property (nonatomic, assign) BOOL freeDataOnDestroy;
@property (nonatomic, assign) BOOL freePaletteOnDestroy;

- (instancetype)initWithRuntime:(PBWRuntime*)rt resourceID:(uint32_t)resourceID;
- (instancetype)initWithRuntime:(PBWRuntime*)rt dataPtr:(uint32_t)dataPtr;
- (instancetype)initWithRuntime:(PBWRuntime*)rt PNGPtr:(uint32_t)pngPtr size:(uint32_t)size;
- (instancetype)initWithRuntime:(PBWRuntime*)rt size:(GSize)size format:(GBitmapFormat)format;
- (instancetype)initWithRuntime:(PBWRuntime*)rt size:(GSize)size format:(GBitmapFormat)format palette:(uint32_t)palettePtr freeOnDestroy:(BOOL)freePalette;
- (instancetype)subBitmapWithRect:(GRect)rect;
- (instancetype)palettizedBitmapFrom1bit;
- (GBitmapDataRowInfo)infoForRow:(int16_t)y;
- (void)drawInRect:(GRect)rect context:(PBWGraphicsContext*)ctx;
- (void)invalidateCGImage;

@end

NS_ASSUME_NONNULL_END

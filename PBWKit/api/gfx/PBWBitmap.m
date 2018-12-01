//
//  PBWBitmap.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 25/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWBitmap.h"
#import "PBWRuntime.h"
#import "PBWApp.h"
#import "PBWGraphicsContext.h"

uint32_t pbw_api_gbitmap_get_bytes_per_row(pbw_ctx ctx, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    return bitmap.bytesPerRow;
}

uint32_t pbw_api_gbitmap_get_format(pbw_ctx ctx, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    return bitmap.format;
}

uint32_t pbw_api_gbitmap_get_data(pbw_ctx ctx, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    return bitmap.pixelPtr;
}

uint32_t pbw_api_gbitmap_set_data(pbw_ctx ctx, uint32_t bitmap_ptr, uint32_t data_ptr, uint32_t format, uint32_t row_size_bytes) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    bool free_on_destroy = !!(pbw_cpu_stack_peek(ctx->cpu, 0) & 0xff);
    bitmap.dataPtr = bitmap.pixelPtr = data_ptr;
    bitmap.format = format & 0xff;
    bitmap.freeDataOnDestroy = free_on_destroy;
    bitmap.bytesPerRow = row_size_bytes & 0xffff;
    return 0;
}

uint32_t pbw_api_gbitmap_get_bounds(pbw_ctx ctx, uint32_t retptr, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    RETURN_GRECT(bitmap.bounds);
    return 0;
}

uint32_t pbw_api_gbitmap_set_bounds(pbw_ctx ctx, uint32_t bitmap_ptr, ARG_GRECT(bounds)) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    bitmap.bounds = UNPACK_GRECT(bounds);
    return 0;
}

uint32_t pbw_api_gbitmap_get_palette(pbw_ctx ctx, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    return bitmap.palettePtr;
}

uint32_t pbw_api_gbitmap_set_palette(pbw_ctx ctx, uint32_t bitmap_ptr, uint32_t palette_ptr, uint32_t free_on_destroy) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    bitmap.palettePtr = palette_ptr;
    bitmap.freePaletteOnDestroy = !!(free_on_destroy & 0xff);
    return 0;
}

uint32_t pbw_api_gbitmap_create_with_resource(pbw_ctx ctx, uint32_t resource_id) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime resourceID:resource_id];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_with_data(pbw_ctx ctx, uint32_t data_ptr) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime dataPtr:data_ptr];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_as_sub_bitmap(pbw_ctx ctx, uint32_t base_bitmap_ptr, ARG_GRECT(sub_rect)) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(base_bitmap_ptr)];
    PBWBitmap *newBitmap = [bitmap subBitmapWithRect:UNPACK_GRECT(sub_rect)];
    return newBitmap.tag;
}

uint32_t pbw_api_gbitmap_create_from_png_data(pbw_ctx ctx, uint32_t png_ptr, uint32_t png_size) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime PNGPtr:png_ptr size:png_size];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_blank(pbw_ctx ctx, uint32_t size, uint32_t format) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime size:UNPACK_SIZE(size) format:format & 0xff];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_blank_2bit(pbw_ctx ctx, uint32_t size, uint32_t format) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime size:UNPACK_SIZE(size) format:format & 0xff];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_blank_with_palette(pbw_ctx ctx, uint32_t size, uint32_t format, uint32_t palette_ptr, uint32_t free_on_destroy) {
    PBWBitmap *bitmap = [[PBWBitmap alloc] initWithRuntime:ctx->runtime size:UNPACK_SIZE(size) format:format & 0xff palette:palette_ptr freeOnDestroy:!!(free_on_destroy & 0xff)];
    return bitmap.tag;
}

uint32_t pbw_api_gbitmap_create_palettized_from_1bit(pbw_ctx ctx, uint32_t src_bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(src_bitmap_ptr)];
    PBWBitmap *newBitmap = [bitmap palettizedBitmapFrom1bit];
    return newBitmap.tag;
}

uint32_t pbw_api_gbitmap_destroy(pbw_ctx ctx, uint32_t bitmap_ptr) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    [bitmap destroy];
    return 0;
}

uint32_t pbw_api_gbitmap_get_data_row_info(pbw_ctx ctx, uint32_t retptr, uint32_t bitmap_ptr, uint32_t y) {
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmap_ptr)];
    GBitmapDataRowInfo info = [bitmap infoForRow:y & 0xffff];
    void *result = pbw_ctx_get_pointer(ctx, retptr);
    OSWriteLittleInt32(result, 0, info.data);
    OSWriteLittleInt16(result, 4, info.min_x);
    OSWriteLittleInt16(result, 6, info.max_x);
    return 0;
}

uint8_t BlendColor(uint16_t src, uint8_t dst) {
    unsigned int srcR = (src >> 12) & 3;
    unsigned int srcG = (src >> 7) & 3;
    unsigned int srcB = (src >> 2) & 3;
    unsigned int dstR = (dst >> 4) & 3;
    unsigned int dstG = (dst >> 2) & 3;
    unsigned int dstB = dst & 3;
    unsigned int alpha = (dst >> 6) & 3;
    dstR = (alpha * srcR + (3 - alpha) * dstR) / 3;
    dstG = (alpha * srcG + (3 - alpha) * dstG) / 3;
    dstB = (alpha * srcB + (3 - alpha) * dstB) / 3;
    return 0b11000000 | (dstR << 4) | (dstG << 2) | dstB;
}

static const uint8_t PBWBitmapIdentityPalette[256] = {
    0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
    0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,
    0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,
    0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f,
    0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f,
    0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x5b,0x5c,0x5d,0x5e,0x5f,
    0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f,
    0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x7b,0x7c,0x7d,0x7e,0x7f,
    0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f,
    0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f,
    0xa0,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xab,0xac,0xad,0xae,0xaf,
    0xb0,0xb1,0xb2,0xb3,0xb4,0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xbb,0xbc,0xbd,0xbe,0xbf,
    0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xcb,0xcc,0xcd,0xce,0xcf,
    0xd0,0xd1,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xdf,
    0xe0,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,0xee,0xef,
    0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfd,0xfe,0xff
};
static const uint32_t PBWBitmapNativePalette[256] = {
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff
};

@implementation PBWBitmap
{
    CGImageRef _cgImage;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt resourceID:(uint32_t)resourceID {
    NSData *resource = [rt.app resourceWithID:resourceID];
    if (resource == nil) return nil;
    pbw_ctx ctx = rt.runtimeContext;
    if (self = [super initWithRuntime:rt]) {
        _dataPtr = pbw_api_malloc(ctx, (uint32_t)resource.length);
        _freeDataOnDestroy = YES;
        memcpy(pbw_ctx_get_pointer(ctx, _dataPtr), resource.bytes, resource.length);
        [self decodeNativeImage:(uint32_t)resource.length];
    }
    return self;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt dataPtr:(uint32_t)dataPtr {
    if (self = [super initWithRuntime:rt]) {
        _dataPtr = dataPtr;
        _freeDataOnDestroy = NO;
        [self decodeNativeImage:0];
    }
    return self;}

- (instancetype)initWithRuntime:(PBWRuntime*)rt PNGPtr:(uint32_t)pngPtr size:(uint32_t)size {
    if (self = [super initWithRuntime:rt]) {
        _dataPtr = pngPtr;
        _freeDataOnDestroy = NO;
        [self decodePNGWithSize:size];
    }
    return self;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt size:(GSize)size format:(GBitmapFormat)format {
    self = [self initWithRuntime:rt size:size format:format palette:0 freeOnDestroy:NO];
    return self;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt size:(GSize)size format:(GBitmapFormat)format palette:(uint32_t)palettePtr freeOnDestroy:(BOOL)freePalette {
    if (self = [self initWithRuntime:rt size:size format:format]) {
        uint32_t paletteSize = 0;
        switch (format) {
            case GBitmapFormat1BitPalette:
                paletteSize = 2;
            case GBitmapFormat1Bit:
                _bytesPerRow = (size.w + 7) / 8;
                break;
            case GBitmapFormat2BitPalette:
                paletteSize = 4;
                _bytesPerRow = (size.w + 3) / 4;
                break;
            case GBitmapFormat4BitPalette:
                paletteSize = 16;
                _bytesPerRow = (size.w + 1) / 2;
                break;
            case GBitmapFormat8Bit:
                _bytesPerRow = size.w;
                break;
            case GBitmapFormat8BitCircular:
            default:
                __builtin_trap();
                break;
        }
        pbw_ctx ctx = rt.runtimeContext;
        uint32_t totalSize = _bytesPerRow * size.h;
        if (palettePtr == 0) totalSize += paletteSize;
        _dataPtr = _pixelPtr = pbw_api_malloc(ctx, totalSize);
        _freeDataOnDestroy = YES;
        if (palettePtr) {
            _palettePtr = palettePtr;
            _freePaletteOnDestroy = freePalette;
        } else {
            _palettePtr = paletteSize ? _dataPtr + paletteSize : 0;
            _freePaletteOnDestroy = NO;
        }
    }
    return self;
}

- (instancetype)subBitmapWithRect:(GRect)rect {
    PBWBitmap *subBitmap = [[PBWBitmap alloc] initWithRuntime:_runtime];
    subBitmap->_freeDataOnDestroy = NO;
    subBitmap->_freePaletteOnDestroy = NO;
    subBitmap->_format = _format;
    subBitmap->_bytesPerRow = _bytesPerRow;
    subBitmap->_dataPtr = _dataPtr;
    subBitmap->_pixelPtr = _pixelPtr;
    subBitmap->_palettePtr = _palettePtr;
    subBitmap->_bounds = GRect(_bounds.origin.x + rect.origin.x, _bounds.origin.y + rect.origin.y, rect.size.w, rect.size.h);
    grect_clip(&subBitmap->_bounds, &_bounds);
    return subBitmap;
}

- (instancetype)palettizedBitmapFrom1bit {
    __builtin_trap();
    return nil;
}

- (void)destroy {
    pbw_ctx ctx = self.runtime.runtimeContext;
    if (_dataPtr && _freeDataOnDestroy) pbw_api_free(ctx, _dataPtr);
    if (_palettePtr && _freePaletteOnDestroy) pbw_api_free(ctx, _palettePtr);
    [super destroy];
}

- (void)decodePNGWithSize:(uint32_t)dataSize {
    pbw_ctx ctx = _runtime.runtimeContext;
    void *imageData = pbw_ctx_get_pointer(ctx, _dataPtr);
    // draw image into context
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageData, dataSize, NULL);
    CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    uint32_t width = (uint32_t)CGImageGetWidth(image);
    uint32_t height = (uint32_t)CGImageGetHeight(image);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef decodeContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(decodeContext, CGRectMake(0, 0, width, height), image);
    CGImageRelease(image);
    // decode as 8-bit
    if (_freeDataOnDestroy) pbw_api_free(ctx, _dataPtr);
    _dataPtr = pbw_api_malloc(ctx, width * height);
    imageData = pbw_ctx_get_pointer(ctx, _dataPtr);
    uint8_t *pngData = CGBitmapContextGetData(decodeContext);
    uint8_t *nextPixel = imageData;
    for (int y=0; y < height; y++) {
        for (int x=0; x < width; x++) {
            *nextPixel = 0xc0 | ((pngData[1] & 0xc0) >> 2) | ((pngData[2] & 0xc0) >> 4) | ((pngData[3] & 0xc0) >> 6);
            nextPixel += 1;
            pngData += 4;
        }
    }
    CGContextRelease(decodeContext);
    _bytesPerRow = width;
    _format = GBitmapFormat8Bit;
    _bounds = GRect(0, 0, width, height);
    _palettePtr = 0;
    _pixelPtr = _dataPtr;
}

- (void)decodeNativeImage:(uint32_t)dataSize {
    pbw_ctx ctx = _runtime.runtimeContext;
    const void *imageData = pbw_ctx_get_pointer(ctx, _dataPtr);
    if (dataSize >= 16 && memcmp(imageData, "\211PNG\r\n\032\n", 8) == 0) {
        // PNG image
        [self decodePNGWithSize:dataSize];
    } else {
        _bytesPerRow = OSReadLittleInt16(imageData, 0);
        uint16_t flags = OSReadLittleInt16(imageData, 2);
        _format = (flags >> 1) & 0x1f;
        _bounds = GRect(OSReadLittleInt16(imageData, 4),
                        OSReadLittleInt16(imageData, 6),
                        OSReadLittleInt16(imageData, 8),
                        OSReadLittleInt16(imageData, 10));
        _pixelPtr = _dataPtr + 12;
        if (_format == GBitmapFormat1BitPalette ||
            _format == GBitmapFormat2BitPalette ||
            _format == GBitmapFormat4BitPalette) {
            _palettePtr = _pixelPtr + (_bytesPerRow * _bounds.size.h);
        } else {
            _palettePtr = 0;
        }
    }
}

- (GBitmapDataRowInfo)infoForRow:(int16_t)y {
    GBitmapDataRowInfo info;
    info.data = _pixelPtr + (_bytesPerRow * y);
    if (_format == GBitmapFormat8BitCircular) {
        // TODO: support circular bitmaps
        __builtin_trap();
    }
    info.min_x = 0;
    info.max_x = _bounds.size.w - 1;
    return info;
}

- (void)invalidateCGImage {
    CGImageRelease(_cgImage);
    _cgImage = NULL;
}

- (CGImageRef)CGImage {
    if (_cgImage == NULL) {
        size_t bitsPerPixel, lastColor;
        switch (_format) {
            case GBitmapFormat1BitPalette:
                bitsPerPixel = 1;
                lastColor = 1;
                break;
            case GBitmapFormat1Bit:
                bitsPerPixel = 1;
                lastColor = 1;
                break;
            case GBitmapFormat2BitPalette:
                bitsPerPixel = 2;
                lastColor = 3;
                break;
            case GBitmapFormat4BitPalette:
                bitsPerPixel = 4;
                lastColor = 15;
                break;
            case GBitmapFormat8Bit:
                bitsPerPixel = 8;
                lastColor = 255;
                break;
            case GBitmapFormat8BitCircular:
                bitsPerPixel = 8;
                lastColor = 255;
            default:
                __builtin_trap();
                break;
        }
        uint8_t *colorTable = calloc(lastColor+1, 3);
        memcpy(colorTable, "\0\0\0\xff\xff\xff", 6);
        CGColorSpaceRef baseColorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorSpaceRef colorSpace = CGColorSpaceCreateIndexed(baseColorSpace, lastColor, colorTable);
        CGColorSpaceRelease(baseColorSpace);
        free(colorTable);
        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, pbw_ctx_get_pointer(_runtime.runtimeContext, _pixelPtr), _bytesPerRow * _bounds.size.h, NULL);
        _cgImage = CGImageCreate(_bounds.size.w, _bounds.size.h, bitsPerPixel, bitsPerPixel, _bytesPerRow, colorSpace, 0, dataProvider, NULL, false, kCGRenderingIntentDefault);
        CGDataProviderRelease(dataProvider);
        CGColorSpaceRelease(colorSpace);
    }
    return _cgImage;
}

- (void)drawInRect:(GRect)rect context:(nonnull PBWGraphicsContext *)graphicsCongext {
    CGContextRef cg = graphicsCongext->cgContext;
    pbw_ctx ctx = _runtime.runtimeContext;
    uint32_t *fbuf = CGBitmapContextGetData(cg);
    const uint8_t *palette;
    grect_standardize(&rect);
    
    // Determine actual palette to use and stuff like bit length/mask
    uint8_t bits_per_pixel;
    switch (_format) {
        case GBitmapFormat1Bit:
        case GBitmapFormat1BitPalette:
            bits_per_pixel = 1;
            break;
        case GBitmapFormat2BitPalette:
            bits_per_pixel = 2;
            break;
        case GBitmapFormat4BitPalette:
            bits_per_pixel = 4;
            break;
        case GBitmapFormat8Bit:
        case GBitmapFormat8BitCircular:
        default:
            bits_per_pixel = 8;
            break;
    }
    uint8_t index_mask = (1 << bits_per_pixel) - 1;
    uint8_t pixels_per_byte = 8 / bits_per_pixel;
    GCompOp comp_op = graphicsCongext.compositingMode;
    static const uint8_t bw_palettes[][2] = { // uint8 is easier to declare for constants
        [GCompOpAssign] =         { GColorBlackARGB8, GColorWhiteARGB8 },
        [GCompOpAssignInverted] = { GColorWhiteARGB8, GColorBlackARGB8},
        [GCompOpAnd] =            { GColorBlackARGB8, GColorClearARGB8 },
        [GCompOpOr] =             { GColorClearARGB8, GColorWhiteARGB8 },
        [GCompOpClear] =          { GColorClearARGB8, GColorWhiteARGB8 },
        [GCompOpSet] =            { GColorWhiteARGB8, GColorClearARGB8}
    };
    if (_format == GBitmapFormat1Bit) {
        palette = bw_palettes[comp_op];
    } else if (_palettePtr) {
        palette = pbw_ctx_get_pointer(ctx, _palettePtr);
    } else {
        palette = PBWBitmapIdentityPalette;
    }
    
    // Blit the bitmap
    size_t bytesPerScreenRow = CGBitmapContextGetBytesPerRow(cg);
    uint32_t *fb_line = fbuf + rect.origin.x + (rect.origin.y + rect.size.h - 1) * (bytesPerScreenRow/4);
    uint8_t* bm_first_line = pbw_ctx_get_pointer(ctx, _pixelPtr) + _bounds.origin.y * _bytesPerRow;
    GPoint src_offset = {
        .x = (rect.origin.x - rect.origin.x) % _bounds.size.w,
        .y = (rect.origin.y - rect.origin.y) % _bounds.size.h
    };
    
    for (int y = 0; y < rect.size.h; y++) {
        uint32_t *fb_pixel = fb_line;
        uint8_t *bm_line = bm_first_line + ((src_offset.y + y) % _bounds.size.h) * _bytesPerRow;
        
        for (int x = 0; x < rect.size.w; x++) {
            int src_x = _bounds.origin.x + (src_offset.x + x) % _bounds.size.w;
            uint8_t src_pixel_byte = bm_line[src_x / pixels_per_byte];
            int src_pixel_bit = (src_x % pixels_per_byte) * bits_per_pixel;
            int src_color_index = (src_pixel_byte >> src_pixel_bit) & index_mask;
            uint8_t color = comp_op == GCompOpAssign ? palette[src_color_index] : BlendColor(*fb_pixel, palette[src_color_index]);
            *fb_pixel = PBWBitmapNativePalette[color];
            fb_pixel++;
        }
        
        fb_line -= (bytesPerScreenRow/4);
    }
}

@end

//
//  PBWFont.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 01/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//  Text rendering adapted from neographics: https://github.com/pebble-dev/neographics
//

#import "PBWFont.h"
#import "PBWRuntime.h"
#import "PBWApp.h"
#import "PBWGraphics.h"
#import "PBWGraphicsContext.h"

uint32_t pbw_api_fonts_get_system_font(pbw_ctx ctx, uint32_t font_key) {
    PBWRuntime *runtime = ctx->runtime;
    const char *fontKeyStr = pbw_ctx_get_pointer(ctx, font_key);
    PBWFont *font = [runtime systemFontWithKey:@(fontKeyStr)];
    return font.tag;
}

uint32_t pbw_api_fonts_load_custom_font(pbw_ctx ctx, uint32_t res_handle) {
    PBWRuntime *runtime = ctx->runtime;
    PBWFont *font = [[PBWFont alloc] initWithRuntime:runtime resourceHandle:res_handle];
    if (font == nil) {
        font = [[PBWFont alloc] initWithRuntime:runtime fontKey:@"FONT_KEY_RENAISSANCE_09"];
    }
    return font.tag;
}

uint32_t pbw_api_fonts_unload_custom_font(pbw_ctx ctx, uint32_t font_handle) {
    PBWFont *font = ctx->runtime.objects[@(font_handle)];
    [font destroy];
    return 0;
}

uint32_t pbw_api_graphics_draw_text(pbw_ctx ctx, uint32_t gctx, uint32_t textPtr, uint32_t fontTag, uint32_t box_origin) {
    uint32_t box_size = pbw_cpu_stack_peek(ctx->cpu, 0);
    GTextOverflowMode overflowMode = pbw_cpu_stack_peek(ctx->cpu, 1) & 0xff;
    GTextAlignment alignment = pbw_cpu_stack_peek(ctx->cpu, 2) & 0xff;
    // TODO: uint32_t text_attributes = pbw_cpu_stack_peek(ctx->cpu, 3);
    GRect box = UNPACK_GRECT(box);
    PBWFont *font = ctx->runtime.objects[@(fontTag)];
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    const char *text = pbw_ctx_get_pointer(ctx, textPtr);
    [font drawText:text inContext:graphicsContext box:box withOverflowMode:overflowMode alignment:alignment attributes:nil];
    return 0;
}

#define __CODEPOINT_IGNORE_AT_LINE_END(a) ((a) == 32)
// Breaking after this character is a _good idea_
// (for example, breaking after spaces or hyphens is good)
// This is preferred to prebreaking. Hyphens after postbreakables are ignored.
// #define __CODEPOINT_GOOD_POSTBREAKABLE(a) (false)
#define __CODEPOINT_GOOD_POSTBREAKABLE(a) ((a) == 32)
// Breaking after this character is allowed
// (for example, you aren't allowed to break immediately before punctuation.)
#define __CODEPOINT_ALLOW_PREBREAKABLE(a) (!((a) == 32 || (a) == 33 || (a) == 34 || (a) == 44 || (a) == 46))
#define __CODEPOINT_NEEDS_HYPHEN_AFTER(a) (\
/* numbers          */ ((a) >= 0x30 && (a) <= 0x39) ||\
/* basic uppercase  */ ((a) >= 0x41 && (a) <= 0x5a) ||\
/* basic lowercase  */ ((a) >= 0x61 && (a) <= 0x7a) ||\
/* extended a and b */ ((a) >= 0x100 && (a) <= 0x24f) \
)

typedef struct GGlyphInfo {
    uint8_t width;
    uint8_t height;
    int8_t left_offset;
    int8_t top_offset;
    int8_t advance;
    uint8_t data[];
} __attribute__((__packed__)) GGlyphInfo;

typedef struct GFontHashTableEntry {
    uint8_t hash_value;
    uint8_t offset_table_size;
    uint16_t offset_table_offset;
} __attribute__((__packed__)) GFontHashTableEntry;

@implementation PBWFont
{
    uint8_t fontVersion, lineHeight;
    uint16_t numberOfGlyphs, wildcardCodepoint;
    uint8_t hashTableSize, codepointBytes;
    uint8_t fontInfoSize;
    uint8_t glyphOffsetSize;
    BOOL glyphRLEEncoded;
    NSData *fontData;
    BOOL isSystemFont;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt resourceHandle:(uint32_t)resourceHandle {
    if (self = [super initWithRuntime:rt]) {
        fontData = [rt.app resourceWithID:resourceHandle];
        if (![self loadFont]) {
            [self destroy];
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithRuntime:(PBWRuntime*)rt fontKey:(NSString*)fontKey {
    if (self = [super initWithRuntime:rt]) {
        fontData = [rt systemResourceWithKey:fontKey];
        isSystemFont = YES;
        if (![self loadFont]) {
            [self destroy];
            return nil;
        }
    }
    return self;
}

- (BOOL)loadFont {
    if (fontData == nil) {
        return NO;
    }
    const uint8_t *data = fontData.bytes;
    fontVersion = data[0];
    lineHeight = data[1];
    numberOfGlyphs = OSReadLittleInt16(data, 2);
    wildcardCodepoint = OSReadLittleInt16(data, 4);
    hashTableSize = 255;
    codepointBytes = 4;
    uint8_t fontFeatures = 0;
    if (fontVersion == 1) {
        // this is actually the offset table
        hashTableSize = numberOfGlyphs;
    }
    if (fontVersion >= 2) {
        hashTableSize = data[6];
        codepointBytes = data[7];
    }
    if (fontVersion >= 3) {
        fontInfoSize = data[8];
        fontFeatures = data[9];
    } else {
        fontInfoSize = fontVersion == 1 ? 6 : 8;
    }
    glyphOffsetSize = (fontFeatures & 0b01) ? 2 : 4;
    // TODO: support RLE-encoded fonts
    glyphRLEEncoded = (fontFeatures & 0b10);
    
    return YES;
}

- (const GGlyphInfo*)infoForGlyph:(uint32_t)codepoint {
    const uint8_t *data = (const uint8_t*)fontData.bytes + fontInfoSize;
    uint8_t offsetTableItemLength = glyphOffsetSize + codepointBytes;
    const GFontHashTableEntry *hash_data;
    if (fontVersion == 1) {
        // v1 has no hash table, offset table is {uint16_t codepoint, uint16_t offset}
        uint16_t searchCodepoint = codepoint;
        const uint8_t * offset_entry = bsearch_b(&searchCodepoint, data, hashTableSize, 4, ^int(const void * a, const void * b) {
            return OSReadLittleInt16(a, 0) - OSReadLittleInt16(b, 0);
        });
        if (offset_entry == NULL && searchCodepoint != wildcardCodepoint) return [self infoForGlyph:wildcardCodepoint];
        if (offset_entry == NULL) __builtin_trap();
        assert(OSReadLittleInt16(offset_entry, 0) == searchCodepoint);
        data += 4 * hashTableSize;
        data += 4 * OSReadLittleInt16(offset_entry, 2);
        return (const GGlyphInfo*)data;
    } else {
        hash_data = (const GFontHashTableEntry*)(data + (codepoint % hashTableSize) * sizeof(GFontHashTableEntry));
    }
    
    data += (hashTableSize * sizeof(GFontHashTableEntry));
    
    if (hash_data->hash_value != (codepoint % hashTableSize)) {
        // There was no hash table entry with the correct hash. Fall back to tofu.
        return (const GGlyphInfo *) (data + offsetTableItemLength * numberOfGlyphs + 4);
    }
    
    const uint8_t * offset_entry = data + hash_data->offset_table_offset;
    
    uint16_t iters = 0; // theoretical possibility of 255 entries in an offset
    // table mean that we can't use a uint8 for safety
    while ((codepointBytes == 2
            ? OSReadLittleInt16(offset_entry, 0)
            : OSReadLittleInt32(offset_entry, 0)) != codepoint &&
           iters < hash_data->offset_table_size) {
        offset_entry += offsetTableItemLength;
        iters++;
    }
    
    if ((codepointBytes == 2
         ? OSReadLittleInt16(offset_entry, 0)
         : OSReadLittleInt32(offset_entry, 0)) != codepoint)
        // We couldn't find the correct entry. Fall back to tofu.
        return (const GGlyphInfo *) (data + offsetTableItemLength * numberOfGlyphs + 4);
    
    data += offsetTableItemLength * numberOfGlyphs +
    (glyphOffsetSize == 2
     ? OSReadLittleInt16(offset_entry,codepointBytes)
     : OSReadLittleInt32(offset_entry,codepointBytes));
    
    return (const GGlyphInfo*)data;
}

- (void)drawGlyph:(const GGlyphInfo*)glyph inContext:(PBWGraphicsContext*)graphicsContext atPoint:(GPoint)p {
    int16_t minx = 0, miny = 0;
    int16_t maxx = _runtime.screenSize.width, maxy = _runtime.screenSize.height;
    p.x += glyph->left_offset;
    p.y += glyph->top_offset;
    const uint8_t *glyphData = glyph->data;
    if (fontVersion == 1) glyphData += 3;
    for (uint8_t y = 0; y < glyph->height; y++)
        for (uint8_t x = 0; x < glyph->width; x++)
            if (glyphData[(y*glyph->width+x)/8] & (1 << ((y*glyph->width+x) % 8)) &&
                p.x + x >= minx && p.x + x < maxx &&
                p.y + y >= miny && p.y + y < maxy)
                [graphicsContext setPixel:GPoint(p.x + x, p.y + y) toColor:graphicsContext.textColor];
}

- (void)drawCharacter:(uint32_t)codepoint inContext:(PBWGraphicsContext *)graphicsContext atPoint:(GPoint)point {
    const GGlyphInfo *glyphInfo = [self infoForGlyph:codepoint];
    [self drawGlyph:glyphInfo inContext:graphicsContext atPoint:point];
}

- (GPoint)_drawTextLine:(const char *)text inContext:(PBWGraphicsContext*)ctx origin:(GPoint)text_origin start:(uint32_t)idx end:(uint32_t)idx_end {
    while (idx < idx_end) {
        uint32_t codepoint = 0;
        if (text[idx] & 0b10000000) {
            if ((text[idx] & 0b11100000) == 0b11000000) {
                codepoint = ((text[idx  ] &  0b11111) << 6)
                +  (text[idx+1] & 0b111111);
                idx += 2;
            } else if ((text[idx] & 0b11110000) == 0b11100000) {
                codepoint = ((text[idx  ] &   0b1111) << 12)
                + ((text[idx+1] & 0b111111) << 6)
                +  (text[idx+2] & 0b111111);
                idx += 3;
            } else if ((text[idx] & 0b11111000) == 0b11110000) {
                codepoint = ((text[idx  ] &    0b111) << 18)
                + ((text[idx+1] & 0b111111) << 12)
                + ((text[idx+2] & 0b111111) << 6)
                +  (text[idx+3] & 0b111111);
                idx += 4;
            } else {
                idx += 1;
            }
        } else {
            codepoint = text[idx];
            idx += 1;
        }
        const GGlyphInfo * glyph = [self infoForGlyph:codepoint];
        [self drawGlyph:glyph inContext:ctx atPoint:text_origin];
        if (fontVersion == 1) {
            text_origin.x += glyph->data[2];
        } else {
            text_origin.x += glyph->advance;
        }
    }
    return text_origin;
}

- (void)drawText:(const char *)text inContext:(PBWGraphicsContext*)ctx box:(GRect)box withOverflowMode:(GTextOverflowMode)overflowMode alignment:(GTextAlignment)alignment attributes:(nullable id)attributes {
    // Rendering of text is done as follows:
    // - We store the index of the beginning of the line.
    // - We iterate over characters in the line.
    //    - Whenever an after-breakable character occurs, we make a note of it.
    //    - When the width of the line is exceeded, we actually render
    //      the line (up to the breakable character.)
    //    - We then use that character's index as the beginning
    //      of the next line.
    // TODO: attributes
    GPoint char_origin = box.origin, line_origin = box.origin;
    line_origin.y += 1;
    const GGlyphInfo *space = [self infoForGlyph:' '];
    uint32_t line_begin = 0, index = 0, next_index = 0;
    int32_t last_breakable_index = -1, last_renderable_index = -1,
    lenience = space->advance;
    const GGlyphInfo *hyphen = [self infoForGlyph:'-'], *glyph = NULL;
    
    uint32_t codepoint = 0, next_codepoint = 0, last_codepoint = 0,
    last_renderable_codepoint = 0, last_breakable_codepoint = 0;
    while (text[index] != '\0') {
        // We're following the 2003 UTF-8 definition:
        // 0b0xxxxxxx
        // 0b110xxxxx 0b10xxxxxx
        // 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
        // 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
        if (text[index] == '\n'
            && (char_origin.x + (__CODEPOINT_NEEDS_HYPHEN_AFTER(codepoint) ? hyphen->advance : 0)
                <= box.origin.x + box.size.w)) {
                [self _drawTextLine:text inContext:ctx origin:line_origin start:line_begin end:index];
                char_origin.x = box.origin.x;
                char_origin.y += self->lineHeight;
                last_breakable_index = last_renderable_index = -1;
                line_origin = char_origin;
                index = next_index = index + 1;
                line_begin = index;
                continue;
            }
        
        if (text[index] & 0b10000000) { // begin of multibyte character
            if ((text[index] & 0b11100000) == 0b11000000) {
                next_codepoint = ((text[index  ] &  0b11111) << 6)
                +  (text[index+1] & 0b111111);
                next_index += 2;
            } else if ((text[index] & 0b11110000) == 0b11100000) {
                next_codepoint = ((text[index  ] &   0b1111) << 12)
                + ((text[index+1] & 0b111111) << 6)
                +  (text[index+2] & 0b111111);
                next_index += 3;
            } else if ((text[index] & 0b11111000) == 0b11110000) {
                next_codepoint = ((text[index  ] &    0b111) << 18)
                + ((text[index+1] & 0b111111) << 12)
                + ((text[index+2] & 0b111111) << 6)
                +  (text[index+3] & 0b111111);
                next_index += 4;
            } else {
                next_codepoint = 0;
                next_index += 1;
            }
        } else {
            next_codepoint = text[index];
            next_index += 1;
        }
        const GGlyphInfo *next_glyph = [self infoForGlyph:next_codepoint];
        
        
        // Debugging:
        // n_graphics_context_set_text_color(ctx, n_GColorLightGray);
        // n_graphics_font_draw_glyph(ctx, next_glyph, char_origin);
        // n_graphics_context_set_text_color(ctx, n_GColorBlack);
        
        // We now know what codepoint the next character has.
        
        if (glyph) {
            if (__CODEPOINT_ALLOW_PREBREAKABLE(codepoint)) {
                if (char_origin.x +
                    (__CODEPOINT_NEEDS_HYPHEN_AFTER(last_codepoint)
                     ? hyphen->advance : 0)
                    <= box.origin.x + box.size.w) {
                    last_renderable_index = index;
                    last_renderable_codepoint = codepoint;
                }
            }
            if (__CODEPOINT_GOOD_POSTBREAKABLE(codepoint) &&
                ((
                  (__CODEPOINT_IGNORE_AT_LINE_END(codepoint) &&
                   char_origin.x - glyph->advance <= box.origin.x + box.size.w) ||
                  char_origin.x <= box.origin.x + box.size.w))) {
                last_breakable_index = index;
                last_breakable_codepoint = codepoint;
            }
        }
        
        // Done processing the two available characters.
        
        index = next_index;
        last_codepoint = codepoint;
        codepoint = next_codepoint;
        glyph = next_glyph;
        char_origin.x += glyph->advance;
        
        if ((char_origin.x + (__CODEPOINT_NEEDS_HYPHEN_AFTER(codepoint) ? hyphen->advance : 0) - lenience
             > box.origin.x + box.size.w)) {
            if (last_breakable_index > 0) {
                switch (alignment) {
                    case GTextAlignmentCenter:
                        [self _drawTextLine:text
                                  inContext:ctx
                                     origin:GPoint(line_origin.x + (box.size.w - char_origin.x - 3)/2, line_origin.y)
                                      start:line_begin
                                        end:last_breakable_index];
                        break;
                    case GTextAlignmentRight:
                        [self _drawTextLine:text
                                  inContext:ctx
                                     origin:GPoint(line_origin.x + box.size.w - char_origin.x - 3, line_origin.y)
                                      start:line_begin
                                        end:last_breakable_index];
                        break;
                    default:
                        [self _drawTextLine:text
                                  inContext:ctx
                                     origin:line_origin
                                      start:line_begin
                                        end:last_breakable_index];
                }
                index = next_index = last_breakable_index;
                char_origin.x = box.origin.x;
                char_origin.y += self->lineHeight;
                line_begin = last_breakable_index;
                last_breakable_index = last_renderable_index = -1;
                line_origin = char_origin;
            } else if (last_renderable_index > 0) {
                GPoint end;
                switch (alignment) {
                    case GTextAlignmentCenter:
                        end = [self _drawTextLine:text
                                        inContext:ctx
                                           origin:GPoint(line_origin.x + (box.size.w - char_origin.x - 3)/2, line_origin.y)
                                            start:line_begin
                                              end:last_renderable_index];
                        break;
                    case GTextAlignmentRight:
                        end = [self _drawTextLine:text
                                        inContext:ctx
                                           origin:GPoint(line_origin.x + box.size.w - char_origin.x - 3, line_origin.y)
                                            start:line_begin
                                              end:last_renderable_index];
                        break;
                    default:
                        end = [self _drawTextLine:text
                                        inContext:ctx
                                           origin:line_origin
                                            start:line_begin
                                              end:last_renderable_index];
                }
                if (__CODEPOINT_NEEDS_HYPHEN_AFTER(last_renderable_codepoint) || true) { // TODO
                    [self drawGlyph:hyphen inContext:ctx atPoint:end];
                }
                index = next_index = last_renderable_index;
                char_origin.x = box.origin.x;
                char_origin.y += self->lineHeight;
                line_begin = last_renderable_index;
                last_breakable_index = last_renderable_index = -1;
                line_origin = char_origin;
            } else {
                [self drawGlyph:hyphen inContext:ctx atPoint:line_origin];
                line_begin = next_index;
                char_origin.x = box.origin.x;
                char_origin.y += self->lineHeight;
                line_origin = char_origin;
            }
            if (line_origin.y + self->lineHeight >= box.origin.y + box.size.h) {
                return;
            }
        }
        index += (0 * line_begin * last_breakable_codepoint);
    }
    if (index != line_begin) {
        switch (alignment) {
            case GTextAlignmentCenter:
                [self _drawTextLine:text
                          inContext:ctx
                             origin:GPoint(line_origin.x + (box.size.w - char_origin.x - 3)/2, line_origin.y)
                              start:line_begin
                                end:index];
                break;
            case GTextAlignmentRight:
                [self _drawTextLine:text
                          inContext:ctx
                             origin:GPoint(line_origin.x + box.size.w - char_origin.x - 3, line_origin.y)
                              start:line_begin
                                end:index];
                break;
            case GTextAlignmentLeft:
            default:
                [self _drawTextLine:text
                          inContext:ctx
                             origin:line_origin
                              start:line_begin
                                end:index];
        }
    }
}

- (void)destroy {
    if (isSystemFont) {
        return;
    }
    [super destroy];
}

@end

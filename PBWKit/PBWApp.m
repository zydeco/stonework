//
//  PBWApp.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWApp.h"
#import "PBWBundle.h"


/**
 * A pebble app binary header
 */
#define APP_NAME_SIZE 32

struct PblAppHeader {
    char magic[8];
    uint8_t struct_version_major, struct_version_minor;
    uint8_t sdk_version_major, sdk_version_minor;
    uint8_t process_version_major, process_version_minor;
    uint16_t load_size;
    uint32_t offset;
    uint32_t crc;
    char name[APP_NAME_SIZE];
    char company[APP_NAME_SIZE];
    uint32_t icon_resource_id;
    uint32_t sym_table_addr;
    uint32_t flags;
    uint32_t reloc_list_start; // removed in 9.0
    uint32_t num_reloc_entries;
    // added in 8.1
    uint8_t uuid[16];
    // added in 8.2
    uint32_t resource_crc;
    uint32_t resource_timestamp;
    // added in 16.0
    uint16_t virtual_size;
};

#define PblAppHeaderAtLeast(s, major, minor) ((s.struct_version_major == major && s.struct_version_minor > minor) || s.struct_version_major > major)

@implementation PBWApp
{
    NSString *_basePath;
    struct PblAppHeader appHeader;
}

- (instancetype)initWithBundle:(PBWBundle *)bundle platform:(PBWPlatformType)platform {
    NSString *platformName = NSStringFromPBWPlatformType(platform);
    if (platformName == nil) {
         @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Invalid platform type %d",(int)platform] userInfo:nil];
    }
    NSString *manifestFileName = @"manifest.json";
    NSData *manifestData = [bundle dataAtPath:[platformName stringByAppendingPathComponent:manifestFileName]];
    NSString *basePath;
    if (manifestData == nil && platform == PBWPlatformTypeAplite) {
        // try root directory
        manifestData = [bundle dataAtPath:manifestFileName];
        basePath = @"";
    } else {
        basePath = [platformName stringByAppendingString:@"/"];
    }
    if (manifestData == nil) {
        return nil;
    }
    NSDictionary<NSString*,id> *manifest = [NSJSONSerialization JSONObjectWithData:manifestData options:0 error:NULL];
    if (manifest == nil) {
        return nil;
    }
    if (self = [super init]) {
        _bundle = bundle;
        _platform = platform;
        _manifest = manifest;
        _basePath = basePath;
        NSDictionary<NSString*,id> *appManifest = manifest[@"application"];
        _appBinary = [_bundle dataAtPath:[basePath stringByAppendingString: appManifest[@"name"]]];
        if (appManifest[@"resources"]) {
            _resourcePack = [_bundle dataAtPath:[basePath stringByAppendingString: appManifest[@"resources"]]];
        } else {
            _resourcePack = nil;
        }
        [self loadAppHeader];
        // TODO: check integrity of app image and resources?
    }
    return self;
}

- (void)loadAppHeader {
    const uint8_t *header = _appBinary.bytes;
    char buf[APP_NAME_SIZE+1];
    bzero(buf, sizeof(buf));
    bzero(&appHeader, sizeof(appHeader));
    memcpy(&appHeader, header, 8);
    appHeader.struct_version_major = header[0x08];
    appHeader.struct_version_minor = header[0x09];
    appHeader.sdk_version_major = header[0x0a];
    appHeader.sdk_version_minor = header[0x0b];
    appHeader.process_version_major = header[0x0c];
    appHeader.process_version_minor = header[0x0d];
    appHeader.load_size = OSReadLittleInt16(header, 0x0e);
    appHeader.offset = OSReadLittleInt32(header, 0x10);
    appHeader.crc = OSReadLittleInt32(header, 0x14);
    memcpy(appHeader.name, header + 0x18, 32);
    memcpy(appHeader.company, header + 0x38, 32);
    appHeader.icon_resource_id = OSReadLittleInt32(header, 0x58);
    appHeader.sym_table_addr = OSReadLittleInt32(header, 0x5c);
    appHeader.flags = OSReadLittleInt32(header, 0x60);
    int pos = 0x64;
    if PblAppHeaderAtLeast(appHeader, 9, 0) {
        appHeader.reloc_list_start = appHeader.load_size;
    } else {
        appHeader.reloc_list_start = OSReadLittleInt32(header, pos);
        pos += 4;
    }
    appHeader.num_reloc_entries = OSReadLittleInt32(header, pos); pos += 4;
    if PblAppHeaderAtLeast(appHeader, 8, 1) {
        memcpy(appHeader.uuid, header + pos, 16); pos += 16;
        _UUID = [[NSUUID alloc] initWithUUIDBytes:appHeader.uuid];
    } else {
        _UUID = nil;
    }
    if PblAppHeaderAtLeast(appHeader, 8, 2) {
        appHeader.resource_crc = OSReadLittleInt32(header, pos); pos += 4;
        appHeader.resource_timestamp = OSReadLittleInt32(header, pos); pos += 4;
    }
    if PblAppHeaderAtLeast(appHeader, 16, 0) {
        appHeader.virtual_size = OSReadLittleInt16(header, pos);
    } else {
        appHeader.virtual_size = appHeader.load_size;
    }
    
    memcpy(buf, appHeader.name, APP_NAME_SIZE);
    _appName = [NSString stringWithUTF8String:buf];
    memcpy(buf, appHeader.company, APP_NAME_SIZE);
    _companyName = [NSString stringWithUTF8String:buf];
}

#pragma mark - Accessors

- (NSString *)description {
    return [NSString stringWithFormat:@"<PBWApp %@ (%@ %d.%d), platform=%@>", _UUID, _appName, (int)appHeader.process_version_major, (int)appHeader.process_version_minor, NSStringFromPBWPlatformType(_platform)];
}

- (uint16_t)virtualSize {
    return appHeader.virtual_size;
}

- (uint16_t)loadSize {
    return appHeader.load_size;
}

- (uint32_t)entryPoint {
    return appHeader.offset;
}

- (uint32_t)symbolTableOffset {
    return appHeader.sym_table_addr;
}

- (uint32_t)relocTableOffset {
    return appHeader.reloc_list_start;
}

- (uint32_t)numRelocEntries {
    return appHeader.num_reloc_entries;
}

- (NSString *)appVersion {
    return [NSString stringWithFormat:@"%d.%d", (int)appHeader.process_version_major, (int)appHeader.process_version_minor];
}

- (uint32_t)appFlags {
    return appHeader.flags;
}

@end

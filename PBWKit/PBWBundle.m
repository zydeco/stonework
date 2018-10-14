//
//  PBWBundle.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWBundle.h"
#import <minizip/unzip.h>
#import "PBWApp.h"

@implementation PBWBundle
{
    unzFile zf;
}

+ (instancetype)bundleWithURL:(NSURL *)url {
    return [[PBWBundle alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _bundleURL = url;
        zf = unzOpen(url.path.fileSystemRepresentation);
        [self loadAppInfo];
    }
    return self;
}

- (void)dealloc {
    if (zf) {
        unzClose(zf);
    }
}

- (void)loadAppInfo {
    NSData *appInfo = [self dataAtPath:@"appinfo.json"];
    if (appInfo) {
        _infoDictionary = [NSJSONSerialization JSONObjectWithData:appInfo options:0 error:NULL];
        _targetPlatforms = PBWPlatformTypeNone;
        for (NSString *platform in _infoDictionary[@"targetPlatforms"]) {
            _targetPlatforms |= PBWPlatformTypeFromString(platform);
        }
        if (_targetPlatforms == PBWPlatformTypeNone) {
            _targetPlatforms = PBWPlatformTypeAplite;
        }
        _UUID = [[NSUUID alloc] initWithUUIDString:_infoDictionary[@"uuid"]];
        _shortName = _infoDictionary[@"shortName"];
        _longName = _infoDictionary[@"longName"];
        _versionLabel = _infoDictionary[@"versionLabel"];
        _companyName = _infoDictionary[@"companyName"];
        NSDictionary<NSString*,id> *watchApp = _infoDictionary[@"watchapp"];
        _isWatchFace = [watchApp[@"watchface"] boolValue];
    } else {
        // legacy app
        PBWApp *app = [[PBWApp alloc] initWithBundle:self platform:PBWPlatformTypeAplite];
        _targetPlatforms = PBWPlatformTypeAplite;
        _UUID = app.UUID;
        _shortName = app.appName;
        _longName = app.appName;
        _versionLabel = app.appVersion;
        _companyName = app.companyName;
        _isWatchFace = app.appFlags & 1;
    }
    

}

- (nullable NSData*)dataAtPath:(NSString*)path {
    unz_file_info fileInfo;
    if (unzLocateFile(zf, path.fileSystemRepresentation, NULL) == UNZ_OK &&
        unzGetCurrentFileInfo(zf, &fileInfo, NULL, 0, NULL, 0, NULL, 0) == UNZ_OK) {
        void *data = malloc(fileInfo.uncompressed_size);
        unzOpenCurrentFile(zf);
        unzReadCurrentFile(zf, data, fileInfo.uncompressed_size);
        unzCloseCurrentFile(zf);
        return [NSData dataWithBytesNoCopy:data length:fileInfo.uncompressed_size freeWhenDone:YES];
    } else {
        return nil;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<PBWBundle %@: %@ %@>", _UUID, _longName, _versionLabel];
}

@end

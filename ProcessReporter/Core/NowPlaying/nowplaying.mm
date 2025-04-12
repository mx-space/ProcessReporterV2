// nowplaying.m
// ProcessReporter
// https://github.com/davidmurray/ios-reversed-headers/blob/master/MediaRemote/MediaRemote.h
// Created by Innei on 2023/7/2.
#import "nowplaying.h"
#import "MRContent.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef void (*MRMediaRemoteGetNowPlayingInfoFunction)(
    dispatch_queue_t queue, void (^handler)(NSDictionary *information));
typedef void (*MRMediaRemoteSetElapsedTimeFunction)(double time);
typedef void (*MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)(
    dispatch_queue_t queue, void (^handler)(Boolean isPlaying));
typedef void (*MRMediaRemoteGetNowPlayingApplicationPIDFunction)(
    dispatch_queue_t queue, void (^handler)(int PID));

typedef enum { GET, GET_RAW, MEDIA_COMMAND, SEEK } Command;

@implementation NowPlaying

+ (NSDictionary *)getNowPlayingInfo {
  __block NSDictionary *result = nil;
  dispatch_group_t group = dispatch_group_create();
  dispatch_group_enter(group);

  @autoreleasepool {
    CFURLRef ref = (__bridge CFURLRef)
        [NSURL fileURLWithPath:
                   @"/System/Library/PrivateFrameworks/MediaRemote.framework"];
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, ref);

    MRMediaRemoteGetNowPlayingInfoFunction MRMediaRemoteGetNowPlayingInfo =
        (MRMediaRemoteGetNowPlayingInfoFunction)
            CFBundleGetFunctionPointerForName(
                bundle, CFSTR("MRMediaRemoteGetNowPlayingInfo"));

    MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction
        MRMediaRemoteGetNowPlayingApplicationIsPlaying =
            (MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)
                CFBundleGetFunctionPointerForName(
                    bundle,
                    CFSTR("MRMediaRemoteGetNowPlayingApplicationIsPlaying"));

    MRMediaRemoteGetNowPlayingApplicationPIDFunction
        MRMediaRemoteGetNowPlayingApplicationPID =
            (MRMediaRemoteGetNowPlayingApplicationPIDFunction)
                CFBundleGetFunctionPointerForName(
                    bundle, CFSTR("MRMediaRemoteGetNowPlayingApplicationPID"));

    __block BOOL isPlaying = NO;
    dispatch_group_enter(group);
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^(Boolean playing) {
          isPlaying = playing;
          dispatch_group_leave(group);
        });

    __block int pid = 0;
    dispatch_group_enter(group);
    MRMediaRemoteGetNowPlayingApplicationPID(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^(int applicationPID) {
          pid = applicationPID;
          dispatch_group_leave(group);
        });

    MRMediaRemoteGetNowPlayingInfo(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^(NSDictionary *information) {
          if (information) {
            MRContentItem *item = [[objc_getClass("MRContentItem") alloc]
                initWithNowPlayingInfo:information];

            // 基本信息
            NSString *name =
                [information objectForKey:@"kMRMediaRemoteNowPlayingInfoTitle"];
            NSString *artist = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoArtist"];
            NSString *album =
                [information objectForKey:@"kMRMediaRemoteNowPlayingInfoAlbum"];
            NSString *genre =
                [information objectForKey:@"kMRMediaRemoteNowPlayingInfoGenre"];
            NSString *composer = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoComposer"];

            // 播放信息
            double elapsedTime = [[information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoElapsedTime"]
                doubleValue];
            double duration = [[information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoDuration"]
                doubleValue];
            double playbackRate = [[information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoPlaybackRate"]
                doubleValue];
            double startTime = [[information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoStartTime"]
                doubleValue];

            // 曲目信息
            NSNumber *trackNumber = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTrackNumber"];
            NSNumber *totalTrackCount = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTotalTrackCount"];
            NSNumber *discNumber = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoDiscNumber"];
            NSNumber *totalDiscCount = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTotalDiscCount"];
            NSNumber *chapterNumber = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoChapterNumber"];
            NSNumber *totalChapterCount = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTotalChapterCount"];

            // 队列信息
            NSNumber *queueIndex = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoQueueIndex"];
            NSNumber *totalQueueCount = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTotalQueueCount"];

            // 播放模式
            NSNumber *shuffleMode = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoShuffleMode"];
            NSNumber *repeatMode = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoRepeatMode"];

            // 其他信息
            NSString *mediaType = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoMediaType"];
            NSNumber *isMusicApp = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoIsMusicApp"];
            NSString *uniqueIdentifier = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoUniqueIdentifier"];
            NSDate *timestamp = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoTimestamp"];

            // 交互状态
            NSNumber *isAdvertisement = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoIsAdvertisement"];
            NSNumber *isBanned = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoIsBanned"];
            NSNumber *isInWishList = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoIsInWishList"];
            NSNumber *isLiked = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoIsLiked"];
            NSNumber *prohibitsSkip = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoProhibitsSkip"];

            // 电台信息
            NSString *radioStationIdentifier = [information
                objectForKey:
                    @"kMRMediaRemoteNowPlayingInfoRadioStationIdentifier"];
            NSString *radioStationHash = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoRadioStationHash"];

            // 功能支持
            NSNumber *supportsFastForward15Seconds =
                [information objectForKey:@"kMRMediaRemoteNowPlayingInfoSupport"
                                          @"sFastForward15Seconds"];
            NSNumber *supportsRewind15Seconds = [information
                objectForKey:
                    @"kMRMediaRemoteNowPlayingInfoSupportsRewind15Seconds"];
            NSNumber *supportsIsBanned = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoSupportsIsBanned"];
            NSNumber *supportsIsLiked = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoSupportsIsLiked"];

            // 获取播放状态
            NSString *playbackState = nil;
            if ([item respondsToSelector:@selector(metadata)]) {
              id metadata = [item valueForKey:@"metadata"];
              if ([metadata respondsToSelector:@selector(playbackState)]) {
                playbackState = [NSString
                    stringWithFormat:@"%ld", (long)[[metadata
                                                 valueForKey:@"playbackState"]
                                                 integerValue]];
              }
            }

            // 获取 bundle identifier
            NSString *bundleIdentifier = nil;
            if ([item respondsToSelector:@selector(metadata)]) {
              id metadata = [item valueForKey:@"metadata"];
              if ([metadata respondsToSelector:@selector(bundleIdentifier)]) {
                bundleIdentifier = [metadata valueForKey:@"bundleIdentifier"];
              }
            }

            // 获取专辑封面
            NSData *artworkData = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoArtworkData"];
            NSString *artworkMIMEType = [information
                objectForKey:@"kMRMediaRemoteNowPlayingInfoArtworkMIMEType"];

            // 处理专辑封面数据
            NSString *artworkBase64 = @"";
            if (artworkData) {
              // 如果是 PNG 或 JPEG 数据，直接转换为 base64
              if ([artworkMIMEType isEqualToString:@"image/png"] ||
                  [artworkMIMEType isEqualToString:@"image/jpeg"]) {
                artworkBase64 = [artworkData base64EncodedStringWithOptions:0];
              } else {
                // 如果不是标准图片格式，尝试转换为 PNG
                NSImage *image = [[NSImage alloc] initWithData:artworkData];
                if (image) {
                  NSData *pngData = [image TIFFRepresentation];
                  artworkBase64 = [pngData base64EncodedStringWithOptions:0];
                }
              }
            }

            // 获取进程信息
            NSRunningApplication *app = [NSRunningApplication
                runningApplicationWithProcessIdentifier:pid];
            NSString *processName = app.localizedName ?: @"";
            NSString *executablePath = app.executableURL.path ?: @"";

            result = @{
              // 基本信息
              @"name" : name ?: @"",
              @"artist" : artist ?: @"",
              @"album" : album ?: @"",
              @"genre" : genre ?: @"",
              @"composer" : composer ?: @"",

              // 播放信息
              @"elapsedTime" : @(elapsedTime),
              @"duration" : @(duration),
              @"playbackRate" : @(playbackRate),
              @"startTime" : @(startTime),
              @"playbackState" : playbackState ?: @"",

              // 曲目信息
              @"trackNumber" : trackNumber ?: @0,
              @"totalTrackCount" : totalTrackCount ?: @0,
              @"discNumber" : discNumber ?: @0,
              @"totalDiscCount" : totalDiscCount ?: @0,
              @"chapterNumber" : chapterNumber ?: @0,
              @"totalChapterCount" : totalChapterCount ?: @0,

              // 队列信息
              @"queueIndex" : queueIndex ?: @0,
              @"totalQueueCount" : totalQueueCount ?: @0,

              // 播放模式
              @"shuffleMode" : shuffleMode ?: @0,
              @"repeatMode" : repeatMode ?: @0,

              // 其他信息
              @"mediaType" : mediaType ?: @"",
              @"isMusicApp" : isMusicApp ?: @NO,
              @"uniqueIdentifier" : uniqueIdentifier ?: @"",
              @"timestamp" : timestamp ?: [NSDate date],
              @"bundleIdentifier" : bundleIdentifier ?: @"",

              // 交互状态
              @"isAdvertisement" : isAdvertisement ?: @NO,
              @"isBanned" : isBanned ?: @NO,
              @"isInWishList" : isInWishList ?: @NO,
              @"isLiked" : isLiked ?: @NO,
              @"prohibitsSkip" : prohibitsSkip ?: @NO,

              // 电台信息
              @"radioStationIdentifier" : radioStationIdentifier ?: @"",
              @"radioStationHash" : radioStationHash ?: @"",

              // 功能支持
              @"supportsFastForward15Seconds" : supportsFastForward15Seconds
                  ?: @NO,
              @"supportsRewind15Seconds" : supportsRewind15Seconds ?: @NO,
              @"supportsIsBanned" : supportsIsBanned ?: @NO,
              @"supportsIsLiked" : supportsIsLiked ?: @NO,

              // 专辑封面
              @"artworkData" : artworkBase64,
              @"artworkMIMEType" : artworkMIMEType ?: @"",

              // 播放状态
              @"isPlaying" : @(isPlaying),

              // 进程信息
              @"processID" : @(pid),
              @"processName" : processName,
              @"executablePath" : executablePath,
            };
          }
          dispatch_group_leave(group);
        });
  }

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  return result;
}

@end

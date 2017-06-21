//
//  UNDownLoadManager.m
//  DownloadDemo
//
//  Created by Len on 2017/6/21.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import "UNDownLoadManager.h"
#import "NSURLSession+CheckResumeData.h"
#import <CommonCrypto/CommonDigest.h>

@interface UNDownLoadManager() <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSData *resumeData;

@end

@implementation UNDownLoadManager

+ (UNDownLoadManager *)sharedInstance
{
    static UNDownLoadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (NSURLSession *)backgroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"com.aixiaoqi.unitoys.BackgroundSession";
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    return session;
}

- (void)setResumeData:(NSData *)resumeData
{
    _resumeData = resumeData;
    [[NSUserDefaults standardUserDefaults] setObject:resumeData forKey:@"DownResumeData"];
}

- (void)beginDownWithUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [self backgroundURLSession];
    self.downloadTask = [session downloadTaskWithRequest:request];
    [self.downloadTask resume];
}

- (void)pauseDownloadUrl:(NSString *)urlString
{
    __weak __typeof(self) wSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        __strong __typeof(wSelf) sSelf = wSelf;
        sSelf.resumeData = resumeData;
    }];
}

- (void)continueDownloadUrl:(NSString *)urlString
{
    if (!_resumeData) {
        _resumeData = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownResumeData"];
    }
    if (self.resumeData) {
        if (kSystemVersionValue >= 10.0) {
            self.downloadTask = [[self backgroundURLSession] downloadTaskWithCorrectResumeData:_resumeData];
        } else {
            self.downloadTask = [[self backgroundURLSession] downloadTaskWithResumeData:_resumeData];
        }
        [self.downloadTask resume];
        _resumeData = nil;
    }else{
        if (urlString) {
            [self beginDownWithUrl:urlString];
        }
    }
}

#pragma mark ---- NSURLSessionDownloadDelegate
//下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"URLSession:downloadTask:didWriteData:totalBytesWritten");
    NSLog(@"Progress:%.2f%%",(CGFloat)totalBytesWritten / totalBytesExpectedToWrite * 100);
    NSString *strProgress = [NSString stringWithFormat:@"%.2f",(CGFloat)totalBytesWritten / totalBytesExpectedToWrite];
    [self postDownlaodProgressNotification:strProgress];
}

//下载恢复时调用
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    self.isDownLoading = YES;
    NSLog(@"URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes");
    NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

//下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"下载完成====URLSession:downloadTask:didFinishDownloadingToURL===%@", [location path]);
    self.isDownLoading = YES;
    NSString *locationString = [location path];
    NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [self getMD5:[downloadTask.currentRequest.URL absoluteString]], [self getSuffix:[downloadTask.currentRequest.URL absoluteString]]]];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:finalLocation error:&error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    self.isDownLoading = NO;
    NSLog(@"URLSession:didCompleteWithError");
    if (error) {
        NSLog(@"error:%@",error);
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            self.resumeData = resumeData;
        }else if(error.code == -1002){
            [self downloadErrorNotification];
        }
    } else {
        [self postDownlaodProgressNotification:@"1"];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
}

- (void)postDownlaodProgressNotification:(NSString *)strProgress {
    NSDictionary *userInfo = @{@"progress":strProgress};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadProgressNotification" object:nil userInfo:userInfo];
    });
}

- (void)downloadErrorNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UNDownLoadError" object:@"Reset"];
}

- (NSString *)getPathWithUrlString:(NSString *)urlString
{
    NSString *suffix = [self getSuffix:urlString];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject];
    if (suffix) {
        return [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [self getMD5:urlString], suffix]];
    }else{
        return [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self getMD5:urlString]]];
    }
}

//此方式获取后缀不准确
- (NSString *)getSuffix:(NSString *)urlString
{
    NSArray *array = [urlString componentsSeparatedByString:@"."];
    return array.lastObject;
}

- (NSString *)getMD5:(NSString *)string
{
    const char *cStr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

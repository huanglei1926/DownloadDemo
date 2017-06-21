//
//  UNDownLoadManager.h
//  DownloadDemo
//
//  Created by Len on 2017/6/21.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CompletionHandlerType)();

@interface UNDownLoadManager : NSObject

+ (UNDownLoadManager *)sharedInstance;

- (NSURLSession *)backgroundURLSession;

- (void)beginDownWithUrl:(NSString *)urlString;
- (void)pauseDownloadUrl:(NSString *)urlString;
- (void)continueDownloadUrl:(NSString *)urlString;

- (NSString *)getPathWithUrlString:(NSString *)urlString;

@property (nonatomic, assign) BOOL isDownLoading;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (readonly, nonatomic) NSData *resumeData;
@end

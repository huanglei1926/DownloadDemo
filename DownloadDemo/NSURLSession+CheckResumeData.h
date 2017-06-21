//
//  NSURLSession+CheckResumeData.h
//  DownloadDemo
//
//  Created by Len on 2017/6/21.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define kSystemVersionValue [[UIDevice currentDevice].systemVersion floatValue]

@interface NSURLSession (CheckResumeData)
- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;
@end

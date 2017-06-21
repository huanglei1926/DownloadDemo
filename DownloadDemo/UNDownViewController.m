//
//  UNDownViewController.m
//  DownloadDemo
//
//  Created by Len on 2017/6/20.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import "UNDownViewController.h"
#import "UNDownLoadManager.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface UNDownViewController ()
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) AVPlayerViewController *playerVC;
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation UNDownViewController

- (AVPlayerViewController *)playerVC
{
    if (!_playerVC) {
        _playerVC = [[AVPlayerViewController alloc] init];
    }
    return _playerVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    _urlString = @"http://pcclient.download.youku.com/ikumac/youkumac_1.2.6.06206.dmg";
//    _urlString = @"http://hz189cloud.oos-hz.ctyunapi.cn/934ad8ae-828d-475e-86e5-bcb7548cb97d?response-content-type=video/mp4&Expires=1498088520&response-content-disposition=attachment%3Bfilename%3D%22%C3%A7%C2%94%C2%9F%C3%A5%C2%8C%C2%96%C3%A5%C2%8D%C2%B1%C3%A6%C2%9C%C2%BA%C3%AF%C2%BC%C2%9A%C3%A5%C2%A4%C2%8D%C3%A4%C2%BB%C2%87.mp4%22&AWSAccessKeyId=95e6d363b6e2475aeecc&Signature=JtazA96MWw4DoNamusxNEdwGYM0%3D";
    _urlString = @"http://flv2.bn.netease.com/videolib3/1604/28/fVobI0704/SD/fVobI0704-mobile.mp4";
    
    CGFloat progress = 0;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"UrlDownLoadProgress"]) {
        progress = [[[NSUserDefaults standardUserDefaults] objectForKey:@"UrlDownLoadProgress"] floatValue];
    }
    self.progressView.progress = progress;
    
    if (progress == 1) {
        [self.downButton setTitle:@"打开" forState:UIControlStateNormal];
    }else if (progress > 0 && [UNDownLoadManager sharedInstance].isDownLoading) {
        [self.downButton setTitle:@"暂停" forState:UIControlStateNormal];
    }else if(progress == 0){
        [self.downButton setTitle:@"开始" forState:UIControlStateNormal];
    }else{
        [self.downButton setTitle:@"继续" forState:UIControlStateNormal];
    }
    
    [self.downButton addTarget:self action:@selector(downButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:@"DownloadProgressNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadError:) name:@"UNDownLoadError" object:nil];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"UNDownLoadError" object:@"Reset"];
}

- (void)updateDownloadProgress:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGFloat fProgress = [userInfo[@"progress"] floatValue];
    [[NSUserDefaults standardUserDefaults] setObject:@(fProgress) forKey:@"UrlDownLoadProgress"];
    self.progressView.progress = fProgress;
    if (fProgress == 1.0) {
        [self.downButton setTitle:@"打开" forState:UIControlStateNormal];
    }
}

- (void)downloadError:(NSNotification *)noti
{
    if ([noti.object isEqualToString:@"Reset"]) {
        [self resetDown];
    }
}

- (void)deleteAction:(UIButton *)button
{
    button.enabled = NO;
    [self deleteData];
    button.enabled = YES;
}

- (void)startDownAction
{
    [[UNDownLoadManager sharedInstance] beginDownWithUrl:_urlString];
}

- (void)pauseDownAction
{
    [[UNDownLoadManager sharedInstance] pauseDownloadUrl:_urlString];
}

- (void)continueDownAction
{
    [[UNDownLoadManager sharedInstance] continueDownloadUrl:_urlString];
}

- (void)downButtonAction:(UIButton *)button
{
    if ([button.titleLabel.text isEqualToString:@"继续"]) {
        //继续下载
        NSLog(@"点击继续");
        [self continueDownAction];
        [button setTitle:@"暂停" forState:UIControlStateNormal];
    }else if ([button.titleLabel.text isEqualToString:@"暂停"]){
        //暂停下载
        NSLog(@"点击暂停");
        [self pauseDownAction];
        [button setTitle:@"继续" forState:UIControlStateNormal];
    }else if ([button.titleLabel.text isEqualToString:@"开始"]){
        //开始下载
        NSLog(@"点击开始");
        [self startDownAction];
        [button setTitle:@"暂停" forState:UIControlStateNormal];
    }else if ([button.titleLabel.text isEqualToString:@"打开"]){
        NSLog(@"点击打开");
        NSLog(@"打开文件----%@", [[UNDownLoadManager sharedInstance] getPathWithUrlString:_urlString]);
        [self startPlayer:[[UNDownLoadManager sharedInstance] getPathWithUrlString:_urlString]];
    }
}

- (void)startPlayer:(NSString *)urlString
{
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@",urlString]];
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:url];
    self.player = [[AVPlayer alloc]initWithPlayerItem:item];
    self.playerVC.player = self.player;
    [self presentViewController:self.playerVC animated:YES completion:nil];
}

- (void)resetDown
{
    self.progressView.progress = 0;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UrlDownLoadProgress"];
    [self.downButton setTitle:@"开始" forState:UIControlStateNormal];
}

- (void)deleteData
{
    //删除
    NSString *path = [[UNDownLoadManager sharedInstance] getPathWithUrlString:_urlString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //删除成功清除进度
        [self resetDown];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"删除出错---%@", error);
        }else{
            NSLog(@"删除成功");
        }
    }else{
        NSLog(@"未发现文件");
    }
}

- (IBAction)dismissAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

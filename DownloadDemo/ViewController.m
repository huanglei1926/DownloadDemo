//
//  ViewController.m
//  DownloadDemo
//
//  Created by Len on 2017/6/21.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import "ViewController.h"
#import "UNDownViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)presentVcAction:(UIButton *)sender {
    UNDownViewController *downVc = [[UNDownViewController alloc] init];
    [self presentViewController:downVc animated:YES completion:nil];
}


@end

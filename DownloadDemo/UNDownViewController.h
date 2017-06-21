//
//  UNDownViewController.h
//  DownloadDemo
//
//  Created by Len on 2017/6/20.
//  Copyright © 2017年 lei.huang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UNDownViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

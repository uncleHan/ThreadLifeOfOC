//
//  HHSaveLifeThread.m
//  线程保活
//
//  Created by 韩恒 on 2019/12/9.
//  Copyright © 2019 韩恒. All rights reserved.
//

#import "HHSaveLifeThread.h"


// 监控线程生命周期
@interface MYThread : NSThread

@end


@implementation MYThread

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end


@interface HHSaveLifeThread ()

@property (nonatomic,strong)MYThread *thread;
///  控制runloop是否停止循环
@property (nonatomic,assign)BOOL isStop;

@end


@implementation HHSaveLifeThread


- (instancetype)init{
    if (self = [super init]) {
        //默认runloop不停止,一直循环
        self.isStop = NO;
        __weak typeof(self) weakSelf = self;
        self.thread = [[MYThread alloc]initWithBlock:^{
            //保住此线程的命,获取当前线程的 runloop ,添加任务
            NSPort *port = [[NSPort alloc]init];
            [[NSRunLoop currentRunLoop]addPort:port forMode:NSDefaultRunLoopMode];
            while (weakSelf && !weakSelf.isStop) {
                [[NSRunLoop currentRunLoop]runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }];
        [self.thread start];
    }
    return self;
}


// 执行任务
- (void)executeTaskWithBlock:(void (^)(void))taskBlock{
    if(!self.thread || !taskBlock) return;
    [self performSelector:@selector(__executeTaskWithBlock:) onThread:self.thread withObject:taskBlock waitUntilDone:NO];
}

// 停止
- (void)stop{
    
    if (!self.thread) return;
    [self performSelector:@selector(__stopRunloop) onThread:self.thread withObject:nil waitUntilDone:YES];
}


- (void)dealloc{
    [self stop];
    NSLog(@"%s",__func__);
}

#pragma mark 私有api
/// 停止 runloop 循环
- (void)__stopRunloop{
    self.isStop = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
    self.thread= nil;
}


- (void)__executeTaskWithBlock:(void (^)(void))taskBlock{
    taskBlock();
}

@end

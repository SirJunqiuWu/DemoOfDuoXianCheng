//
//  ViewController.m
//  DemoOfNSOperation
//
//  Created by 吴 吴 on 15/12/17.
//  Copyright © 2015年 吴 吴. All rights reserved.
//

//1.1 iOS有三种多线程编程的技术，分别是：
//1.、NSThread
//2、Cocoa NSOperation （iOS多线程编程之NSOperation和NSOperationQueue的使用）
//3、GCD  全称：Grand Central Dispatch（ iOS多线程编程之Grand Central Dispatch(GCD)介绍和使用）
//这三种编程方式从上到下，抽象度层次是从低到高的，抽象度越高的使用越简单，也是Apple最推荐使用的。

#import "ViewController.h"

#define ImageUrl     @"http://static.51dy.ren/static/images/upload/2015-11-04/5639e8f3ec5fc.jpg"

@interface ViewController ()
{
    UIImageView *icon;
    
    /**
     *  当前票数
     */
    int tickets;
    /**
     *  售出票数
     */
    int count;
    
    NSThread* ticketsThreadOne;
    NSThread* ticketsThreadTwo;
    
    /**
     *  锁
     */
    NSCondition* ticketsCondition;
    NSLock *theLock;
}

@end

@implementation ViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"多线程";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatImageDirectory];
    [self setupUI];
//    [self downloadImage:ImageUrl];
    [self testNSThread];
//    [self testNSOperation];
//    [self testNSThreadSynchronized];
//    [self testGCD];
//    [self testDispatchGroupAsync];
//    [self testDispatchBarrierAsync];
//    [self testDispatchApply];
    
}

#pragma mark - 创建UI

- (void)setupUI {
    icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    icon.backgroundColor = [UIColor clearColor];
    [self.view addSubview:icon];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 刷新界面

- (void)uploadUI:(id)obj {
    if ([obj isKindOfClass:[UIImage class]])
    {
        icon.image = obj;
    }
}

#pragma mark - 自定义方法

- (void)downloadImage:(NSString *)imageUrl {
    UIImage *img = [self getImage];
    if (img == nil)
    {
        /**
         *  将数据流转化为图片
         */
        NSURL *url = [NSURL URLWithString:imageUrl];
        NSData *data = [[NSData alloc]initWithContentsOfURL:url];
        
        img = [UIImage imageWithData:data];
        
        /**
         *  压缩图片
         */
        NSData *imageData = UIImageJPEGRepresentation(img,0.5);
        
        /**
         *  将图片数据流写进指定文件夹
         */
        
        [self writeImageDataToImageDirectoryWithImageData:imageData];
    }
    
    /**
     * 在主线程中刷新UI,当然也可以调用其他线程刷新：performSelector:onThread:withObject:waitUntilDone:
     */
    [self performSelectorOnMainThread:@selector(uploadUI:) withObject:img waitUntilDone:YES];
}

#pragma mark - 多线程

/**
 *  NSThread 有两种直接创建方式：
 *  优点：NSThread 比其他两个轻量级
 *  缺点：需要自己管理线程的生命周期，线程同步。线程同步对数据的加锁会有一定的系统开销
 */
- (void)testNSThread {
    /**
     * 实例方法创建NSThread对象:先创建线程对象，然后再运行线程操作，在运行线程操作前可以设置线程的优先级等线程信息
     */
    NSThread *tempThread = [[NSThread alloc]initWithTarget:self selector:@selector(downloadImage:) object:ImageUrl];
    [tempThread start];
    
    /**
     *  类方法创建NSThread对象:直接创建线程并且开始运行线程
     */
    [NSThread detachNewThreadSelector:@selector(downloadImage:) toTarget:self withObject:ImageUrl];
}

- (void)testNSOperation {
    /**
     * 用NSInvocationOperation建了一个后台线程
     */
    NSInvocationOperation *tempOperation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(downloadImage:) object:ImageUrl];
    
    /**
     * 初始化NSOperationQueue队列
     */
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc]init];
    
    /**
     *  将后台线程加到队列中
     */
    [tempQueue addOperation:tempOperation];
}


/**
 *  Grand Central Dispatch 
 *  GCD的工作原理是：让程序平行排队的特定任务，根据可用的处理资源，安排他们在任何可用的处理器核心上执行任务。 一个任务可以是一个函数(function)或者是一个block。 GCD的底层依然是用线程实现，不过这样可以让程序员不用关注实现的细节。GCD中的FIFO队列称为dispatch queue，它可以保证先进来的任务先得到执行dispatch queue分为下面三种：1)Serial又称为private dispatch queues，同时只执行一个任务。Serial queue通常用于同步访问特定的资源或数据。当你创建多个Serial queue时，虽然它们各自是同步执行的，但Serial queue与Serial queue之间是并发执行的。2)Concurrent又称为global dispatch queue，可以并发地执行多个任务，但是执行完成的顺序是随机的。 3)Main dispatch queue它是全局可用的serial queue，它是在应用程序主线程上执行任务的。我们看看dispatch queue如何使用
 */
- (void)testGCD {
    /**
     *  为了避免界面在处理耗时的操作时卡死，比如读取网络数据，IO,数据库读写等，我们会在另外一个线程中处理这些操作，然后通知主线程更新界面。用GCD实现这个流程的操作比前面介绍的NSThread  NSOperation的方法都要简单.GCD会自动根据任务在多核处理器上分配资源，优化程序。
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /**
         *  耗时的操作
         */
        [self downloadImage:ImageUrl];
        
        NSURL *url = [NSURL URLWithString:ImageUrl];
        NSData *data = [[NSData alloc]initWithContentsOfURL:url];
        UIImage *img = [UIImage imageWithData:data];
        if (data !=nil)
        {
          dispatch_async(dispatch_get_main_queue(), ^{
              /**
               *  更新界面
               */
              icon.image = img;
          });
        }
    });
}


/**
 *  dispatch_group_async可以实现监听一组任务是否完成，完成后得到通知执行其他的操作。这个方法很有用，比如你执行三个下载任务，当三个任务都下载完成后你才通知界面说完成的了
 */
- (void)testDispatchGroupAsync {
    
    /**
     *  使用函数dispath_get_global_queue去得到队列
     */
    dispatch_queue_t allQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    /**
     * 创建一个组队列
     */
    dispatch_group_t group = dispatch_group_create();
    
    /**
     *  异步处理多个事件
     */
    dispatch_group_async(group, allQueue, ^{
        [NSThread sleepForTimeInterval:1];
         NSLog(@"任务一完成");
    });
    
    dispatch_group_async(group, allQueue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务二完成");
    });
    dispatch_group_async(group, allQueue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"任务三完成");
    });
    
    dispatch_group_notify(group, allQueue, ^{
        NSLog(@"任务都完成,刷新UI");
    });
}


/**
 *  多个任务按顺序执行
 */
- (void)testDispatchBarrierAsync {
    dispatch_group_t queue = dispatch_queue_create("gcdtest.rongfzh.yc", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"dispatch_async1");
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:4];
        NSLog(@"dispatch_async2");
    });
    dispatch_barrier_async(queue, ^{
        [NSThread sleepForTimeInterval:4];
        NSLog(@"dispatch_barrier_async");
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"dispatch_async3");  
    });
}


/**
 *  执行某个代码片段N次
 */
- (void)testDispatchApply{
    
    /**
     * 系统给每一个应用程序提供了三个concurrent dispatch queues。这三个并发调度队列是全局的，它们只有优先级的不同。因为是全局的，我们不需要去创建。我们只需要通过使用函数dispath_get_global_queue去得到队列
     */
   dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_apply(5, globalQ, ^(size_t index) {
       NSLog(@"index: %zu",index);
   });
}


#pragma mark - NSThread的线程同步

- (void)testNSThreadSynchronized {
    tickets = 100;
    count = 0;
    
    /**
     * 锁对象
     */
    theLock = [[NSLock alloc] init];
    ticketsCondition = [[NSCondition alloc] init];
    
    ticketsThreadOne = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [ticketsThreadOne setName:@"Thread-1"];
    [ticketsThreadOne start];
    
    
    ticketsThreadTwo = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [ticketsThreadTwo setName:@"Thread-2"];
    [ticketsThreadTwo start];
    
    NSThread *ticketsThreadthree = [[NSThread alloc] initWithTarget:self selector:@selector(run3) object:nil];
    [ticketsThreadthree setName:@"Thread-3"];
    [ticketsThreadthree start];
}

- (void)run3{
    /**
     * 线程的顺序执行他们都可以通过[ticketsCondition signal]; 发送信号的方式，在一个线程唤醒另外一个线程的等待。
     */
    while (YES)
    {
        [ticketsCondition lock];
        [NSThread sleepForTimeInterval:1];
        [ticketsCondition signal];
        [ticketsCondition unlock];
    }
}

- (void)run {
    while (TRUE)
    {
        /**
         *  上锁:如果没有线程同步的lock，卖票数可能是-1.加上lock之后线程同步保证了数据的正确性。
         */
        [theLock lock];
        [ticketsCondition lock];
        [ticketsCondition wait];
        if (tickets>=0)
        {
            [NSThread sleepForTimeInterval:0.09];
            count = 100 - tickets;
            NSLog(@"当前票数是:%d,售出:%d,线程名:%@",tickets,count,[[NSThread currentThread] name]);
            tickets--;
        }
        else
        {
            break;
        }
        [theLock unlock];
        [ticketsCondition unlock];
    }
}


#pragma mark - 存储路径

/**
 *  将图片数据流写入指定文件夹
 *
 *  @param data 图片数据流
 */
- (void)writeImageDataToImageDirectoryWithImageData:(NSData *)imageData {
    NSArray *pathsArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    
    /**
     *  获取该图片在图片文件下的唯一路径
     */
    NSString *path = [[pathsArr[0]stringByAppendingPathComponent:@"image"]stringByAppendingPathComponent:@"5639e8f3ec5fc"];
    
    BOOL writeSuccess = [imageData writeToFile:path atomically:YES];
    if (writeSuccess)
    {
        NSLog(@"数据写入成功");
    }
    else
    {
        /**
         *  写入失败，进行第二次写入
         */
        [imageData writeToFile:path atomically:YES];
    }
}

/**
 *  获取图片数据流
 *
 *  @return 图片数据流
 */
- (UIImage *)getImage {
    NSArray *pathsArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[pathsArr[0]stringByAppendingPathComponent:@"image"]stringByAppendingPathComponent:@"5639e8f3ec5fc"];
    
    UIImage *image= [UIImage imageWithContentsOfFile:path];
    return image;
}


/**
 *  沙盒目录下的document文件夹下创建image文件夹
 */
- (void)creatImageDirectory {
    NSArray *pathsArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = pathsArr[0];
    
    /**
     *  指定图片文件下该图片的唯一路径
     */
    path = [path stringByAppendingPathComponent:@"image"];
    
    BOOL isDir = NO;
    BOOL isExit = [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
    if (!isExit)
    {
        BOOL isSuccess = [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (isSuccess)
        {
            NSLog(@"文件夹创建成功");
        }
        else
        {
            NSLog(@"文件夹创建失败");
        }
    }
}

@end

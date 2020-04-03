# YBTaskScheduler 
[![Cocoapods](https://img.shields.io/cocoapods/v/YBTaskScheduler.svg)](https://cocoapods.org/pods/YBTaskScheduler)&nbsp;
[![Cocoapods](https://img.shields.io/cocoapods/p/YBTaskScheduler.svg)](https://github.com/indulgeIn/YBTaskScheduler)&nbsp;
[![License](https://img.shields.io/github/license/indulgeIn/YBTaskScheduler.svg)](https://github.com/indulgeIn/YBTaskScheduler)&nbsp;

iOS 任务调度器，为 CPU 和内存减负

技术原理博客：[iOS 任务调度器：为 CPU 和内存减负](https://www.jianshu.com/p/f2a610c77d26)

## 特性

- 命令模式：将任务用容器管理起来延迟执行，实现任务执行频率控制、任务总量控制。
- 策略模式：利用 C++ 栈、队列、优先队列实现三种调度策略，性能优越。
- 应用场景一：主线程任务量过大导致掉帧（利用组件为任务调度降频）。
- 应用场景二：短时间内执行的任务量过大，而某些任务失去了执行的意义（利用组件的任务淘汰策略）。
- 应用场景三：需要将任务按自定义的优先级调度（利用组件的优先队列策略）

## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'YBTaskScheduler'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 `<YBTaskScheduler/YBTaskScheduler.h>`。

若搜索不到库，可使用 rm ~/Library/Caches/CocoaPods/search_index.json 移除本地索引然后再执行安装，或者更新一下 CocoaPods 版本。

### 手动导入

1. 下载 YBTaskScheduler 文件夹所有内容并且拖入你的工程中。
2. 导入 `YBTaskScheduler.h`。


## 用法

可下载 DEMO 参考一个相册处理的案例。

### 基本使用

```objc
//初始化并选择任务调度策略
_scheduler = [YBTaskScheduler schedulerWithStrategy:YBTaskSchedulerStrategyLIFO];
//添加任务
[_scheduler addTask:^{
     /* 
     具体任务代码
     解压图片、裁剪图片、访问磁盘等 
     */
}];
```
注意该组件使用实例化方式使用，为了避免任务调度器提前释放，需要外部对其进行强持有（建议作为调用方的属性或实例变量）。

### 任务调度策略

任务调度策略有三种：
```objc
typedef NS_ENUM(NSInteger, YBTaskSchedulerStrategy) {
    YBTaskSchedulerStrategyLIFO,    //后进先出（后进任务优先级高）
    YBTaskSchedulerStrategyFIFO,    //先进先出（先进任务优先级高）
    YBTaskSchedulerStrategyPriority   //优先级调度（自定义任务的优先级）
};
```
首先要明确的是，业务中是想要执行`-addTask:`方法先添加的任务先调用，还是后添加的任务先调用。

比如在一个 UITableView 的列表中，每一个 Cell 都有一个将头像图片异步裁剪为圆角的任务，当快速滑动的时候，理所应当是后加入的任务应该调用，所以应该选择 YBTaskSchedulerStrategyLIFO。

当业务中的任务需要按照你自己指定的优先级来调度，就选择 YBTaskSchedulerStrategyPriority。

### 任务执行线程队列

若不显式的指定任务执行队列，组件会默认让这些任务并发执行（类似并行队列）。
你可以指定执行的队列，比如你只是想降低主线程任务的调用频率：
```objc
_scheduler.taskQueue = dispatch_get_main_queue();
```
如此，所有添加的任务都会在主队列执行。

### 任务淘汰机制

很多时候你需要淘汰掉一部分已经添加到`YBTaskScheduler`的任务。

比如上面举得在 UITableView 的 cell 中异步裁剪头像图片的例子，当用户快速滑动时，假设有 100 个任务添加到了任务调度器中，而前 90 个 cell 已经滑出了屏幕，它们的异步任务已经不需要了（建立在你不会缓存异步结果的前提下）：
```objc
_scheduler.maxNumberOfTasks = 20;
```
这里设置最大任务数量为 20，若添加的任务大于了这个数量，会删除掉优先级低的任务。
而不同的任务调度策略有不同的效果，比如 YBTaskSchedulerStrategyLIFO 策略会删除先加入的任务，YBTaskSchedulerStrategyFIFO 策略会删除后加入的任务，注意 YBTaskSchedulerStrategyPriority 暂时不支持任务淘汰机制（由于 C++ 优先队列不支持低优先级节点删除，后面考虑自己实现）。

### 任务调用频率控制

以下两个属性就能控制频率：
```objc
/* 每次执行的任务数量 */
@property (nonatomic, assign) NSUInteger executeNumber;
/* 执行频率（RunLoop 循环 executeFrequency 次执行一次任务） */
@property (nonatomic, assign) NSUInteger executeFrequency;
```
默认是每次 RunLoop 循环调用一个任务，比如你这么做：
```objc
_scheduler.executeNumber = 2;
_scheduler.executeFrequency = 5;
```
那么就表示 RunLoop 循环 5 次调用 2 个任务。




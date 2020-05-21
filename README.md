# XLScrollView

此项目是仿百度POI搜索时，分级滑动的效果，当做是一次学习的过程，来把这样一个效果实现！

先来放一波效果图。。。。。

![放个小版的GIF，大概看一下](https://upload-images.jianshu.io/upload_images/728436-706eb15c27925670.gif?imageMogr2/auto-orient/strip)

在百度地图搜索POI，展示POI列表时，会有这种效果，当滑到底部时，地图会联动缩放，这里先针对列表TableView做一下分析，所以没有添加这个效果，但是是小问题，先不用管。

**想要做成这种效果，肯定是需要两层滚动scrollView来实现。底层scrollView来实现分段效果，内层scrollView来实现列表展示的作用。**
**这里两个竖直滚动的视图，就会发生滑动冲突。**

### 这里有一些关键点：
* 底层的滑动View，如何做成上中下三段效果，不能用`isPagingEnabled`属性来实现，这里用了`scrollViewWillEndDragging`代理加动画来实现。
* 当底层scrollView滚动至最底部时，要求不遮挡地图的触摸事件，可以正常的与地图进行交互。这里用到了响应链`hitTest:withEvent`方法来解决。
* 双层滚动视图的滑动冲突。

**为了方便，scrollView的分段三个级别用，1级，2级，3级来说明。**

#### 控件层级介绍：
![](https://upload-images.jianshu.io/upload_images/728436-a3eee921eb775b30.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 黑色层：当为2级时，可以点击button，跳转到3级。
* 红色层：scrollView，提供分段滑动效果。
* 白色层：展示数据列表。

分析具体实现
-----------
### 1、上中下三段效果实现
分页效果首先想到就是`isPagingEnabled `属性，但是他有局限性，不能随便分页，只能在每个分页大小一样的情况下使用，所以这里不能使用。
这里主要用到了scrollView的代理方法。
```
//将要结束手势拖拽，开始减速
func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
```
这个代理是手指离开屏幕开始减速，并且提供了两个参数：
* velocity：手指离开屏幕时的初速度。若不为0，则会减速到`targetContentOffset`表示的目的地。
* targetContentOffset：指针类型，表示要到达的目的地。因为是指针类型，所以我们可以修改他的值，这就是我们可以实现分段效果的重点。

直接上代码，看一下这里面的计算逻辑。

```
//这里处理滑动手势结束后，页面跳转效果
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //不是底层scrollView，则退出！
        if scrollView == self.tableView {
            return
        }
        let currentOffsetY = scrollView.contentOffset.y
        var gotoPointY: CGFloat = 0
        
        //计算滑动手势结束后，页面准备的位置 ---（这里只分析了速度velocity不为0时，当速度为0时，用下面的方式计算位置）
        if currentOffsetY <= contentOffsetMaxY && currentOffsetY > contentOffsetMidY {
            
            if velocity.y > 0 {
                gotoPointY = contentOffsetMaxY
            }else if velocity.y < 0{
                gotoPointY = contentOffsetMidY
            }
        }else if currentOffsetY < contentOffsetMidY && currentOffsetY > contentOffsetMinY {
            
            if velocity.y > 0 {
                gotoPointY = contentOffsetMidY
            }else{
                gotoPointY = contentOffsetMinY
            }
        }else{
            gotoPointY = contentOffsetMinY
        }
        //当滑动速度为0时，判断当前位置距离哪一级别最近
        if velocity.y == 0 {
            
            var distance: CGFloat = contentOffsetMaxY
            let currentOffsetArray = [contentOffsetMinY, contentOffsetMidY, contentOffsetMaxY]
            for item in currentOffsetArray {
                
                let temp = abs(item - currentOffsetY)
                if distance > temp {
                    
                    distance = temp
                    gotoPointY = item
                }
            }
        }
        //动画到指定位置
        moveScrollView(scrollView: scrollView, initialSpringVelocity: velocity.y, movePointY: gotoPointY, isAnimate: true)
        //这里是重点，把计算好的最后位置给到targetContentOffset
        targetContentOffset.pointee = CGPoint(x: 0, y: gotoPointY)
    }
```
**计算好需要的位置坐标，设置到`targetContentOffset `属性。`moveScrollView `添加动画**

```
//动画将scrollView移动到指定位置
    func moveScrollView(scrollView: UIScrollView, initialSpringVelocity velocity: CGFloat, movePointY: CGFloat, isAnimate: Bool) {
        //可以先设置一下当前偏移量。
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: velocity, options: UIView.AnimationOptions.curveEaseOut, animations: {
            //动画到计算好的指定偏移量
            scrollView.contentOffset.y = movePointY
        }, completion: nil)
    }
```
**这样其实就大体实现了，分三段的效果。**

#### 2、视图显示到3级时，如何实现不遮挡地图触摸事件

因为scrollView是全屏布局，才可以全屏滚动。这样不可避免的就会遮挡住地图的触摸事件交互，这跟我们的需求是不符的。所以需要我们来做一个处理，**这里用到了`hitTest:withEvent`方法来解决**。

* 简单介绍一下`hitTest:withEvent`方法：
响应链传递的关键方法，当手势交互时，会逐级的用此方法来寻找到要响应事件的视图。我们可以重写方法，来进行业务需求的操作。

**所以我们可以通过此方法，来判断scrollView在什么时候可以响应手势事件，什么时候忽略手势事件。**

创建一个UIScrollView类，重写父类`hitTest:withEvent`方法，上代码：

```
override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            return nil
        }
        return hitView
    }
```

解读一下：

* 从父类方法中，获取到将要响应事件的视图`hitView `，如果这个视图是`scrollView`本身，则返回`nil`代表这层view不响应事件，事件会继续传递，就会传递到`scrollView`下一层视图。
* 如果`hitView `不是`scrollView`本身，则表示是`scrollView`的子视图响应手势事件，也就是说手指是触碰的子View，不是直接触碰`scrollView`，所以正常return这个子视图就好了。

这里的业务需求就是手指触碰白色tableView才可以拖动，触碰红色区域不会影响下一层的Map地图交互。（这里因为我中间添加了一个黑色图层，是想实现在2级时，点击黑色按钮，可以到达3级，当到3级时，黑色按钮设置`isUserInteractionEnabled = false`，不会影响地图交互）

#### 3、解决滑动冲突
滑动tableView的时候，还需要让scrollView也同时滚动，所以首先要让他们之间的滚动互相不受影响。
这里需要用到`UIGestureRecognizerDelegate`代理里的方法。

* 还是需要自定义UITableView类，实现代理`UIGestureRecognizerDelegate`的方法👇

```
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
```
返回`true`时，代表tableView有多个手势时不会干扰，这样就不会影响到scrollView的滚动。
有很多地方都会用到，比如给tableView添加手势时，返回`true`就可以多个手势一起触发。

* 不互相干扰了，但是还是不能实现效果，还需要去控制他们什么时候才可以让他们滚动。
监听滑动偏移量，来进行判断控制。所以用到scrollView的代理方法：

```
func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //这里主要解决滑动冲突
        if scrollView == self.scrollView {
            //这里用 > 就好
            if scrollView.contentOffset.y > contentOffsetMaxY {
                scrollView.contentOffset.y = contentOffsetMaxY
                //设置标记，用来判断视图是否可以滚动
                scrollViewMove = false
                tableViewMove = true
            }
            //当scrollView不能滚动时，设置其偏移量
            if !scrollViewMove {
                scrollView.contentOffset.y = contentOffsetMaxY
            }
        }else if scrollView == self.tableView {
            //同scrollView的滚动View类似操作。
            if scrollView.contentOffset.y <= 0 {
                scrollView.contentOffset.y = 0
                tableViewMove = false
                scrollViewMove = true
            }
            if !tableViewMove {
                scrollView.contentOffset.y = 0
            }
        }
    }
```
添加两个标记（其实用一个标记也可以），来控制视图是否可以滚动。
这样来控制，就可以解决问题了。

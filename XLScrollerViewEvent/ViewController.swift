//
//  ViewController.swift
//  XLScrollerViewEvent
//
//  Created by 王晓磊 on 2020/5/18.
//  Copyright © 2020 王晓磊. All rights reserved.
//

import UIKit
import MapKit

// iPhone X
func isIPhoneXType() -> Bool {
    guard #available(iOS 11.0, *) else {
        return false
    }
    return UIApplication.shared.windows.first?.safeAreaInsets.bottom != 0
}
let kIPhoneX: Bool = isIPhoneXType()
let kTabbarSafeBottomMargin: CGFloat = kIPhoneX ? 34.0 : 0.0
let kStatusBarAndNavigationBarHeight: CGFloat = kIPhoneX ? 88.0 : 64.0

//当级别为Mid中间时的窗口大小比例
let mapWindowHeight: CGFloat = (UIScreen.main.bounds.size.height - kStatusBarAndNavigationBarHeight) * 0.4

let bottomBarHeight: CGFloat = 40 + kTabbarSafeBottomMargin

//底层scrollView
let contentOffsetMinY: CGFloat = 0.0
let contentOffsetMaxY = UIScreen.main.bounds.size.height - kStatusBarAndNavigationBarHeight - bottomBarHeight
let contentOffsetMidY = contentOffsetMaxY - mapWindowHeight



//此项目是仿百度POI搜索时，分级滑动的效果，当做是一次学习的过程，来把这样一个效果实现！
class ViewController: UIViewController {
    
    //滑动冲突标记，标记双层滑动View，判断他们什么时候允许滑动
    var scrollViewMove = true
    var tableViewMove = false
    
    private lazy var scrollView: XLScrollView = {
       
        let scrollView = XLScrollView(frame: CGRect(x: 0, y: kStatusBarAndNavigationBarHeight, width: self.view.width, height: self.view.height - kStatusBarAndNavigationBarHeight))
        scrollView.delegate = self;
        scrollView.backgroundColor = UIColor.clear
        scrollView.contentSize = CGSize(width: self.view.width, height: (self.view.height - kStatusBarAndNavigationBarHeight) * 2 - bottomBarHeight)
        //这里不能用isPagingEnabled来做分页效果
//        scrollView.isPagingEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private lazy var tableView: XLTableView = {
        
        let tableView = XLTableView(frame: CGRect(x: 0, y: self.scrollView.height - bottomBarHeight, width: self.scrollView.width, height: self.scrollView.height), style: UITableView.Style.plain)
        tableView.backgroundColor = UIColor.white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
//        tableView.estimatedSectionHeaderHeight = 0
//        tableView.estimatedSectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        
        return tableView
    }()
    
    private lazy var quitButton: UIButton = {
       
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor.clear
        button.frame = CGRect(x: 0, y: kStatusBarAndNavigationBarHeight, width: self.scrollView.width, height: self.scrollView.height - bottomBarHeight)
        button.addTarget(self, action: #selector(quitButtonClick(sender:)), for: UIControl.Event.touchDown)
        return button
    }()
    
    private lazy var bottomBar: UIView = {
        let barView = UIView.init(frame: CGRect.init(x: 0, y: view.height, width: view.width, height: bottomBarHeight))

        barView.backgroundColor = UIColor.white
        barView.layer.shadowColor = UIColor.black.cgColor
        barView.layer.shadowOffset = CGSize.init(width: 0, height: 2)
        barView.layer.shadowOpacity = Float(0.14)
        barView.layer.shadowRadius = 3
        barView.isUserInteractionEnabled = false

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: barView.width, height: bottomBarHeight - kTabbarSafeBottomMargin))
        label.text = "点击查看更多结果"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.tag = 111;
        barView.addSubview(label)
        
        return barView
    }()
    
    //随便加载一个地图试试效果，不会阻挡地图事件。
    //（和地图联动进行缩放地图就暂时不写了，有时间再写！）
    private lazy var mapView: MKMapView = {
       
        let mapview = MKMapView.init(frame: view.bounds)
        mapview.userTrackingMode=MKUserTrackingMode.follow//追踪模式
        mapview.showsScale=true//显示比例尺
        mapview.showsCompass=true//显示罗盘
        mapview.showsBuildings=true//显示建筑物
        mapview.mapType=MKMapType.standard//地图的显示模式，有号几个选项
        
        return mapview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "两层滚动View，滑动冲突解决"
        
        //首先加载地图
        view.addSubview(mapView)
        
        view.addSubview(quitButton)
        
        view.addSubview(self.scrollView)
        
        scrollView.addSubview(tableView)
        
        view.addSubview(bottomBar)
        view.bringSubviewToFront(bottomBar)
        
        //设定底层scrollView的滑动起始点
        scrollView.contentOffset.y = contentOffsetMidY
    }
}

//tableView代理
extension ViewController: UITableViewDataSource, UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellID = "cellID"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        if cell == nil {
            
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellID")
        }
        
        if indexPath.row == 0 {
            
            let myString = "100分"
            
            let myAttrString = NSMutableAttributedString(string: myString)
            myAttrString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.red], range: myString.nsRange(of: "分"))
            
            cell?.textLabel?.attributedText = myAttrString
        }else{
            
            cell?.textLabel?.text = String(indexPath.row)
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //这里先暂时从tableView的点击事件处理，是为了可以点击底部buttomBar，跳转中间级别。
        if self.quitButton.isUserInteractionEnabled == false {
            
            moveScrollView(scrollView: self.scrollView, initialSpringVelocity: 8, movePointY: contentOffsetMidY, isAnimate: true)
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        //下面再进行tableView点击逻辑处理。
        
        tableView.deselectRow(at: indexPath, animated: true)
        print("点击了cell：", indexPath)
        
    }
}

//滑动事件代理
extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //这里主要解决滑动冲突
        if scrollView == self.scrollView {
            
            //当contentOffset大于设定最大偏移量时，固定偏移量，同时标记为上层tableView可以滑动，底层不可滑动。
            //这里不能加上”=“，因为有等号时，向上弹性滑动就会导致tableView自动向上跑（这里不要这种效果）。而且当正好上边对齐时，两层不能触发滚动。所以只是">"就好
            if scrollView.contentOffset.y > contentOffsetMaxY {
                
                scrollView.contentOffset.y = contentOffsetMaxY
                
                scrollViewMove = false
                tableViewMove = true
            }
            //当底层不能滚动时，设置其偏移量
            if !scrollViewMove {
                
                scrollView.contentOffset.y = contentOffsetMaxY
            }
            
            //滑动到contentOffsetMinY级别，背景button取消响应，否则开放响应
            if scrollView.contentOffset.y <= contentOffsetMinY {
                
                self.quitButton.isUserInteractionEnabled = false
            }else{
                self.quitButton.isUserInteractionEnabled = true
                
                //这里隐藏bottomBar。
                moveButtom(isShow: false)
            }
            
        }else if scrollView == self.tableView {
            
            //同底层的滚动View类似操作。
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
    
    //这里处理滑动手势结束后，页面的跳转效果
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
        targetContentOffset.pointee = CGPoint(x: 0, y: gotoPointY)
        
    }
    
    //减速已经结束
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if scrollView == self.scrollView {
            
            //如果滑动减速结束时，就是当滑动速度为0时，若停止位置，不在所在的三段级别位置时，则将其指定跳转到中间级别的位置上
            //这么做是因为内层tableView滑动减速结束后，可能会导致父层的scrollView不在三段级别上，所以才做了如下处理。
            let currentOffsetY = scrollView.contentOffset.y
            let currentOffsetArray = [contentOffsetMinY, contentOffsetMidY, contentOffsetMaxY]
            
            if !currentOffsetArray.contains(currentOffsetY) {
                
                //动画到指定位置
                moveScrollView(scrollView: self.scrollView, initialSpringVelocity: 8, movePointY: contentOffsetMidY, isAnimate: true)
            }
        }
    }
}


//自定义方法
extension ViewController{
    
    @objc func quitButtonClick(sender: UIButton) {
        
        gotoBottom()
    }
    
    func gotoBottom() {
        
        moveScrollView(scrollView: self.scrollView, initialSpringVelocity: 8, movePointY: contentOffsetMinY, isAnimate: true)
    }
    
    //动画将scrollView移动到指定位置
    func moveScrollView(scrollView: UIScrollView, initialSpringVelocity velocity: CGFloat, movePointY: CGFloat, isAnimate: Bool) {
        
        //显示bottomBar放在这里，是仿百度地图显示时机。
        if movePointY <= contentOffsetMinY {
            
            moveButtom(isShow: true)
        }
        
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        
        if !isAnimate {
            
            scrollView.contentOffset.y = movePointY
            return
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: velocity, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            scrollView.contentOffset.y = movePointY
        }, completion: nil)
    }
    
    //buttom位置设置
    func moveButtom(isShow: Bool) {
        
        UIView.animate(withDuration: 0.1) {
            
            if isShow {
                
                self.bottomBar.frame = CGRect.init(x: 0, y: self.view.height - bottomBarHeight, width: self.view.width, height: bottomBarHeight)
            }else{
                self.bottomBar.frame = CGRect.init(x: 0, y: self.view.height, width: self.view.width, height: bottomBarHeight)
            }
        }
    }
}

//String扩展，自定义方法------传入子字符串，返回NSRange对象
extension String{
    
    func nsRange(of subString: String) -> NSRange {
        
        let range = self.range(of: subString)
        let from = range!.lowerBound.samePosition(in: utf16)
        let to = range!.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from!), length: utf16.distance(from: from!, to: to!))
    }
}

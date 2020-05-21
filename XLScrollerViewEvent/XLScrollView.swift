//
//  XLScrollView.swift
//  XLScrollerViewEvent
//
//  Created by 王晓磊 on 2020/5/18.
//  Copyright © 2020 王晓磊. All rights reserved.
//

import UIKit

class XLScrollView: UIScrollView {

    //重写父类方法，如果事件响应是直接作用在底层scrollView上的话，不响应此事件
    //这样做是为了，只有滑动上层子视图tableView才会正常滑动，否则就不响应，事件就会往下面传递，不会造成遮挡视图事件。
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
       
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            
            return nil
        }
        return hitView
    }
}

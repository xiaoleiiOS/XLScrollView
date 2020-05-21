//
//  XLTableView.swift
//  XLScrollerViewEvent
//
//  Created by 王晓磊 on 2020/5/18.
//  Copyright © 2020 王晓磊. All rights reserved.
//

import UIKit

class XLTableView: UITableView, UIGestureRecognizerDelegate {

    //使上层滚动View的事件，不影响底层滚动View的事件响应
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

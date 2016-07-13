//
//  NSDateExtension.swift
//  HAudioPlayer
//
//  Created by wuqiuhao on 2016/7/13.
//  Copyright © 2016年 Hale. All rights reserved.
//

import Foundation

extension NSDate {
    // 格式化日期
    func stringForDateFormat(format: String) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
}

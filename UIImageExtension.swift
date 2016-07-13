//
//  UIImageExtension.swift
//  HAudioPlayer
//
//  Created by wuqiuhao on 2016/7/13.
//  Copyright © 2016年 Hale. All rights reserved.
//

import UIKit

extension UIImage {
    // 裁剪图片成正方形，取中间部分
    func cutImageToSquare()-> UIImage {
        let scale = UIScreen.mainScreen().scale
        let width = self.size.width
        let height = self.size.height
        let length = min(width,height) * scale
        var x:CGFloat = 0
        var y:CGFloat = 0
        let wh:CGFloat = width / height
        if wh > 1 {
            // 宽图
            x = (width - height) / 2 * scale
        } else{
            // 高图
            y = (height - width) / 2 * scale
        }
        let rect = CGRect(x: x, y: y, width: length, height: length)
        let imageRef = CGImageCreateWithImageInRect(self.CGImage, rect)
        let image = UIImage(CGImage: imageRef!)
        return image
    }
}

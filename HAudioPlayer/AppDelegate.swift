//
//  AppDelegate.swift
//  HAudioPlayer
//
//  Created by wuqiuhao on 2016/7/13.
//  Copyright © 2016年 Hale. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configAVAudioSession()
        return true
    }

    func configAVAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("audio session active error")
        }
        
    }
}

// MARK: - 音乐后台播放，远程控制
extension AppDelegate {
    
    // 结束申明应用接受远程控制事件
    func applicationWillResignActive(application: UIApplication) {
        application.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
    }
    
    /**
     接受系统控制中心的控制事件
     - parameter event:
     */
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event!.type == .RemoteControl {
            //判断点击按钮的类型
            switch (event!.subtype) {
            case .RemoteControlPlay:
                NSNotificationCenter.defaultCenter().postNotificationName("RemoteControlPlay", object: nil)
            case .RemoteControlPause:
                NSNotificationCenter.defaultCenter().postNotificationName("RemoteControlPause", object: nil)
            case .RemoteControlPreviousTrack:
                NSNotificationCenter.defaultCenter().postNotificationName("RemoteControlPreviousTrack", object: nil)
            case .RemoteControlNextTrack:
                NSNotificationCenter.defaultCenter().postNotificationName("RemoteControlNextTrack", object: nil)
            default:
                break;
            }
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
}


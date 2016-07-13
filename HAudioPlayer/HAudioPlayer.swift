//
//  HAudioPlayer.swift
//  HAudioPlayer
//
//  Created by wuqiuhao on 2016/7/13.
//  Copyright © 2016年 Hale. All rights reserved.
//

import UIKit
import AVFoundation

@objc
protocol HAudioPlayerDelegate {
    /**
     准备完毕，可以播放
     */
    func didReadyToPlay()
    /**
     更新缓冲进度
     */
    optional func didChangeLoadTimeRange(bufferTime: NSTimeInterval)
    /**
     播放完毕
     */
    func didEndPlay()
}

class HAudioPlayer: NSObject {
    // 播放列表
    var audioList: [HAudio]!
    // 从哪一首开始播放
    var currentIndex: Int!
    // 播放器引擎
    var player: AVPlayer!
    // 播放状态
    var mtStatus: AVPlayerStatus {
        return player.status
    }
    // 代理
    var delegate: HAudioPlayerDelegate?
    // 音量
    var mtVolume: Float? {
        set {
            player.volume = newValue!
        } get {
            return player.volume
        }
    }
    
    var mtDuration: NSTimeInterval! {
        get {
            return Double(player.currentItem!.duration.value) / Double(player.currentItem!.duration.timescale)
        }
    }
    
    var mtCurrentTime: NSTimeInterval {
        return Double(player.currentTime().value) / Double(player.currentTime().timescale)
    }
    
    var mtTimeScale: CMTimeScale {
        return player.currentItem!.duration.timescale
    }
    
    var loadedTimeRanges: [NSValue] {
        return player.currentItem!.loadedTimeRanges
    }
    
    var mtRate:Float {
        return player.rate
    }
    
    /**
     播放本地或网络音频初始化
     
     - parameter playAtIndex:  播放列表指定位置处音频
     - parameter audioList:    音频列表
     */
    init(playAtIndex: Int? = 0, audioList: [HAudio]) {
        super.init()
        if !audioList.isEmpty {
            self.audioList = audioList
            if playAtIndex >= audioList.count - 1 || playAtIndex < 0 {
                self.currentIndex = 0
            } else {
                self.currentIndex = playAtIndex!
            }
            let url = NSBundle.mainBundle().URLForResource(audioList[currentIndex].url, withExtension: nil)!
            let asset = AVAsset(URL: url)
            let playItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playItem)
            addObserverForPlayItem()
        }
    }
    
    deinit {
        removeObserverForPlayItem()
    }
    
    func updatePlayItem() {
        let url = NSBundle.mainBundle().URLForResource(audioList[currentIndex].url, withExtension: nil)!
        removeObserverForPlayItem()
        let playItem = AVPlayerItem(URL: url)
        player.replaceCurrentItemWithPlayerItem(playItem)
        addObserverForPlayItem()
    }
    
    /**
     播放
     */
    func playAudio() {
        player.play()
    }
    
    /**
     暂停
     */
    func stopAudio() {
        player.pause()
    }
    
    /**
     下一首,列表循环（默认）
     */
    func nextAudio()-> Bool {
        if let list = audioList {
            if currentIndex < list.count - 1 {
                currentIndex! += 1
                updatePlayItem()
            } else {
                currentIndex = 0
                updatePlayItem()
            }
            return true
        }
        return false
    }
    
    /**
     上一首，列表循环（默认）
     */
    func lastAudio()-> Bool {
        if let list = audioList {
            if currentIndex > 0 {
                currentIndex! -= 1
                updatePlayItem()
            } else {
                currentIndex = list.count - 1
                updatePlayItem()
            }
            return true
        }
        return false
    }
    
    /**
     播放到指定时间
     */
    func mtSeekToTime(cmTime:CMTime , seekCompletion: ((Bool)->Void)) {
        player.seekToTime(cmTime, completionHandler: seekCompletion)
    }
}

// MARK: - extension private notification function
extension HAudioPlayer {
    @objc private func didEndPlay() {
        delegate?.didEndPlay()
    }
    
    private func didChangeLoadTimeRange(bufferTime: NSTimeInterval) {
        delegate?.didChangeLoadTimeRange?(bufferTime)
    }
    
    private func didReadyToPlay() {
        delegate?.didReadyToPlay()
    }
}

extension HAudioPlayer {
    // 添加监听
    func addObserverForPlayItem() {
        player.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.New, context: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HAudioPlayer.didEndPlay), name: AVPlayerItemDidPlayToEndTimeNotification , object: player.currentItem)
    }
    
    // 移除监听
    func removeObserverForPlayItem() {
        player.currentItem?.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            let status = change!["new"] as! Int
            if status == AVPlayerStatus.ReadyToPlay.rawValue {
                didReadyToPlay()
            }
        } else if keyPath == "loadedTimeRanges" {
            let array = player.currentItem?.loadedTimeRanges
            let timeRanges = array?.first?.CMTimeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRanges!.start)
            let durationSeconds = CMTimeGetSeconds(timeRanges!.duration)
            let bufferTime = startSeconds + durationSeconds
            didChangeLoadTimeRange(bufferTime)
        }
    }
}
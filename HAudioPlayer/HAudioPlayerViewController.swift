//
//  HAudioPlayerViewController.swift
//  HAudioPlayer
//
//  Created by wuqiuhao on 2016/7/13.
//  Copyright © 2016年 Hale. All rights reserved.
//

import UIKit
import MediaPlayer

class HAudioPlayerViewController: UIViewController {
    
    @IBOutlet var channelName: UILabel!
    
    @IBOutlet var subTitle: UILabel!
    
    @IBOutlet var progressBar: UISlider!
    
    @IBOutlet var playingTime: UILabel!
    
    @IBOutlet var endTime: UILabel!
    
    @IBOutlet var lastSong: UIButton!
    
    @IBOutlet var nextSong: UIButton!
    
    @IBOutlet var playBtn: UIButton!
    
    @IBOutlet var diskImageView: UIImageView!
    
    @IBOutlet var coverImageView: UIImageView!
    
    @IBOutlet var backGroundImgView: UIImageView!
    
    var audioTitle: String!
    var artist: String!
    var playingInfo = [String:AnyObject]()
    var audioList = [HAudio]()
    var audioPlayer: HAudioPlayer?
    var timer: NSTimer?
    var rotateAnimation: CABasicAnimation?
    lazy var themeColor = UIColor(red: 178 / 255.0, green: 144 / 255.0, blue: 80 / 255.0, alpha: 1.0)
    var isShouldRotating = false
    var duration: NSTimeInterval?
    var isStop = false
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(frame: CGRect(x: 2.5, y: 14, width: self.progressBar.bounds.width - 5, height: self.progressBar.bounds.height))
        progressView.progressTintColor = UIColor(white: 0.8, alpha: 0.5)
        progressView.trackTintColor = UIColor.clearColor()
        self.progressBar.addSubview(progressView)
        self.progressBar.sendSubviewToBack(progressView)
        return progressView
    }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        UIBarButtonItem.appearance().tintColor = themeColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        initAudioList()
        addObserverForPlayItem()
    }
    
    deinit {
        removeObserverForPlayItem()
    }
}

// MARK: - 接受系统控制中心的控制事件
extension HAudioPlayerViewController {
    // 播放
    func  didRemoteControlPlay() {
        audioPlayer?.playAudio()
        self.timer?.fireDate = NSDate()
        if UIApplication.sharedApplication().applicationState != UIApplicationState.Background  {
            beginRotateCover()
        }
        isShouldRotating = true
        playBtn.selected = true
    }
    // 暂停
    func didRemoteControlPause() {
        audioPlayer?.stopAudio()
        self.timer?.fireDate = NSDate.distantFuture()
        if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
            stopRotateCover()
        }
        isShouldRotating = false
        playBtn.selected = false
    }
    // 上一首
    func didRemoteControlPreviousTrack() {
        playLastAudio()
        isShouldRotating = true
        playBtn.selected = true
    }
    // 下一首
    func didRemoteControlNextTrack() {
        playNextAudio()
        isShouldRotating = true
        playBtn.selected = true
    }
}

// MARK: - private method
extension HAudioPlayerViewController {
    func initAudioList() {
        for i in 0..<3 {
            var audio = HAudio()
            audio.url = "music\(i).mp3"
            let asset = AVAsset(URL: NSBundle.mainBundle().URLForResource(audio.url, withExtension: nil)!)
            for format in asset.availableMetadataFormats {
                for dataItem in asset.metadataForFormat(format) {
                    if dataItem.commonKey == "artwork" {
                        audio.cover = dataItem.value as? NSData
                    } else if dataItem.commonKey == "artist" {
                        audio.artist = dataItem.value as? String
                    } else if dataItem.commonKey == "title" {
                        audio.title = dataItem.value as? String
                    }
                }
            }
            audioList.append(audio)
        }
        audioPlayer = HAudioPlayer(audioList: audioList)
        initPlayerConfig()
    }
    
    func configUI() {
        progressBar.enabled = false
        playBtn.enabled = false
        lastSong.enabled = false
        nextSong.enabled = false
        coverImageView.layer.cornerRadius = (UIScreen.mainScreen().bounds.width - 100) / 2
        coverImageView.clipsToBounds = true
        
        progressBar.setThumbImage(UIImage(named: "Music_slider"), forState: .Normal)
        progressBar.setMinimumTrackImage(UIImage(named: "Music_already_play"), forState: UIControlState.Normal)
        progressBar.setMaximumTrackImage(UIImage(named: "Music_will_play"), forState: UIControlState.Normal)
        channelName.textColor = themeColor
        subTitle.textColor = themeColor
        playingTime.textColor = themeColor
        endTime.textColor = themeColor
        view.bringSubviewToFront(diskImageView)
        view.sendSubviewToBack(backGroundImgView)
        progressBar.value = 0
        playingInfo.updateValue(0, forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
        playingInfo.updateValue(0, forKey: MPMediaItemPropertyPlaybackDuration)
        playingTime.text = "00:00"
        endTime.text = "00:00"
        
        let blur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.frame = view.frame
        backGroundImgView.addSubview(effectView)
    }
    
    // 初始化播放器参数
    func initPlayerConfig() {
        playBtn.addTarget(self, action: #selector(playBtnClicked(_:)), forControlEvents: .TouchUpInside)
        lastSong.addTarget(self, action: #selector(playLastAudio), forControlEvents: .TouchUpInside)
        nextSong.addTarget(self, action: #selector(playNextAudio), forControlEvents: .TouchUpInside)
        audioPlayer = HAudioPlayer(audioList: audioList)
        audioPlayer?.delegate = self
        audioPlayer?.mtVolume = 1.0
        audioTitle = audioList[audioPlayer!.currentIndex].title!
        artist = audioList[audioPlayer!.currentIndex].artist!
        channelName.text = audioTitle
        subTitle.text = artist
        self.playingInfo.updateValue(audioTitle,forKey: MPMediaItemPropertyTitle)
        self.playingInfo.updateValue(artist,forKey: MPMediaItemPropertyArtist)
        var image: UIImage!
        if let data = audioList[audioPlayer!.currentIndex].cover {
            image = UIImage(data: data)
        } else {
            image = UIImage(named: "Music_default_cover")
        }
        coverImageView.image = image
        backGroundImgView.image = image
        self.playingInfo.updateValue(MPMediaItemArtwork(image: image!.cutImageToSquare()),forKey: MPMediaItemPropertyArtwork)
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.playingInfo
    }
    
    // 定时更新播放进度
    func updatePlayingProgress() {
        if let player = audioPlayer {
            progressBar.value = Float(player.mtCurrentTime) / Float(duration!)
            playingInfo.updateValue(audioPlayer!.mtCurrentTime, forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
            playingInfo.updateValue(audioPlayer!.mtRate, forKey: MPNowPlayingInfoPropertyPlaybackRate)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.playingInfo
            playingTime.text = NSDate(timeIntervalSinceReferenceDate: audioPlayer!.mtCurrentTime).stringForDateFormat("mm:ss")
        }
    }
    
    /**
     开始旋转封面
     */
    func beginRotateCover() {
        if let _ = rotateAnimation {
            let pausedTime = coverImageView.layer.timeOffset
            coverImageView.layer.speed = 1.0
            coverImageView.layer.timeOffset = 0
            coverImageView.layer.beginTime = 0
            let timeSincePause = coverImageView.layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
            coverImageView.layer.beginTime = timeSincePause
        } else {
            rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotateAnimation!.fillMode = kCAFillModeForwards
            rotateAnimation!.removedOnCompletion = false
            rotateAnimation!.toValue = M_PI * 2
            rotateAnimation!.duration = 30
            rotateAnimation!.cumulative = true
            rotateAnimation!.repeatCount = Float(CGFloat.max)
            coverImageView.layer.addAnimation(rotateAnimation!, forKey: "rotateAnimation")
        }
    }
    
    /**
     暂停旋转封面
     */
    func stopRotateCover() {
        let pausedTime = coverImageView.layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        coverImageView.layer.speed = 0
        coverImageView.layer.timeOffset = pausedTime
    }
    
    /**
     移除旋转动画
     */
    func removeRotateCover() {
        coverImageView.layer.removeAnimationForKey("rotateAnimation")
    }
    
    func applicationWillResignActive() {
        if isShouldRotating {
            stopRotateCover()
        }
    }
    
    func applicationDidBecomeActive() {
        if isShouldRotating {
            beginRotateCover()
        }
    }
}

// MARK: - Action
extension HAudioPlayerViewController {
    // 播放、暂停按钮被点击
    func playBtnClicked(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            // 播放当前歌曲
            isStop = false
            isShouldRotating = true
            audioPlayer!.playAudio()
            beginRotateCover()
            timer?.fireDate = NSDate()
        } else {
            isStop = true
            isShouldRotating = false
            audioPlayer?.stopAudio()
            stopRotateCover()
            timer?.fireDate = NSDate.distantFuture()
        }
    }
    
    /**
     点击进度条拖块
     
     - parameter sender:
     */
    @IBAction func progressBarTouchDown(sender: UISlider) {
        timer?.fireDate = NSDate.distantFuture()
    }
    
    /**
     结束拖动进度
     
     - parameter sender:
     */
    @IBAction func progressBarTouchUpInside(sender: UISlider) {
        let currentTime = duration! * Double(sender.value)
        audioPlayer!.mtSeekToTime(CMTime(seconds: currentTime, preferredTimescale: audioPlayer!.mtTimeScale), seekCompletion: { (finished) in
            if finished {
                self.timer?.fireDate = NSDate()
                self.progressBar.value = sender.value
                self.playingTime.text = NSDate(timeIntervalSinceReferenceDate: currentTime).stringForDateFormat("mm:ss")
            }
        })
    }
    
    /**
     结束拖动进度
     
     - parameter sender:
     */
    @IBAction func progressBarTouchUpOutside(sender: UISlider) {
        let currentTime = duration! * Double(sender.value)
        audioPlayer!.mtSeekToTime(CMTime(seconds: currentTime, preferredTimescale: audioPlayer!.mtTimeScale), seekCompletion: { (finished) in
            if finished {
                self.timer?.fireDate = NSDate()
                self.progressBar.value = sender.value
                self.playingTime.text = NSDate(timeIntervalSinceReferenceDate: currentTime).stringForDateFormat("mm:ss")
            }
        })
    }
    
    /**
     上一曲
     */
    func playLastAudio() {
        if let player = audioPlayer where player.lastAudio() {
            stopRotateCover()
            isStop = false
            progressBar.value = 0
            playingTime.text = "00:00"
            
            audioTitle = audioList[audioPlayer!.currentIndex].title!
            artist = audioList[audioPlayer!.currentIndex].artist!
            channelName.text = audioTitle
            subTitle.text = artist
            self.playingInfo.updateValue(audioTitle,forKey: MPMediaItemPropertyTitle)
            self.playingInfo.updateValue(artist,forKey: MPMediaItemPropertyArtist)
            var image: UIImage!
            if let data = audioList[player.currentIndex].cover {
                image = UIImage(data: data)
            } else {
                image = UIImage(named: "Music_default_cover")
            }
            coverImageView.image = image
            backGroundImgView.image = image
            self.playingInfo.updateValue(MPMediaItemArtwork(image: image!.cutImageToSquare()),forKey: MPMediaItemPropertyArtwork)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.playingInfo
        }
    }
    
    /**
     下一曲
     */
    func playNextAudio() {
        if let player = audioPlayer {
            player.nextAudio()
            stopRotateCover()
            isStop = false
            progressBar.value = 0
            playingTime.text = "00:00"
            audioTitle = audioList[audioPlayer!.currentIndex].title!
            artist = audioList[audioPlayer!.currentIndex].artist!
            channelName.text = audioTitle
            subTitle.text = artist
            self.playingInfo.updateValue(audioTitle,forKey: MPMediaItemPropertyTitle)
            self.playingInfo.updateValue(artist,forKey: MPMediaItemPropertyArtist)
            var image: UIImage!
            if let data = audioList[player.currentIndex].cover {
                image = UIImage(data: data)
            } else {
                image = UIImage(named: "Music_default_cover")
            }
            coverImageView.image = image
            backGroundImgView.image = image
            self.playingInfo.updateValue(MPMediaItemArtwork(image: image!.cutImageToSquare()),forKey: MPMediaItemPropertyArtwork)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.playingInfo
        }
    }
}


// MARK: - extension Observer
extension HAudioPlayerViewController {
    // 添加监听
    func addObserverForPlayItem() {
        // 进入后台监听
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        // 进入前台监听
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplicationWillEnterForegroundNotification, object: nil)
        // 意外中断监听
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioSessionInterruptionNotification), name: AVAudioSessionInterruptionNotification, object: AVAudioSession.sharedInstance())
        // 输出设备改变监听
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioSessionRouteChangeNotification), name: AVAudioSessionRouteChangeNotification, object: AVAudioSession.sharedInstance())
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didRemoteControlPlay), name: "RemoteControlPlay", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didRemoteControlPause), name: "RemoteControlPause", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didRemoteControlPreviousTrack), name: "RemoteControlPreviousTrack", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didRemoteControlNextTrack), name: "RemoteControlNextTrack", object: nil)
    }
    
    // 移除监听
    func removeObserverForPlayItem() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionRouteChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlPlay", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlPause", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlPreviousTrack", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "RemoteControlNextTrack", object: nil)
    }
}

// MARK: - HAudioPlayerDelegate
extension HAudioPlayerViewController: HAudioPlayerDelegate {
    // 准备播放
    func didReadyToPlay() {
        if !isStop {
            playBtn.enabled = true
            lastSong.enabled = true
            nextSong.enabled = true
            progressBar.enabled = true
            
            timer?.invalidate()
            duration = audioPlayer!.mtDuration
            endTime.text = NSDate(timeIntervalSinceReferenceDate: duration!).stringForDateFormat("mm:ss")
            playingInfo.updateValue(duration!, forKey: MPMediaItemPropertyPlaybackDuration)
            playBtn.selected = true
            audioPlayer?.playAudio()
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updatePlayingProgress), userInfo: nil, repeats: true)
            if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
                beginRotateCover()
            }
        }
    }
    
    // 刷新缓冲进度
    func didChangeLoadTimeRange(bufferTime: NSTimeInterval) {
        progressView.progress = Float(bufferTime) / Float(audioPlayer!.mtDuration)
    }
    
    // 结束播放
    func didEndPlay() {
        // 自动下一首
        playNextAudio()
    }
}

// MARK: - 打断处理
extension HAudioPlayerViewController {
    // 音频打断（电话打入、其他播放器打开...）
    func audioSessionInterruptionNotification(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let typeKey = userInfo![AVAudioSessionInterruptionTypeKey] as? UInt {
            if typeKey == AVAudioSessionInterruptionType.Began.rawValue {
                // 打断
                isShouldRotating = false
                playBtn.selected = false
                audioPlayer?.stopAudio()
                if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
                    stopRotateCover()
                }
                timer?.fireDate = NSDate.distantFuture()
            } else if typeKey == AVAudioSessionInterruptionType.Ended.rawValue {
                // 打断恢复
                playBtn.selected = true
                isShouldRotating = true
                audioPlayer!.playAudio()
                if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
                    beginRotateCover()
                }
                timer?.fireDate = NSDate()
            }
        }
    }
    // 音频输出设备变化
    func audioSessionRouteChangeNotification(notification: NSNotification) {
        let userInfo = notification.userInfo
        //
        if let reasonKey = userInfo![AVAudioSessionRouteChangeReasonKey] as? UInt {
            if reasonKey == AVAudioSessionRouteChangeReason.NewDeviceAvailable.rawValue {
                // 接入新的输出设备（耳机）
            } else if reasonKey == AVAudioSessionRouteChangeReason.OldDeviceUnavailable.rawValue {
                // 断开输出设备
                playBtn.selected = false
                isShouldRotating = false
                audioPlayer?.stopAudio()
                if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
                    stopRotateCover()
                }
                timer?.fireDate = NSDate.distantFuture()
            }
        }
    }
}

//
//  Play.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 2/10/2025.
//

import AVFoundation
internal import Combine
import Foundation
import SwiftUI

class Play: ObservableObject {
    enum PlayStatus {
        case playing
        case paused
        case stopped
    }

    init() {

    }
    var player = AVAudioPlayer()
    @Published var playList: [Music] = []

    func play() {
        if nowPlaying < 0 {
            player.stop()
            playStatus = .stopped
            return
        }

        //如果暫停，則繼續播放
        if playStatus == .paused {
            player.play()
            playStatus = .playing
        }
        else{
            //若下標有效，則播放
            if let nm = nowMusic{
                switch nm.type {
                case .local:
                    do {
                        player = try AVAudioPlayer(
                            contentsOf: (nm as! LocalMusic).url
                        )
                        player.prepareToPlay()
                        player.play()
                        playStatus = .playing
                    } catch _ {
                        player.stop()
                        playStatus = .stopped
                        return
                    }
                default:
                    return
                }
            }
            //無效則停止
            else{
                playStatus = .stopped
                player.stop()
            }
        }
    }
    func pause() {
        player.pause()
        playStatus = .paused
    }

//    //合理化當前播放歌曲
//    private func validateNowPlaying() {
//        if nowPlaying >= playList.count || nowPlaying < 0 {
//            nowPlaying = -1
//        }
//    }

    @Published var nowPlaying: Int = 0
    var nowMusic: Music? {
        if (0..<playList.count).contains(nowPlaying){
            return playList[nowPlaying]
        }
        return nil
    }

    @Published var playStatus: PlayStatus = .stopped
    var playIcon: String { playStatus == .playing ? "pause" : "play" }

    //設置新播放列表
    func setList(_ list: [Music]) {
        playList = list
        nowPlaying = 0
        playStatus = .stopped
    }
    
    //上一首
    func last() {
        nowPlaying -= 1
        play()
    }
    //下一首
    func next() {
        nowPlaying += 1
        play()
    }
}

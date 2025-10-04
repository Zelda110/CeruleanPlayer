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
    var oringinPlayList: [Music] = []

    @Published var shuffled: Bool = false

    func play(startByChanging: Bool = false) {
        if startByChanging {
            if nowMusic != nil {
                play()
            } else {
                nowPlaying = 0
                playStatus = .stopped
                player.stop()
            }
        } else {
            switch playStatus {
            case .stopped, .playing:
                if !playList.isEmpty {
                    if let nm = nowMusic {
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
                    } else {
                        playStatus = .stopped
                        player.stop()
                    }
                }
            case .paused:
                player.play()
                playStatus = .playing
            }
        }
    }
    func pause() {
        player.pause()
        playStatus = .paused
    }

    @Published var nowPlaying: Int = 0
    var nowMusic: Music? {
        if (0..<playList.count).contains(nowPlaying) {
            return playList[nowPlaying]
        }
        return nil
    }

    @Published var playStatus: PlayStatus = .stopped
    var playIcon: String { playStatus == .playing ? "pause" : "play" }

    //設置新播放列表
    func setList(_ list: [Music], startMusic: Music? = nil) {
        oringinPlayList = list
        playList = shuffled ? list.shuffled() : list
        if let start = startMusic{
            nowPlaying = playList.firstIndex { $0 === start }!
        } else {
            nowPlaying = 0
        }
        playStatus = .stopped
    }

    //上一首
    func last() {
        nowPlaying -= 1
        play(startByChanging: true)
    }
    //下一首
    func next() {
        nowPlaying += 1
        play(startByChanging: true)
    }

    //隨機播放
    func toggleShuffle() {
        shuffled.toggle()
        if playList.isEmpty { return }
        if shuffled {
            playList = playList[0...nowPlaying] + playList.shuffled()
        } else {
            nowPlaying = oringinPlayList.firstIndex { $0 === nowMusic! }!
            playList = oringinPlayList
        }
    }
}

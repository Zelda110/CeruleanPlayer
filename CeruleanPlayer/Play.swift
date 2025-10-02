//
//  Play.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 2/10/2025.
//

import Foundation
import AVFoundation
import SwiftUI
internal import Combine

class Play: ObservableObject {
    init() {
        
    }
    var player = AVAudioPlayer()
    @Published var playList: [any Music] = []

    func play() {
        if playList.isEmpty {
            return
        }
        switch playList[0].type{
        case .local:
            do{
                player = try AVAudioPlayer(
                    contentsOf: (playList[0] as! LocalMusic).url
                )
                player.prepareToPlay()
                player.play()
            }catch _ {
                return
            }
        default:
            return
        }
    }
    func pause() {
        player.pause()
    }
}

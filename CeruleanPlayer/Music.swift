//
//  Music.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import AVFoundation
internal import Combine
import MusicKit
import SwiftUI

enum FileType {
    case appleMusic
    case local
}

//enum MusicTagType{
//    case title
//    case artists
//    case albumArtists
//    case album
//    case composer
//    case lyricist
//    case genre
//    case trackNumber
//    case allTracks
//    case discNumber
//    case allDiscs
//    case year
//    case bpm
//}

//藝術家類
struct Artist {
    init(_ name: String) {
        self.name = name
        self.alias = [self.name]
        self.id = UUID()
    }
    func isSame(_ value: String) -> Bool {
        return alias.contains(value)
    }
    var id: UUID
    var name: String
    var alias: [String]
}

struct Tags {
    var title: String = ""
    var artists: [UUID]?
    var album: String?
    var cover: URL?
}

class Music: ObservableObject {
    var type: FileType = .local
    @Published var tags: Tags = Tags()
    func getCover() async -> Image? { nil }
    let uuid = UUID()
}

//本地音樂類
class LocalMusic: Music {
    init(url: URL) {
        self.url = url
        super.init()
        self.type = .local
    }

    var url: URL
    //導入封面
    override func getCover() async -> Image? {
        //優先嘗試 tag 裡的封面
        if let url = tags.cover {
            if let cgimgSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                let cgimg = CGImageSourceCreateImageAtIndex(cgimgSource, 0, nil)
                return Image(decorative: cgimg!, scale: 1.0)
            }
        }
        //從源文件讀取封面
        do {
            let asset = AVURLAsset(url: self.url)
            let data = try await asset.load(.metadata)
            if let cover = try await AVMetadataItem.metadataItems(
                from: data,
                filteredByIdentifier: .commonIdentifierArtwork
            ).first?.load(.value) {
                guard
                    let cgImageSource = CGImageSourceCreateWithData(
                        cover as! CFData,
                        nil
                    )
                else { return nil }
                return Image(
                    decorative: CGImageSourceCreateImageAtIndex(
                        cgImageSource,
                        0,
                        nil
                    )!,
                    scale: 1.0
                )
            }
            return nil
        } catch _ {
            return nil
        }
    }
}

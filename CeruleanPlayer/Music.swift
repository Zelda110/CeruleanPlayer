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

//從姓名或 uuid 獲取藝術家
func getArtist(_ name: String, temporary: Bool = false) -> Artist {
    if let artist = allArtists.first(where: { $0.alias.contains(name) }) {
        return artist
    } else {
        let newArtist = Artist(name)
        if !temporary {
            allArtists.append(newArtist)
        }
        return newArtist
    }
}
func getArtist(_ id: UUID) -> Artist? {
    return allArtists.first(where: { $0.id == id })
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
}

//本地音樂類
class LocalMusic: Music {
    init(url: URL) {
        self.url = url
        super.init()
        self.type = .local
        Task {
            do {
                let tags = try await self.loadAsset()
                self.tags = tags
            }
        }
    }

    //讀取音樂元數據
    func loadAsset() async throws -> Tags {
        let asset = AVURLAsset(url: self.url)
        self.asset = asset
        let data = try await asset.load(.metadata)

        var tags = Tags()
        //標題
        if let title = try await AVMetadataItem.metadataItems(
            from: data,
            filteredByIdentifier: .commonIdentifierTitle
        ).first?.load(.stringValue) {
            tags.title = title
        }
        //藝術家
        if let artist = try await AVMetadataItem.metadataItems(
            from: data,
            filteredByIdentifier: .commonIdentifierArtist
        ).first?.load(.stringValue) {
            let artists: [UUID] = artist.split(separator: " & ").map({
                getArtist(String($0)).id
            })
            tags.artists = artists
        }
        //專輯
        if let album = try await AVMetadataItem.metadataItems(
            from: data,
            filteredByIdentifier: .commonIdentifierAlbumName
        ).first?.load(.stringValue) {
            tags.album = album
        }

        return tags
    }

    var asset: AVAsset?
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
            self.asset = asset
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

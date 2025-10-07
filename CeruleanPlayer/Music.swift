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

enum FileType: Int, Codable {
    case appleMusic = 0
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
struct Artist: Codable {
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

//專輯類
struct Album: Codable {
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

struct Tags: Codable {
    var title: String = ""
    var artists: [UUID]?
    var album: UUID?
    var cover: URL?
}

class Music: ObservableObject, Codable {
    var type: FileType = .local
    var tags: Tags = Tags()
    func getCover() async -> Image? { nil }
    var uuid = UUID()
    
    //實現 json 編碼
    enum CodingKeys: String, CodingKey {
        case uuid, type, tags
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.type = try container.decode(FileType.self, forKey: .type)
        self.tags = try container.decode(Tags.self, forKey: .tags)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.tags, forKey: .tags)
    }
    
    init() {}
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
    
    //實現 json 編碼
    enum CodingKeys: String, CodingKey {
        case url
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }
}

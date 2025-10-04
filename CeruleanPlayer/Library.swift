//
//  Library.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import AVFoundation
import Cocoa
internal import Combine
import Foundation

let supportedFileExtensions: Set<String> = ["mp3", "wav", "m4a", "flac"]

class Source: ObservableObject {
    //    var songSources: [URL] = [URL(filePath: "smb://192.168.50.110/resource/Musics/C418")]
    var songSources: [URL] = [URL(filePath: "/Users/zelda/Music/m")]

    @Published var allArtists: [Artist] = []
    @Published var allSongs: [Music] = []

    //導入音樂源的所有音樂
    func loadSources() async {
        let fileManager = FileManager()

        // 嘗試遍歷已有來源
        var urls: [URL] = []

        for source in songSources {
            urls +=
                fileManager.enumerator(
                    at: source,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )?
                .compactMap { $0 as? URL }
                .filter {
                    supportedFileExtensions.contains(
                        $0.pathExtension.lowercased()
                    )
                }
                ?? []
        }

        // 將找到的音樂加入 allSongs
        for url in urls {
            let music = await loadLocalMusic(url)
            allSongs.append(music as Music)
        }
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

    //導入本地音樂
    func loadLocalMusic(_ url: URL) async -> LocalMusic {

        let music = LocalMusic(url: url)

        //導入元數據
        do {
            let asset = AVURLAsset(url: url)
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

            music.tags = tags
        } catch _ {
            music.tags = Tags()
        }

        return music
    }
}

//從所有源導入音樂
//func loadSources() {
//    let fileManager = FileManager()
//    for source in songSources {
//        let musics = fileManager.enumerator(
//            at: source,
//            includingPropertiesForKeys: nil,
//            options: .skipsHiddenFiles,
//            errorHandler: nil
//        )
//        let urls = musics?.compactMap { $0 as? URL }.filter {
//            supportedFileExtensions.contains($0.pathExtension)
//        }
//        allSongs += urls?.map { LocalMusic(url: $0) as Music } ?? []
//    }
//}

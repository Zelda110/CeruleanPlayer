//
//  Library.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import AVFoundation
internal import Combine
import Foundation

let supportedFileExtensions: Set<String> = ["mp3", "wav", "m4a", "flac"]

class Source: ObservableObject {
    private struct SongSource: Codable {
        var url: URL
        var num: Int
    }
    
    init() {
        Task.detached{
            await self.loadArtists()
            await self.loadAlbums()
            await self.loadLocalSongs()
        }
    }
    
    let appURL: URL = FileManager.default.urls(
        for: .musicDirectory,
        in: .userDomainMask
    )[0].appending(path: "CeruleanPlayer")
    
    @Published var songSources: [URL] = [URL(filePath: "/Users/zelda/Music/m")]

    @Published var allArtists: [Artist] = []
    @Published var allAlbums: [Album] = []
    @Published var allLocalSongs: [LocalMusic] = []
    
    @Published var loadedSongs: Float = -1
    @Published var totalSongs: Float = 0

    func saveLocalSongs(){
        do{
            let url = appURL.appending(path: "source/localSongs.json")
            try FileManager.default
                .createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let data = try encoder.encode(allLocalSongs)
            try data.write(to: url)
        }catch _ {
            print("failed to save local songs")
        }
    }
    
    func saveAllArtists(){
        do{
            let url = appURL.appending(path: "source/artists.json")
            try FileManager.default
                .createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let data = try encoder.encode(allArtists)
            try data.write(to: url)
        }catch _ {
            print("failed to save artists")
        }
    }
    
    func saveAllAlbums(){
        do{
            let url = appURL.appending(path: "source/albums.json")
            try FileManager.default
                .createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let data = try encoder.encode(allAlbums)
            try data.write(to: url)
        }catch _ {
            print("failed to save albums")
        }
    }
    
    func loadLocalSongs() {
        do{
            let url = appURL.appending(path: "source/localSongs.json")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allLocalSongs = try decoder.decode([LocalMusic].self, from: data)
        }catch _ {
            print("failed to load local songs")
        }
    }
    
    func loadArtists() {
        do{
            let url = appURL.appending(path: "source/artists.json")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allArtists = try decoder.decode([Artist].self, from: data)
        }catch _ {
            print("failed to load artists")
        }
    }
    
    func loadAlbums() {
        do{
            let url = appURL.appending(path: "source/albums.json")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allAlbums = try decoder.decode([Album].self, from: data)
        }catch _ {
            print("failed to load albums")
        }
    }
    
    //導入音樂源的所有音樂
    func loadSources() async {
        let fileManager = FileManager()
        var songs: [LocalMusic] = []

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
        
        totalSongs = Float(urls.count)
        loadedSongs = 0

        // 將找到的音樂加入 allSongs
        for url in urls {
            let music = await loadLocalMusic(url)
            songs.append(music)
            loadedSongs += 1
        }
        
        loadedSongs = -1
        
        allLocalSongs = songs
        
        saveLocalSongs()
        saveAllArtists()
        saveAllAlbums()
    }

    //從姓名或 uuid 獲取藝術家和專輯
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
    
    func getAlbum(_ name: String, temporary: Bool = false) -> Album {
        if let album = allAlbums.first(where: { $0.alias.contains(name) }) {
            return album
        } else {
            let newAlbum = Album(name)
            if !temporary {
                allAlbums.append(newAlbum)
            }
            return newAlbum
        }
    }
    func getAlbum(_ id: UUID) -> Album? {
        return allAlbums.first(where: { $0.id == id })
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
                tags.album = getAlbum(album).id
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

//
//  Views.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

//歌曲顯示視圖
struct MusicView: View {
    @EnvironmentObject var source: Source
    enum MusicViewStyle {
        case common
        case mini
        case tight
    }

    @ObservedObject var music: Music
    @State var musicList: [Music] = []
    @State private var cover: Image?
    @State private var isLoadingCover = false
    var musicStyle: MusicViewStyle = .common
    @EnvironmentObject var player: Play

    private var albumSize: CGFloat {
        switch musicStyle {
        case .common, .tight:
            return 50
        case .mini:
            return 45
        }
    }
    private let albumRoundCorner: CGFloat = 6
    private var height: CGFloat {
        switch musicStyle {
        case .common, .tight:
            return 50
        case .mini:
            return 30
        }
    }

    //封面視圖
    private func CoverView(tapToPlay: Bool = true) -> some View {
        ZStack {
            if let cover {
                cover
                    .resizable()
                    .scaledToFit()

            } else if isLoadingCover {
                ProgressView()
                    .imageScale(.small)
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
        }
        .frame(maxWidth: albumSize, maxHeight: albumSize)
        .cornerRadius(albumRoundCorner)
        //        .contentShape(Rectangle())
        .onTapGesture {
            if tapToPlay {
                player
                    .setList(
                        musicList.isEmpty ? [music] : musicList,
                        startMusic: music
                    )
                player.play()
            }
        }
    }

    //獲取元數據
    var title: String { music.tags.title }
    var albumName: String {
        if let album = music.tags.album {
            return source.getAlbum(album)!.name
        }
        return ""
    }
    var artists: [String] {
        if let artists = music.tags.artists {
            return artists.map { source.getArtist($0)!.name }
        }
        return []
    }

    var body: some View {
        ZStack {
            switch musicStyle {

            //正常型態
            case .common:
                HStack {
                    CoverView()

                    VStack(alignment: .leading) {
                        Text(title)
                        Text(albumName)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }.frame(width: 150, alignment: .leading)

                    HStack(spacing: 8) {
                        ForEach(artists, id: \.self) { artist in
                            Text(artist)
                        }
                    }
                }
            //迷你型態（用於迷你播放器）
            case .mini:
                HStack {
                    CoverView(tapToPlay: false)

                    VStack(alignment: .leading) {
                        Text(title)

                        HStack(spacing: 5) {
                            ForEach(artists, id: \.self) { artist in
                                Text(artist)
                            }
                            Text("-")
                            Text(albumName)
                        }.font(.footnote)
                            .foregroundStyle(.gray)

                    }

                    //                    Spacer()
                }
            //緊湊型態（用於 ios）
            case .tight:
                HStack {
                    CoverView()

                    VStack(alignment: .leading) {
                        Text(title)

                        HStack(spacing: 5) {
                            ForEach(artists, id: \.self) { artist in
                                Text(artist)
                            }
                            Text("-")
                            Text(albumName)
                        }.font(.footnote)
                            .foregroundStyle(.gray)

                    }

                    //                    Spacer()
                }
            }
        }
        .padding()
        .frame(height: height)
        .onAppear {
            updateCover()
        }
        .onChange(of: music.uuid) {
            updateCover()
        }
    }

    func updateCover() {
        Task.detached {
            isLoadingCover = true
            cover = await music.getCover()
            isLoadingCover = false
        }
    }

    func musicStyle(_ style: MusicViewStyle) -> some View {
        MusicView(music: music, musicStyle: style)
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject var player: Play
    @Binding var sideBar: ContentView.SideBar
    var body: some View {
        HStack {
            //播放控制按鈕
            HStack(spacing: 8) {
                //隨機播放
                Button {
                    player.toggleShuffle()
                } label: {
                    Image(systemName: "shuffle")
                        .imageScale(.small)
                        .foregroundStyle(player.shuffled ? .accent : .gray)
                }
                .frame(width: 20)

                //上一首
                Button {
                    player.last()
                } label: {
                    Image(systemName: "backward")
                }
                .frame(width: 10)
                .keyboardShortcut(.leftArrow)
                //暫停 繼續
                Button {
                    if player.playStatus == .playing {
                        player.pause()
                    } else {
                        player.play()
                    }
                } label: {
                    Image(systemName: player.playIcon)
                        .imageScale(.large)
                }
                .frame(width: 30)
                .keyboardShortcut(.space, modifiers: [])
                //下一首
                Button {
                    player.next()
                } label: {
                    Image(systemName: "forward")
                }
                .frame(width: 10)
                .keyboardShortcut(.rightArrow)
            }
            .buttonStyle(.plain)
            .buttonStyle(.glass)

            if player.playStatus != .stopped {
                //音樂信息顯示
                ZStack {
                    let music = player.nowMusic!
                    MusicView(music: music,musicList: player.playList)
                        .musicStyle(.mini)
                }
                .animation(.snappy())
            } else {
                Text("未在播放")
            }

            //邊欄控制
            HStack(spacing: 8) {
                //顯示歌詞
                Button {
                    if sideBar == .lyrics {
                        sideBar = .null
                    } else {
                        sideBar = .lyrics
                    }
                } label: {
                    Image(systemName: "quote.bubble")
                        .imageScale(.small)
                        .foregroundStyle(sideBar == .lyrics ? .accent : .gray)
                }
                .frame(width: 20)

                //顯示播放列表
                Button {
                    if sideBar == .playList {
                        sideBar = .null
                    } else {
                        sideBar = .playList
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .imageScale(.small)
                        .foregroundStyle(sideBar == .playList ? .accent : .gray)
                }
                .frame(width: 20)
            }
            .buttonStyle(.plain)
            .buttonStyle(.glass)
        }
        .padding()
        .frame(height: 40)
        .fixedSize(horizontal: false, vertical: true)
        #if os(macOS)
            .glassEffect()
        #endif
    }
}

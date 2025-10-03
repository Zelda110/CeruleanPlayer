//
//  Views.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

//歌曲顯示視圖
struct MusicView: View {
    enum MusicViewStyle {
        case common
        case mini
    }

    @ObservedObject var music: Music
    @State private var cover: Image?
    @State private var isLoadingCover = false
    var musicStyle: MusicViewStyle = .common
    @EnvironmentObject var player: Play

    private var albumSize: CGFloat {
        switch musicStyle {
        case .common:
            return 50
        case .mini:
            return 45
        }
    }
    private let albumRoundCorner: CGFloat = 6

    //封面視圖
    private func CoverView(tapToPlay: Bool = true) -> some View {
        ZStack {
            if let cover {
                cover
                    .resizable()
                    .scaledToFill()
                    .frame(width: albumSize, height: albumSize)
                    .clipped()
                    .cornerRadius(albumRoundCorner)
            } else if isLoadingCover {
                ProgressView()
                    .frame(width: albumSize, height: albumSize)
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if tapToPlay {
                player.setList([music])
                player.play()
            }
        }
    }

    //獲取元數據
    var title: String { music.tags.title }
    var albumName: String { music.tags.album ?? "" }
    var artists: [String] {
        if let artists = music.tags.artists {
            return artists.map { getArtist($0)!.name }
        }
        return []
    }

    var body: some View {
        ZStack {
            switch musicStyle {
            case .common:
                HStack {
                    CoverView()

                    VStack(alignment: .leading) {
                        Text(title)
                        Text(albumName)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }.frame(width: 150, alignment: .leading)

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(artists, id: \.self) { artist in
                            Text(artist)
                        }
                    }.frame(width: 150, alignment: .leading)

                    Spacer()
                }
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

                    }.frame(width: 300, alignment: .leading)

                    Spacer()
                }
            }
        }
        .padding()
        .task {
            isLoadingCover = true
            cover = await music.getCover()
            isLoadingCover = false
        }
    }

    func musicStyle(_ style: MusicViewStyle) -> some View {
        MusicView(music: music, musicStyle: style)
    }
}

//迷你播放器視圖
struct MiniPlayerView: View {
    @EnvironmentObject var player: Play
    var body: some View {
        HStack {
            HStack{
                Button {
                    player.last()
                } label: {
                    Image(systemName: "backward")
                }
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
                Button {
                    player.next()
                } label: {
                    Image(systemName: "forward")
                }
            }
            .buttonStyle(.glass)
            .frame(width: 90)

            //音樂信息顯示
            ZStack {
                if let music = player.nowMusic {
                    MusicView(music: music)
                        .musicStyle(.mini)
                }
            }
            .animation(.bouncy)
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 60)
        .glassEffect()
    }
}

#Preview {
    @Previewable @State var player = Play()
    MiniPlayerView()
        .environmentObject(player)
        .onAppear {
            player.setList([
                LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.1 芳華絕代.m4a")
                ),
                LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.2 約會.m4a")
                ),
                LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.3 花生騷.m4a")
                ),
                LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.4 相愛很難 (電影_男人四十_歌曲).m4a")
                ),
                LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.5 兩個女人.m4a")
                ),
            ])
        }
}

//
//  ContentView.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

enum Page {
    case music
    case home
}

struct ContentView: View {
    @StateObject var player = Play()
    @State var page: Page = .home
    var body: some View {
        ZStack {
            NavigationSplitView {
                List(selection: $page) {
                    Section {
                        Label("主頁", systemImage: "house")
                            .tag(Page.home)
                    }
                    Section(header: Text("資料庫")) {
                        Label("音樂", systemImage: "music.note")
                            .tag(Page.music)
                    }
                }.listStyle(.sidebar)

            } detail: {
                ZStack {
                    //主頁面
                    switch page {
                    case .home:
                        HomePage()
                    case .music:
                        MusicPage()
                            .safeAreaPadding(.bottom, 50)
                    }

                    //懸浮播放器
                    VStack {
                        Spacer()
                        MiniPlayerView()
                    }
                }.padding()
            }
        }
        .environmentObject(player)
        .frame(minWidth: 800, minHeight: 450)
    }
}

struct HomePage: View {
    var body: some View {

    }
}

struct MusicPage: View {
    var body: some View {
        List {
            MusicView(
                music: LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.1 芳華絕代.m4a")
                )
            )
            MusicView(
                music: LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.2 約會.m4a")
                )
            )
            MusicView(
                music: LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.3 花生騷.m4a")
                )
            )
            MusicView(
                music: LocalMusic(
                    url: URL(
                        filePath:
                            "/Users/zelda/Music/With/1.4 相愛很難 (電影_男人四十_歌曲).m4a"
                    )
                )
            )
            MusicView(
                music: LocalMusic(
                    url: URL(filePath: "/Users/zelda/Music/With/1.5 兩個女人.m4a")
                )
            )
        }
    }
}

#Preview {
    ContentView()
}

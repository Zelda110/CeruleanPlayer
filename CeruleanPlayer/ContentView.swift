//
//  ContentView.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var player = Play()
    var body: some View {
        HomeView()
            .environmentObject(player)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("資料庫")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                NavigationLink {
                    List{
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
                                url: URL(filePath: "/Users/zelda/Music/With/1.4 相愛很難 (電影_男人四十_歌曲).m4a")
                            )
                        )
                        MusicView(
                            music: LocalMusic(
                                url: URL(filePath: "/Users/zelda/Music/With/1.5 兩個女人.m4a")
                            )
                        )
                    }
                } label: {
                    Label("音樂", systemImage: "music.note")
                }
            }
            .listStyle(.sidebar)
        } detail: {
            
        }
    }
}

#Preview {
    ContentView()
}

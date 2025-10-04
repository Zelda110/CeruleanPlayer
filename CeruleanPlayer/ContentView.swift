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
    @StateObject var source = Source()
    @State var page: Page = .home
    var body: some View {
        ZStack {
            #if os(macOS)
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
                                .safeAreaPadding(.bottom, 30)
                        }

                        //懸浮播放器
                        VStack {
                            Spacer()
                            MiniPlayerView()
                        }
                    }.padding()
                }
            #elseif os(iOS)
                TabView {
                    Tab {
                        HomePage()
                    } label: {
                        Label("首頁", systemImage: "house")
                    }
                    Tab {
                        NavigationStack {
                            NavigationLink {
                                MusicPage()
                                    .navigationTitle("音樂")
                                    .navigationBarTitleDisplayMode(.large)
                            } label: {
                                Label("音樂", systemImage: "music.note")
                            }
                        }.navigationTitle("資料庫")
                    } label: {
                        Label("資料庫", systemImage: "music.note.square.stack")
                    }
                }
                .tabViewBottomAccessory {
                    MiniPlayerView()
                        .environmentObject(player)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            #endif
        }
        .environmentObject(player)
        .environmentObject(source)
        #if os(macOS)
            .frame(minWidth: 800, minHeight: 450)
        #endif
        .onAppear {
            Task.detached{
                print("a")
                await source.loadSources()
            }
        }
    }
}

struct HomePage: View {
    var body: some View {

    }
}

struct MusicPage: View {
    @EnvironmentObject var source: Source
    #if os(macOS)
        @State var musicStyle: MusicView.MusicViewStyle = .common
    #elseif os(iOS)
        @State var musicStyle: MusicView.MusicViewStyle = .tight
    #endif
    var body: some View {
        List {
            ForEach(source.allSongs,id: \.uuid){ music in
                MusicView(music: music, musicList: source.allSongs)
            }
        }
    }
}

#Preview {
    ContentView()
}

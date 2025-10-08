//
//  ContentView.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

struct ContentView: View {
    enum Page {
        case music
        case home
        case localSource
    }
    enum SideBar {
        case playList
        case lyrics
        case null
    }

    @StateObject var player = Play()
    @StateObject var source = Source()
    @State var page: Page = .music
    @State var sideBar: SideBar = .playList

    //顯示導入本地音樂進度
    private struct LoadingProgressView: View {
        @EnvironmentObject var source: Source
        var body: some View {
            if source.loadedSongs >= 0 {
                VStack(spacing: 0) {
                    Text("正在載入本地音樂源")
                    Text("\(Int(source.loadedSongs))/\(Int(source.totalSongs))")
                    ProgressView(
                        value: source.loadedSongs,
                        total: source.totalSongs
                    )
                }.padding(8)
            }
        }
    }

    var body: some View {
        ZStack {
            #if os(macOS)
                NavigationSplitView {
                    VStack {
                        List(selection: $page) {
                            Section {
                                Label("主頁", systemImage: "house")
                                    .tag(Page.home)
                            }
                            Section(header: Text("資料庫")) {
                                Label("音樂", systemImage: "music.note")
                                    .tag(Page.music)
                            }
                            Section(header: Text("音樂源")) {
                                Label("本地", systemImage: "desktopcomputer")
                                    .tag(Page.localSource)
                            }
                        }.listStyle(.sidebar)
                        Spacer()
                        LoadingProgressView()
                    }
                } detail: {
                    ZStack {
                        //主頁面
                        ZStack {
                            switch page {
                            case .home:
                                HomePage()
                            case .music:
                                MusicPage()
                            case .localSource:
                                LocalSourcePage()
                            }
                        }.safeAreaPadding(.bottom, 30)

                        //懸浮播放器
                        VStack {
                            Spacer()
                            MiniPlayerView(sideBar: $sideBar)
                        }
                    }.safeAreaPadding(.trailing, sideBar == .null ? 0 : 300)
                        .padding()
                }
                .frame(minWidth: sideBar == .null ? 700 : 1000, minHeight: 450)

                HStack {
                    Spacer()
                    ZStack {
                        switch sideBar {
                        case .playList:
                            PlayListView()
                        case .lyrics:
                            EmptyView()
                        case .null:
                            EmptyView()
                        }
                    }
                    .ignoresSafeArea()
                    .background(.clear)
                    .glassEffect(.identity, in: .rect)
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
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .environmentObject(player)
        .environmentObject(source)
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
            ForEach(source.allLocalSongs, id: \.uuid) { music in
                MusicView(
                    music: music as Music,
                    musicList: source.allLocalSongs
                )
            }
        }
    }
}

struct LocalSourcePage: View {
    @EnvironmentObject var source: Source
    var body: some View {
        VStack(alignment: .leading) {
            Text("音樂源")
            VStack {
                ForEach(source.songSources, id: \.self) { s in
                    HStack {
                        Text(s.path())
                        Spacer()
                        Button("-") {
                            source.songSources.removeAll { $0 == s }
                        }
                    }
                }
            }
            HStack {
                Button {

                } label: {
                    Label("添加檔案夾", systemImage: "plus")
                }
                Button {
                    Task.detached {
                        await source.loadSources()
                    }
                } label: {
                    Label("重新掃描", systemImage: "magnifyingglass")
                }
            }
        }.padding()
    }
}

#Preview {
    ContentView()
}

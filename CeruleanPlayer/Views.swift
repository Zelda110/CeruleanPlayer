//
//  Views.swift
//  CeruleanPlayer
//
//  Created by ハイラル・ゼルダ on 27/9/2025.
//

import SwiftUI

//歌曲顯示視圖
struct MusicView<M: Music>: View {
    @ObservedObject var music: M
    @State private var cover: Image?
    @State private var isLoadingCover = false
    @EnvironmentObject var player: Play

    var body: some View {
        HStack {
            //封面
            ZStack {
                // 佔位背景
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)

                if let cover {
                    cover
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipped()
                        .cornerRadius(8)
                } else if isLoadingCover {
                    ProgressView()
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
            }.onTapGesture {
                player.playList = [music]
                player.play()
            }

            VStack(alignment: .leading){
                //標題
                if let title = music.tags.title {
                    Text(title)
                } else {
                    Text("No title")
                        .font(.footnote)
                }
                //專輯
                if let album = music.tags.album {
                    Text(album)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()

            //藝術家
            if let artists = music.tags.artists {
                HStack {
                    ForEach(artists, id: \.self) { artist in
                        if let art = getArtist(artist) {
                            Text(art.name)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .task {
            // 視圖出現時載入封面
            isLoadingCover = true
            cover = await music.getCover()
            isLoadingCover = false
        }
    }
}

//
//  ContentView.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 12/13/23.
//

import SwiftUI

//struct ContentView: View {
//    var body: some View {
//        ZStack
//        {
//            Color.mainBackground.ignoresSafeArea()
//            CrosswordView()
//        }
//
//    }
//}


//TEST CHANGES GOR GITHUB COMMIT

struct MainView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainBackground.ignoresSafeArea()
                VStack {
                    NavigationLink(destination: PlayView()) {
                        Text("Play")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: LoadOrCreateView()) {
                        Text("Create")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}

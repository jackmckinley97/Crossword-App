//
//  LoadOrCreateView.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/5/24.
//

import SwiftUI
import Foundation

struct LoadOrCreateView: View {
    @State private var savedCrosswords: [Crossword] = []
    @State private var showingDeleteConfirmation = false
    @State private var crosswordToDelete: Crossword?
    private let dataService = CrosswordDataService()

    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            VStack {
                Text("Load or Create Crossword")
                    .font(.headline)
                    .padding()

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(savedCrosswords) { crossword in
                            HStack {
                                NavigationLink(destination: CreateCrosswordView(crossword: crossword)) {
                                    Text(crossword.title)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                                Spacer()
                                Button(action: {
                                    crosswordToDelete = crossword
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .padding(.trailing)
                            }
                        }
                    }
                }

                NavigationLink(destination: CreateSettingsView()) {
                    Text("Create New")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .onAppear {
                loadSavedCrosswords()
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Crossword"),
                    message: Text("Are you sure you want to delete this crossword?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let crossword = crosswordToDelete {
                            deleteCrossword(crossword)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func loadSavedCrosswords() {
        self.savedCrosswords = dataService.fetchCrosswords()
    }

    private func deleteCrossword(_ crossword: Crossword) {
        dataService.deleteCrossword(crossword)
        loadSavedCrosswords()
    }
}

#Preview {
    LoadOrCreateView()
}

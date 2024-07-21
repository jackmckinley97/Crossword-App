//
//  CreateCluesView.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 12/17/23.
//

import SwiftUI
import Foundation

struct CreateCluesView: View {
    var wordEntries: [WordEntry]
    @Binding var clues: [UUID: String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Across")
                    .font(.headline)
                    .padding()

                ForEach(wordEntries.filter { $0.direction == .across }) { wordEntry in
                    HStack {
                        Text("\(wordEntry.clueNumber). \(wordEntry.word)")
                        TextField("Enter clue", text: Binding(
                            get: { self.clues[wordEntry.id] ?? "" },
                            set: { self.clues[wordEntry.id] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                }

                Text("Down")
                    .font(.headline)
                    .padding()

                ForEach(wordEntries.filter { $0.direction == .down }) { wordEntry in
                    HStack {
                        Text("\(wordEntry.clueNumber). \(wordEntry.word)")
                        TextField("Enter clue", text: Binding(
                            get: { self.clues[wordEntry.id] ?? "" },
                            set: { self.clues[wordEntry.id] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarItems(trailing: Button("Save") {
            print("Clues saved: \(clues)") // Verify the clues are saved here
        })
    }
}

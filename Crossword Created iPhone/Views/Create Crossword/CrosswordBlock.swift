//
//  CrosswordBlock.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/21/24.
//

import SwiftUI

struct CrosswordBlock: View {
    var xIndex: Int
    var yIndex: Int
    var tip = -1

    @Binding var selectedXIndex: Int
    @Binding var selectedYIndex: Int
    @Binding var text: String
    @Binding var isBlackSquareModeOn: Bool

    var clueNumber: Int?
    var blockSize: CGFloat
    var isWordSelected: Bool
    var horizontalTypeToggleAction: () -> Void

    var body: some View {
        let isPeriod = text == "."
        let isSelected = selectedXIndex == xIndex && selectedYIndex == yIndex
        let blockColor = getBlockColor(isSelected: isSelected, isWordSelected: isWordSelected, isPeriod: isPeriod)

        return ZStack {
            if let clueNumber = clueNumber {
                Text("\(clueNumber)")
                    .frame(width: blockSize, height: blockSize, alignment: .topLeading)
                    .font(.system(size: blockSize * 0.25))
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .offset(x: blockSize * 0.05, y: 0)
            }

            Text(isPeriod ? "." : text)
                .frame(width: blockSize, height: blockSize, alignment: .center)
                .font(.system(size: blockSize * 0.6))
                .fontWeight(.bold)
                .foregroundColor(isPeriod ? .clear : .black)
        }
        .foregroundColor(.white)
        .frame(width: blockSize, height: blockSize)
        .background(
            Rectangle()
                .foregroundColor(blockColor)
                .cornerRadius(blockSize * 0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: blockSize * 0.1)
                .stroke(Color.selectedBlockBorder, lineWidth: isSelected ? blockSize * 0.05 : 0)
        )
        .onTapGesture {
            if isBlackSquareModeOn {
                text = (text == ".") ? " " : "."
            } else {
                if text != "." {
                    if selectedXIndex == xIndex && selectedYIndex == yIndex {
                        horizontalTypeToggleAction()
                    }
                    selectedXIndex = xIndex
                    selectedYIndex = yIndex
                }
            }
        }

        func getBlockColor(isSelected: Bool, isWordSelected: Bool, isPeriod: Bool) -> Color {
            if isPeriod {
                return .black
            }
            if isSelected {
                return .selectedBlockBackground
            }
            if isWordSelected {
                return .selectedWordBackgroundGood
            }
            return .unselectedBlockBackground
        }
    }
}

//
//  CarouselView.swift
//
//  Created by Mohamed Nassar on 9/29/20.
//  Copyright © 2020 Mohamed Nassar. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit

public struct CarouselViewStyle {
    public let sliderWidth: CGFloat
    public let spacing: CGFloat
    public let widthOfHiddenCards: CGFloat
    public let cardHeight: CGFloat
    public let shadowRadius: CGFloat
    public let showPagesIndicator: Bool
    public let selectedPagesIndicatorColor: Color
    public let unSelectedPagesIndicatorColor: Color
    /// 0.9
    public let magnificationRatio: CGFloat
    public var cardWidth: CGFloat {
        return sliderWidth - (widthOfHiddenCards*2) - (spacing*2)
    }
    
    public init(
        sliderWidth: CGFloat,
        spacing: CGFloat = 16,
        widthOfHiddenCards: CGFloat = 15,
        cardHeight: CGFloat = 250,
        shadowRadius: CGFloat = 1,
        showPagesIndicator: Bool = true,
        magnificationRatio: CGFloat = 0.9,
        selectedPagesIndicatorColor: Color = .black,
        unSelectedPagesIndicatorColor: Color = .gray
    ) {
        self.sliderWidth = sliderWidth
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.cardHeight = cardHeight
        self.shadowRadius = shadowRadius
        self.showPagesIndicator = showPagesIndicator
        self.magnificationRatio = magnificationRatio
        self.selectedPagesIndicatorColor = selectedPagesIndicatorColor
        self.unSelectedPagesIndicatorColor = unSelectedPagesIndicatorColor
    }
}

public struct CarouselView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable & Identifiable {
    private let style: CarouselViewStyle
    
    private var data: Data
    @Binding var active: Data.Element
    private var content: (Data.Element) -> Content
    
    public init(_ data: Data, active: Binding<Data.Element>, style: CarouselViewStyle, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self._active = active
        self.style = style
        self.content = content
    }
    
    private var activeIndex: Binding<Int> {
        return Binding(get: {(data.firstIndex(of: self.active) as? Int) ?? 0}, set: {active = data[$0 as! Data.Index]})
    }
    
    public var body: some View {
        SliderViewContainer(
            activeIndex: activeIndex,
            numberOfItems: data.count,
            spacing: style.spacing,
            cardWidth: style.cardWidth,
            totalWidth: style.sliderWidth,
            widthOfHiddenCards: style.widthOfHiddenCards,
            showPagesIndicator: style.showPagesIndicator,
            selectedPagesIndicatorColor: style.selectedPagesIndicatorColor,
            unSelectedPagesIndicatorColor: style.unSelectedPagesIndicatorColor
        ) {
            ForEach(data) { item in
                CardView {
                    content(item)
                }
                .frame(width: style.cardWidth, height: active == item ? style.cardHeight : style.cardHeight * style.magnificationRatio, alignment: .center)
                .cornerRadius(8)
                .shadow(radius: style.shadowRadius)
                .transition(.slide)
                .animation(.spring())
                
            }
        }
        .frame(minWidth: 0, idealWidth: 370, maxWidth: .infinity, minHeight: 0, idealHeight: 250, maxHeight: .infinity, alignment: .center)
        
    }
}

struct SliderViewContainer<Items: View>: View {
    private let items: Items
    private let numberOfItems: Int //= 8
    private let spacing: CGFloat //= 16
    private let widthOfHiddenCards: CGFloat //= 32
    private let totalSpacing: CGFloat
    private let cardWidth: CGFloat
    private let totalWidth: CGFloat
    private let showPagesIndicator: Bool
    private let selectedPagesIndicatorColor: Color
    private let unSelectedPagesIndicatorColor: Color

    @GestureState var isDetectingLongPress = false
    
    @Binding var activeIndex: Int
    @State private var screenDrag: Float = 0.0
    
    init(
        activeIndex: Binding<Int>,
        numberOfItems: Int,
        spacing: CGFloat,
        cardWidth: CGFloat,
        totalWidth: CGFloat,
        widthOfHiddenCards: CGFloat,
        showPagesIndicator: Bool,
        selectedPagesIndicatorColor: Color,
        unSelectedPagesIndicatorColor: Color,
        @ViewBuilder _ items: () -> Items) {
        self._activeIndex = activeIndex
        self.items = items()
        self.numberOfItems = numberOfItems
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.totalSpacing = CGFloat((numberOfItems - 1)) * spacing
        self.cardWidth = cardWidth
        self.totalWidth = totalWidth
        self.showPagesIndicator = showPagesIndicator
        self.selectedPagesIndicatorColor = selectedPagesIndicatorColor
        self.unSelectedPagesIndicatorColor = unSelectedPagesIndicatorColor

    }
    
    var body: some View {
        
        let totalCanvasWidth: CGFloat = (cardWidth * CGFloat(numberOfItems)) + totalSpacing
        let xOffsetToShift = (totalCanvasWidth - totalWidth) / 2
        let leftPadding = widthOfHiddenCards + spacing
        let totalMovement = cardWidth + spacing
        
        let activeOffset = xOffsetToShift + (leftPadding) - (totalMovement * CGFloat(activeIndex))
        let nextOffset = xOffsetToShift + (leftPadding) - (totalMovement * CGFloat(activeIndex) + 1)
        
        var calcOffset = Float(activeOffset)
        
        if (calcOffset != Float(nextOffset)) {
            calcOffset = Float(activeOffset) + screenDrag
        }
        
        return VStack {
            HStack(alignment: .center, spacing: spacing) {
                items
            }
            .offset(x: CGFloat(calcOffset), y: 0)
            .gesture(DragGesture().updating($isDetectingLongPress) { currentState, gestureState, transaction in
                screenDrag = Float(currentState.translation.width)
                
            }.onEnded { value in
                screenDrag = 0
                
                if (value.translation.width < -50 && CGFloat(activeIndex) < CGFloat(numberOfItems - 1)) {
                    activeIndex = activeIndex + 1
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                }
                
                if (value.translation.width > 50 && CGFloat(activeIndex) > 0) {
                    activeIndex = activeIndex - 1
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                }
            })
            
            if showPagesIndicator {
                PageControl(index: $activeIndex, maxIndex: numberOfItems - 1, selectedCapsuleColor: selectedPagesIndicatorColor, unSelectedCapsuleColor: unSelectedPagesIndicatorColor)
            }
            
        }
    }
}

struct PageControl: View {
    @Binding var index: Int
    let maxIndex: Int
    let selectedCapsuleColor: Color
    let unSelectedCapsuleColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0...maxIndex, id: \.self) { index in
                Capsule()
                    .fill(index == self.index ? selectedCapsuleColor : unSelectedCapsuleColor)
                    .frame(width: index == self.index ? 15 : 6, height: 6)
                    .animation(.spring())
            }
        }
        .padding(15)
    }
}

struct CardView<Content: View>: View {
    var content: Content
    
    init( @ViewBuilder _ content: () -> Content ) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

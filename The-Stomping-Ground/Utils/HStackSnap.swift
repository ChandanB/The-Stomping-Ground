//
//  HStackSnap.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/6/23.
//

import Foundation
import SwiftUI

public struct HStackSnap<Content: View>: View {
    private let alignment: SnapAlignment
    private let spacing: CGFloat?
    private let coordinateSpace: String
    private let content: () -> Content
    private let eventHandler: SnapToScrollEventHandler?

    public init(
        alignment: SnapAlignment,
        spacing: CGFloat? = nil,
        coordinateSpace: String = "SnapToScroll",
        @ViewBuilder content: @escaping () -> Content,
        eventHandler: SnapToScrollEventHandler? = .none) {

        self.alignment = alignment
        self.spacing = spacing
        self.coordinateSpace = coordinateSpace
        self.content = content
        self.eventHandler = eventHandler
    }

    public var body: some View {
        GeometryReader { geometry in
            HStackSnapCore(
                alignment: alignment,
                spacing: spacing,
                coordinateSpace: coordinateSpace,
                content: content,
                eventHandler: eventHandler)
                .environmentObject(SizeOverride(itemWidth: alignment.shouldSetWidth ? calculatedItemWidth(parentWidth: geometry.size.width, offset: alignment.scrollOffset) : .none))
        }
    }

    private func calculatedItemWidth(parentWidth: CGFloat, offset: CGFloat) -> CGFloat {
        return parentWidth - offset * 2
    }
}

public typealias SnapToScrollEventHandler = ((SnapToScrollEvent) -> Void)

public struct HStackSnapCore<Content: View>: View {
    private let alignment: SnapAlignment
    private let spacing: CGFloat?
    private let coordinateSpace: String
    private let content: () -> Content
    private let eventHandler: SnapToScrollEventHandler?

    @State private var preferences: [ContentPreferenceData] = []
    @State private var hasCalculatedFrames: Bool = false
    @State private var scrollOffset: CGFloat
    @State private var prevScrollOffset: CGFloat = 0
    @State private var snapLocations: [Int: CGFloat] = [:]
    @State private var previouslySentIndex: Int = 0

    public init(
        alignment: SnapAlignment,
        spacing: CGFloat? = nil,
        coordinateSpace: String = "SnapToScroll",
        @ViewBuilder content: @escaping () -> Content,
        eventHandler: SnapToScrollEventHandler? = .none) {

        self.alignment = alignment
        self.spacing = spacing
        self.coordinateSpace = coordinateSpace
        self.content = content
        self.eventHandler = eventHandler
        self.scrollOffset = alignment.scrollOffset
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack {
                    HStack(spacing: spacing, content: content)
                        .offset(x: scrollOffset, y: .zero)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .onPreferenceChange(ContentPreferenceKey.self, perform: { newPreferences in
                self.preferences = newPreferences
                
                if !hasCalculatedFrames {
                    let screenWidth = geometry.frame(in: .named(coordinateSpace)).width
                    var itemScrollPositions: [Int: CGFloat] = [:]
                    var frameMaxXVals: [CGFloat] = []

                    for (index, preference) in newPreferences.enumerated() {
                        itemScrollPositions[index] = scrollOffset(for: preference.rect.minX)
                        frameMaxXVals.append(preference.rect.maxX)
                    }

                    var contentFitMap: [CGFloat] = []

                    for currMinX in newPreferences.map({ $0.rect.minX }) {
                        guard let maxX = newPreferences.last?.rect.maxX else { break }
                        let widthToEnd = maxX - currMinX
                        contentFitMap.append(widthToEnd)
                    }

                    var frameTrim: Int = 0
                    let reversedFitMap = Array(contentFitMap.reversed())

                    for i in 0 ..< reversedFitMap.count {
                        if reversedFitMap[i] > screenWidth {
                            frameTrim = max(i - 1, 0)
                            break
                        }
                    }

                    for (i, item) in itemScrollPositions.sorted(by: { $0.value > $1.value })
                        .enumerated()
                    {
                        guard i < (itemScrollPositions.count - frameTrim) else { break }
                        snapLocations[item.key] = item.value
                    }

                    hasCalculatedFrames = true
                    
                    eventHandler?(.didLayout(layoutInfo: itemScrollPositions))
                }
            })
            .gesture(snapDrag)
        }
        .coordinateSpace(name: coordinateSpace)
    }

    private var snapDrag: some Gesture {
        DragGesture()
            .onChanged { gesture in
                self.scrollOffset = gesture.translation.width + prevScrollOffset
            }.onEnded { _ in
                let currOffset = scrollOffset
                var closestSnapLocation: CGFloat = snapLocations.first?.value ?? alignment.scrollOffset

                for (_, offset) in snapLocations {
                    if abs(offset - currOffset) < abs(closestSnapLocation - currOffset) {
                        closestSnapLocation = offset
                    }
                }

                let selectedIndex = snapLocations.map { $0.value }.sorted(by: { $0 > $1 })
                    .firstIndex(of: closestSnapLocation) ?? 0
                
                previouslySentIndex = selectedIndex // Update the previouslySentIndex variable

                if selectedIndex != previouslySentIndex {
                    eventHandler?(.swipe(index: selectedIndex))
                }

                withAnimation(.easeOut(duration: 0.2)) {
                    scrollOffset = closestSnapLocation
                }
                prevScrollOffset = scrollOffset
            }
    }

    private func scrollOffset(for x: CGFloat) -> CGFloat {
        return (alignment.scrollOffset * 2) - x
    }
}

public enum SnapAlignment {

    case leading(CGFloat)
    case center(CGFloat)
    
    internal var scrollOffset: CGFloat {
        
        switch self {
            
        case let .leading(offset): return offset
        case let .center(offset): return offset
        }
    }
    
    internal var shouldSetWidth: Bool {
        
        switch self {
            
        case .leading: return false
        case .center: return true
        }
    }
}

class SizeOverride: ObservableObject {
    @Published var itemWidth: CGFloat?

    init(itemWidth: CGFloat?) {
        self.itemWidth = itemWidth
    }
}

public enum SnapToScrollEvent {
    case swipe(index: Int)
    case didLayout(layoutInfo: [Int: CGFloat])
}

struct ContentPreferenceData: Equatable {
    let id: Int
    let rect: CGRect
}

struct ContentPreferenceKey: PreferenceKey {
    typealias Value = [ContentPreferenceData]
    
    static var defaultValue: [ContentPreferenceData] = []
    
    static func reduce(value: inout [ContentPreferenceData], nextValue: () -> [ContentPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

struct SnapAlignmentHelper<ID: Hashable>: ViewModifier {

    @EnvironmentObject var sizeOverride: SizeOverride

    var id: ID
    var coordinateSpace: String?

    func body(content: Content) -> some View {

        switch sizeOverride.itemWidth {

        case let .some(value):

            content
                .frame(width: value)
                .overlay(GeometryReaderOverlay(id: id, coordinateSpace: coordinateSpace))

        case .none:

            content
                .overlay(GeometryReaderOverlay(id: id, coordinateSpace: coordinateSpace))
        }
    }
}

extension View {

    public func snapAlignmentHelper<ID: Hashable>(
        id: ID,
        coordinateSpace: String? = .none) -> some View {

        modifier(SnapAlignmentHelper(id: id, coordinateSpace: coordinateSpace))
    }
}

public struct GeometryReaderOverlay<ID: Hashable>: View {

    // MARK: Lifecycle
    public init(id: ID, coordinateSpace: String?) {

        self.id = id
        optionalCoordinateSpace = coordinateSpace
    }

    // MARK: Public
    public var body: some View {

        GeometryReader { geometry in

            Rectangle().fill(Color.clear)
                .preference(
                    key: ContentPreferenceKey.self,
                    value: [ContentPreferenceData(
                        id: id.hashValue,
                        rect: geometry.frame(in: .named(coordinateSpace)))])
        }
    }

    // MARK: Internal
    let id: ID
    let optionalCoordinateSpace: String?

    let defaultCoordinateSpace = "SnapToScroll"

    var coordinateSpace: String {

        return optionalCoordinateSpace ?? defaultCoordinateSpace
    }
}

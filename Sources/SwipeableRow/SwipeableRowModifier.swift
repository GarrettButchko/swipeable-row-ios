import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Size measurement

private struct RowSizeKey: PreferenceKey {
    static let defaultValue = CGSize.zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

// MARK: - Modifier

public struct SwipeableRowModifier: ViewModifier {
    @Binding var editingID: String?
    @State private var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    @State private var hasVibrated = false
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var isHorizontalDrag: Bool? = nil
    @State private var rowSize: CGSize = .zero

    var id: String
    var highlightColor: Color

    let pausePoint: CGFloat = -100
    let commitPoint: CGFloat = -50
    let resetPoint: CGFloat = 0
    let deletePoint: CGFloat = -220
    var showNonDeleteButtons: Bool { offsetX > deletePoint }

    let buttonOne: ButtonSkim?
    let buttonTwo: ButtonSkim?
    let deleteFunction: (() -> Void)?
    let buttonPressFunction: () -> Void

    public init(
        editingID: Binding<String?>,
        id: String,
        highlightColor: Color = .primary,
        buttonOne: ButtonSkim? = nil,
        buttonTwo: ButtonSkim? = nil,
        deleteFunction: (() -> Void)? = nil,
        buttonPressFunction: @escaping () -> Void
    ) {
        self._editingID = editingID
        self.id = id
        self.highlightColor = highlightColor
        self.buttonOne = buttonOne
        self.buttonTwo = buttonTwo
        self.deleteFunction = deleteFunction
        self.buttonPressFunction = buttonPressFunction
    }

    public func body(content: Content) -> some View {
        content
            // Pin to measured size so the frame never collapses while the row slides.
            .frame(
                width: rowSize.width > 0 ? rowSize.width : nil,
                height: rowSize.height > 0 ? rowSize.height : nil
            )
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: RowSizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(RowSizeKey.self) { size in
                // Only update when the size actually changes to avoid layout loops.
                if abs(rowSize.width - size.width) > 0.5 || abs(rowSize.height - size.height) > 0.5 {
                    rowSize = size
                }
            }
            .overlay(
                highlightColor
                    .opacity(isPressed ? 0.32 : 0)
                    .mask(content)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.12), value: isPressed)
            )
            .background(alignment: .trailing) {
                if editingID == id {
                    actionButtons
                        .opacity(offsetX < -10 ? 1 : 0)
                        .offset(x: -offsetX)
                        .frame(width: max(0, -offsetX - 10))
                        .transition(.opacity)
                        .padding(.leading)
                }
            }
            .offset(x: offsetX)
            .simultaneousGesture(dragGesture)
            .onTapGesture {
                guard !isDragging else { return }
                if editingID != id {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { isPressed = false }
                    buttonPressFunction()
                }
            }
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 10,
                pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.12)) { isPressed = pressing }
                },
                perform: {
                    if editingID != id { buttonPressFunction() }
                }
            )
            .onChange(of: editingID) { _, newValue in
                if newValue != id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offsetX = resetPoint
                        lastOffsetX = resetPoint
                    }
                }
            }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            if let deleteFunc = deleteFunction {
                if showNonDeleteButtons {
                    Group {
                        buttonSlot(buttonOne)
                        buttonSlot(buttonTwo)
                    }
                    .transition(.opacity)
                }
                Button { deleteFunc() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(Color.red)
                        if offsetX < -35 {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .opacity(offsetX < commitPoint ? 1 : 0)
                        }
                    }
                }
            } else {
                buttonSlot(buttonOne)
                buttonSlot(buttonTwo)
            }
        }
    }

    @ViewBuilder
    private func buttonSlot(_ skim: ButtonSkim?) -> some View {
        if let skim {
            if skim.isShared {
                SkimShareLinkView(buttonSkim: skim, offsetX: $offsetX)
            } else {
                SkimButtonView(buttonSkim: skim, offsetX: $offsetX)
            }
        }
    }

    // MARK: - Drag gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }
                if !isDragging { isDragging = true }
                let totalOffset = lastOffsetX + value.translation.width
                let clamped = min(resetPoint, max(totalOffset, deletePoint - 80))
                if clamped != offsetX {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offsetX = clamped
                    }
                }
                if offsetX < resetPoint, editingID != id { editingID = id }
                if offsetX < deletePoint && !hasVibrated {
                    triggerHaptic()
                    hasVibrated = true
                } else if offsetX > deletePoint {
                    hasVibrated = false
                }
            }
            .onEnded { _ in
                defer {
                    isDragging = false
                    isHorizontalDrag = nil
                }
                guard isHorizontalDrag == true else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if offsetX < deletePoint {
                        let currentDeleteFunction = deleteFunction
                        offsetX = resetPoint
                        lastOffsetX = resetPoint
                        editingID = nil
                        DispatchQueue.main.async { currentDeleteFunction?() }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if offsetX < commitPoint {
                                offsetX = pausePoint
                            } else {
                                offsetX = resetPoint
                                editingID = nil
                            }
                            lastOffsetX = offsetX
                        }
                    }
                }
            }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

// MARK: - View extension

public extension View {
    func swipeMod(
        editingID: Binding<String?>,
        id: String,
        highlightColor: Color = .primary,
        buttonOne: ButtonSkim? = nil,
        buttonTwo: ButtonSkim? = nil,
        deleteFunction: (() -> Void)? = nil,
        buttonPressFunction: @escaping () -> Void
    ) -> some View {
        modifier(SwipeableRowModifier(
            editingID: editingID,
            id: id,
            highlightColor: highlightColor,
            buttonOne: buttonOne,
            buttonTwo: buttonTwo,
            deleteFunction: deleteFunction,
            buttonPressFunction: buttonPressFunction
        ))
    }
}

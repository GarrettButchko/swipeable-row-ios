import SwiftUI

public struct ButtonSkim {
    public var color: Color
    public var systemImage: String
    public var function: (() -> Void)?
    public var string: String?

    public var isShared: Bool {
        function == nil && string != nil
    }

    public init(color: Color, systemImage: String, function: (() -> Void)? = nil, string: String? = nil) {
        self.color = color
        self.systemImage = systemImage
        self.function = function
        self.string = string
    }
}

public struct SkimButtonView: View {
    let buttonSkim: ButtonSkim
    @Binding var offsetX: CGFloat

    public init(buttonSkim: ButtonSkim, offsetX: Binding<CGFloat>) {
        self.buttonSkim = buttonSkim
        self._offsetX = offsetX
    }

    public var body: some View {
        Button {
            buttonSkim.function?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(buttonSkim.color)
                if offsetX < -35 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(offsetX < -50 ? 1 : 0)
                }
            }
            .clipped()
        }
    }
}

public struct SkimShareLinkView: View {
    let buttonSkim: ButtonSkim
    @Binding var offsetX: CGFloat

    public init(buttonSkim: ButtonSkim, offsetX: Binding<CGFloat>) {
        self.buttonSkim = buttonSkim
        self._offsetX = offsetX
    }

    public var body: some View {
        if let shareString = buttonSkim.string {
            ShareLink(item: shareString) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(buttonSkim.color)
                    if offsetX < -35 {
                        Image(systemName: buttonSkim.systemImage)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .opacity(offsetX < -50 ? 1 : 0)
                    }
                }
                .clipped()
            }
        }
    }
}

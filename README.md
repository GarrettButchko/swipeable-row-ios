# SwipeableRow

A SwiftUI view modifier that adds swipe-to-reveal action buttons to any list row — with optional delete-on-full-swipe and haptic feedback. Built for iOS 17+.

## Features

- Up to two configurable action buttons revealed on left-swipe
- Optional delete action triggered by a full swipe past a threshold
- Haptic feedback at the delete threshold
- Only one row open at a time via a shared `editingID` binding
- Built-in share sheet support via `ShareLink`
- Press highlight animation on tap

## Requirements

- iOS 17+
- Swift 5.9+

## Installation

Add SwipeableRow via Swift Package Manager:

```
https://github.com/garrettbutchko/SwipeableRow
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/garrettbutchko/SwipeableRow", from: "1.0.0")
]
```

## Usage

### Basic setup

Declare a shared `editingID` state in your list view to coordinate which row is open:

```swift
@State private var editingID: String? = nil
```

Apply the `.swipeMod(...)` modifier to each row:

```swift
List(items) { item in
    Text(item.title)
        .swipeMod(
            editingID: $editingID,
            id: item.id,
            highlightColor: .blue,
            buttonOne: ButtonSkim(
                color: .orange,
                systemImage: "bell",
                function: { remind(item) }
            ),
            buttonTwo: ButtonSkim(
                color: .blue,
                systemImage: "square.and.arrow.up",
                string: item.shareURL   // renders as a ShareLink
            ),
            deleteFunction: { delete(item) },
            buttonPressFunction: { open(item) }
        )
}
```

### Action buttons only (no delete)

```swift
Text(item.title)
    .swipeMod(
        editingID: $editingID,
        id: item.id,
        buttonOne: ButtonSkim(color: .green, systemImage: "checkmark", function: { complete(item) }),
        buttonPressFunction: { open(item) }
    )
```

### Delete only

```swift
Text(item.title)
    .swipeMod(
        editingID: $editingID,
        id: item.id,
        deleteFunction: { delete(item) },
        buttonPressFunction: { open(item) }
    )
```

## API Reference

### `View.swipeMod(...)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `editingID` | `Binding<String?>` | required | Shared state tracking which row is open. |
| `id` | `String` | required | Unique identifier for this row. |
| `highlightColor` | `Color` | `.primary` | Color of the press-highlight overlay. |
| `buttonOne` | `ButtonSkim?` | `nil` | First (top) action button. |
| `buttonTwo` | `ButtonSkim?` | `nil` | Second (bottom) action button. |
| `deleteFunction` | `(() -> Void)?` | `nil` | Called when the row is swiped past the delete threshold. Renders a red delete button. |
| `buttonPressFunction` | `() -> Void` | required | Called on tap or long-press when the row is not open. |

### `ButtonSkim`

| Property | Type | Description |
|---|---|---|
| `color` | `Color` | Background color of the button. |
| `systemImage` | `String` | SF Symbol name shown on the button. |
| `function` | `(() -> Void)?` | Action to perform on tap. If `nil` and `string` is set, renders as a `ShareLink`. |
| `string` | `String?` | Content passed to `ShareLink` when `function` is `nil`. |

## License

MIT

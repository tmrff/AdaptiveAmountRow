import Combine
import SwiftUI

// MARK: - AdaptiveAmountList

struct AdaptiveAmountList: View {
  private let short = "short Text"
  private let medium =
  "some text which can obviously be wrapped in two lines"
  private let long = "A lot of text which can obviously be wrapped in many lines!"
  
  var body: some View {
    List {
      AdaptiveAmountRow(title: short)
      AdaptiveAmountRow(title: medium)
      AdaptiveAmountRow(title: long)
    }
  }
}

// MARK: - Preview

#Preview {
  AdaptiveAmountList()
}

// MARK: - Adaptive Amount Row

/// A row view that automatically selects the most appropriate layout based on text content
struct AdaptiveAmountRow: View {
  private let title: String
  private let amount: String = "$ 10.00"
  
  @State private var layoutStatuses: [LayoutMode: Bool] = [:]
  
  /// The first layout mode that can display the content without truncation
  private var optimalLayoutMode: LayoutMode? {
    return layoutStatuses.keys
      .sorted(by: { $0 < $1 })
      .first { !(layoutStatuses[$0] ?? true) }
  }
  
  init(title: String) {
    self.title = title
  }
  
  var body: some View {
    ZStack {
      CompactAmountRowLayout(title: title, amount: amount)
        .layoutPriority(isLayoutSelected(.compact) ? 2 : 1)
        .opacity(isLayoutSelected(.compact) ? 1 : 0)
      
      StandardAmountRowLayout(title: title, amount: amount)
        .layoutPriority(isLayoutSelected(.standard) ? 2 : 1)
        .opacity(isLayoutSelected(.standard) ? 1 : 0)
      
      ExtendedAmountRowLayout(title: title, amount: amount)
        .layoutPriority(isLayoutSelected(.extended) ? 2 : 1)
        .opacity(isLayoutSelected(.extended) ? 1 : 0)
    }
    .onPreferenceChange(LayoutTruncationStatus.self) { statuses in
      self.layoutStatuses = statuses
    }
    .onChange(of: optimalLayoutMode) { _, newMode in
#if DEBUG
      print("Optimal layout mode: \(newMode?.description ?? "none")")
#endif
    }
  }
  
  private func isLayoutSelected(_ mode: LayoutMode) -> Bool {
    return optimalLayoutMode == mode
  }
}

// MARK: - Layout Implementations

/// Compact layout - single line horizontal arrangement
struct CompactAmountRowLayout: View {
  let title: String
  let amount: String
  
  var body: some View {
    let titleView = TruncationDetectingText(
      title,
      maxLines: 1,
      layoutMode: .compact)
      .multilineTextAlignment(.leading)
      .font(.body)
    
    let amountView = createAmountView()
    
    HStack(alignment: .center) {
      titleView
      Spacer(minLength: 2)
      amountView
    }
  }
  
  private func createAmountView() -> some View {
    Text(amount)
      .multilineTextAlignment(.center)
      .font(.title)
      .fixedSize()
  }
}

/// Standard layout - two-line horizontal arrangement
struct StandardAmountRowLayout: View {
  let title: String
  let amount: String
  
  var body: some View {
    let titleView = TruncationDetectingText(
      title,
      maxLines: 2,
      layoutMode: .standard)
      .multilineTextAlignment(.leading)
      .font(.body)
    
    let amountView = createAmountView()
    
    HStack(alignment: .lastTextBaseline) {
      titleView
      Spacer(minLength: 2)
      amountView
    }
  }
  
  private func createAmountView() -> some View {
    Text(amount)
      .multilineTextAlignment(.center)
      .font(.title)
      .fixedSize()
  }
}

/// Extended layout - vertical arrangement
struct ExtendedAmountRowLayout: View {
  let title: String
  let amount: String
  
  var body: some View {
    let titleView = TruncationDetectingText(
      title,
      maxLines: nil,
      layoutMode: .extended)
      .multilineTextAlignment(.leading)
      .font(.body)
    
    let amountView = createAmountView()
    
    VStack(alignment: .leading) {
      titleView
      HStack {
        Spacer()
        amountView
      }
    }
  }
  
  private func createAmountView() -> some View {
    Text(amount)
      .multilineTextAlignment(.center)
      .font(.title)
      .fixedSize()
  }
}

// MARK: - Truncation Detecting Text

/// A text view that can detect whether its content is truncated under the given constraints
struct TruncationDetectingText: View {
  private let content: String
  private let maxLines: Int?
  private let layoutMode: LayoutMode
  
  @StateObject var sizeHolder: SizeHolder
  
  
  /// Creates a truncation-detecting text view
  /// - Parameters:
  ///   - content: The text content to display
  ///   - maxLines: Maximum number of lines (nil for unlimited)
  ///   - layoutMode: The layout mode this text belongs to
  init(_ content: String, maxLines: Int?, layoutMode: LayoutMode) {
    self.content = content
    self.layoutMode = layoutMode
    
    if let maxLines = maxLines, maxLines <= 0 {
      fatalError("maxLines cannot be less than or equal to 0")
    }
    
    self.maxLines = maxLines
    _sizeHolder = StateObject(wrappedValue: SizeHolder(maxLine: maxLines))
  }
  
  var body: some View {
    constrainedText
      .measureSize(sizeHolder.binding(keyPath: \.actualSize))
      .background {
        naturalHeightText
          .measureSize(sizeHolder.binding(keyPath: \.naturalHeightSize))
          .hidden()
      }
      .background {
        naturalWidthText
          .measureSize(sizeHolder.binding(keyPath: \.naturalWidthSize))
          .hidden()
      }
      .overlay {
        if let isContentTruncated = sizeHolder.isContentTruncated {
          Color.clear
            .preference(
              key: LayoutTruncationStatus.self,
              value: [layoutMode: isContentTruncated])
        }
      }
#if DEBUG
      .task(id: sizeHolder.isContentTruncated) {
        if let isContentTruncated = sizeHolder.isContentTruncated {
          print(
            "Layout \(layoutMode.description) - Content truncated: \(isContentTruncated)")
        }
      }
#endif
  }
  
  @ViewBuilder
  private var constrainedText: some View {
    switch maxLines {
    case .none:
      Text(content)
    default:
      Text(content)
        .lineLimit(maxLines ?? 1, reservesSpace: true)
    }
  }
  
  /// Text with natural height (allows wrapping within given width)
  private var naturalHeightText: some View {
    Text(content)
      .fixedSize(horizontal: false, vertical: true)
  }
  
  /// Text with natural width (single line, no wrapping)
  private var naturalWidthText: some View {
    Text(content)
      .fixedSize(horizontal: true, vertical: false)
  }
}

@MainActor
final class SizeHolder: ObservableObject {
  var actualSize: CGSize = .zero {
    didSet {
      needsUpdate()
    }
  }
  
  var naturalHeightSize: CGSize = .zero {
    didSet {
      needsUpdate()
    }
  }
  
  var naturalWidthSize: CGSize = .zero {
    didSet {
      needsUpdate()
    }
  }
  
  var maxLines: Int?
  
  init(maxLine: Int? = nil) {
    maxLines = maxLine
  }
  
  @Published var isContentTruncated: Bool?
  
  func needsUpdate() {
    guard actualSize != .zero,
          naturalWidthSize != .zero,
          naturalHeightSize != .zero
    else {
      return
    }
    
    switch maxLines {
    case .none:
      isContentTruncated = false
    case 1:
      // For single line: check if natural width exceeds actual width
      isContentTruncated = naturalWidthSize.width > actualSize.width
    default:
      // For multiple lines: check if natural height exceeds actual height
      isContentTruncated = naturalHeightSize.height > actualSize.height
    }
  }
  
  func binding(keyPath: ReferenceWritableKeyPath<SizeHolder, CGSize>) -> Binding<CGSize> {
    Binding(
      get: { self[keyPath: keyPath] },
      set: { self[keyPath: keyPath] = $0 })
  }
}

// MARK: - Layout Mode

/// Represents different layout modes for amount rows
enum LayoutMode: Int, Hashable, Identifiable, CaseIterable {
  case compact // Single line horizontal layout
  case standard // Two-line horizontal layout
  case extended // Vertical layout
  
  var id: Self { self }
}

extension LayoutMode: Comparable {
  static func < (lhs: LayoutMode, rhs: LayoutMode) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension LayoutMode: CustomStringConvertible {
  var description: String {
    switch self {
    case .compact:
      return "compact"
    case .standard:
      return "standard"
    case .extended:
      return "extended"
    }
  }
}

// MARK: - Preference Key

/// Preference key for collecting truncation status from multiple layout modes
struct LayoutTruncationStatus: PreferenceKey {
  static var defaultValue: [LayoutMode: Bool] = [:]
  
  static func reduce(
    value: inout [LayoutMode: Bool],
    nextValue: () -> [LayoutMode: Bool])
  {
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
  }
}

// MARK: - View Extensions

extension View {
  /// Measures the size of a view and binds it to the provided binding
  /// - Parameter size: A binding to store the measured size
  /// - Returns: The view with size measurement capability
  func measureSize(_ size: Binding<CGSize>) -> some View {
    background(
      GeometryReader { geometry in
        let currentSize = geometry.size
        Color.clear
          .task(id: currentSize) {
            size.wrappedValue = currentSize
          }
      })
  }
}

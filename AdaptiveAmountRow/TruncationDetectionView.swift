//
//  TruncationDetectionView.swift
//  AdaptiveAmountRow
//
//  Created by Thomas Roff on 05/04/2026.
//

//  SwiftUI doesn't tell you whether a Text view was truncated.
//  The workaround: render three copies of the same string, each under
//  different layout constraints, then compare their measured sizes.

import SwiftUI

struct TruncationDetectionView: View {
  private let long = "A lot of text which can obviously be wrapped in many lines!"
  private let medium = "A medium line of text."
  private let short = "A short line."
  
  private var text: String {
    return long
//    return medium
//    return short
  }
  
  /// Size of the text as actually rendered (constrained by the container).
  @State private var visibleSize: CGSize?
  
  /// Size when width is unlocked — tells us how wide a single line would be.
  /// .fixedSize(horizontal: true, vertical: false)
  @State private var horizontalGhostSize: CGSize?
  
  /// Size when height is unlocked — tells us how tall the text needs when it can wrap freely at the container's width.
  /// .fixedSize(horizontal: false, vertical: true)
  @State private var verticalGhostSize: CGSize?
  
  var isTruncatedOrWrapped: Bool? {
    guard let visibleSize, let verticalGhostSize, let horizontalGhostSize else { return nil }
    // Check if truncated in any dimension
    if visibleSize.width > verticalGhostSize.width || visibleSize.height > horizontalGhostSize.height {
      return true
    } else {
      return false
    }
  }
  
  var layoutDescription: String? {
    guard let visibleSize, let verticalGhostSize, let horizontalGhostSize else {
      return nil
    }
    
    let hasWrapped = visibleSize.height > horizontalGhostSize.height
    
    if hasWrapped {
      if visibleSize.height == verticalGhostSize.height {
        return "wrapped but not truncated"
      } else {
        return "wrapped and truncated"
      }
    } else {
      let hasTruncated = visibleSize.width < horizontalGhostSize.width
      
      if hasTruncated {
        return "single line and truncated"
      } else {
        return "single line but not truncated"
      }
    }
  }
  
  var body: some View {
    VStack {
      Text(text)
        .measureSize($visibleSize)
        .background(
          // Ghost 1 — unlock width, keep height locked.
          // Lays out as a single line: "how wide would I be with no width limit?"
          Text(text)
            .fixedSize(horizontal: true, vertical: false)
            .hidden()
            .measureSize($horizontalGhostSize)
        )
        .background(
          // Ghost 2 — unlock height, keep width locked.
          // Wraps at the container width: "how tall would I be with no height limit?"
          Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .measureSize($verticalGhostSize)
        )
        .frame(width: 100, height: 50)
      
      if let isTruncatedOrWrapped, let layoutDescription {
        Text(isTruncatedOrWrapped ? "isTruncatedOrWrapped" : "Not isTruncatedOrWrapped")
          .foregroundStyle(isTruncatedOrWrapped ? .red : .green)
        
        Text(layoutDescription)
          .foregroundStyle(.blue)
      }
    }
  }
}

/// Reads the size of a view via GeometryReader and writes it to a binding.
/// Uses `.task(id:)` so the binding updates whenever the size changes.
private struct SizeMeasurer: ViewModifier {
  @Binding var size: CGSize?
  
  func body(content: Content) -> some View {
    content.background(
      GeometryReader { geometry in
        Color.clear.task(id: geometry.size) {
          size = geometry.size
        }
      }
    )
  }
}

extension View {
  func measureSize(_ size: Binding<CGSize?>) -> some View {
    modifier(SizeMeasurer(size: size))
  }
}

#Preview {
  TruncationDetectionView()
}

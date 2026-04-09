//
//  ContentView.swift
//  AdaptiveAmountRow
//
//  Created by Thomas Roff on 05/04/2026.
//

import SwiftUI

struct RootView: View {
  var body: some View {
    NavigationStack {
      List {
        NavigationLink("TruncationDetectionView", destination: TruncationDetectionView())
        NavigationLink("AdaptiveAmountList", destination: AdaptiveAmountList())
      }
    }
  }
}

#Preview {
  RootView()
}

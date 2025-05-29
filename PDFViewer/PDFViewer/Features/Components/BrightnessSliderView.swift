//
//  BrightnessSliderView.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 29/5/25.
//

import SwiftUI

struct BrightnessSliderView: View {
    @State private var brightness: Double = 50  // Default value in 10...100 range

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Set Brightness")
                .font(.headline)

            HStack {
                ZStack(alignment: .bottom) {
                    Image(systemName: "sun.max")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)

                    Image(systemName: "sun.max.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.yellow)
                        .mask(
                            Rectangle()
                                .frame(height: CGFloat((brightness - 10) / 90) * 30)
                                .offset(y: (1 - CGFloat((brightness - 10) / 90)) * 15)
                        )
                }

                Slider(value: $brightness, in: 10...100, step: 1)
                    .accentColor(.yellow)

                Text("\(Int(brightness))%")
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding()
    }
}

#Preview {
    BrightnessSliderView()
}


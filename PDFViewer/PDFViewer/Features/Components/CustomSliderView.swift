//
//  LineWidthSliderView.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 29/5/25.
//


//import SwiftUI


import SwiftUI
import SwiftUI

struct CustomSliderView: View {
    var title: String
    var startValue: CGFloat
    var endValue: CGFloat
    @State var currentValue: CGFloat
    var iconName: String
    var iconColor: UIColor
    var onSliderChange: ((Double) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)

            HStack {
                ZStack(alignment: .bottom) {
                    // Background icon (gray)
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)

                    // Foreground filled icon
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color(iconColor))
                        .mask(
                        Rectangle()
                            .frame(height: CGFloat(getProgress()) * 30)
                            .offset(y: (1 - CGFloat(getProgress())) * 15)
                    )
                }

                Slider(value: Binding(
                    get: { currentValue },
                    set: { newValue in
                        currentValue = newValue
                        onSliderChange?(newValue)
                    }
                ), in: startValue...endValue, step: 1)
                .accentColor(Color(iconColor))

                Text("\(Int(currentValue))")
                    .frame(width: 60, alignment: .trailing)
            }
        }
       // .padding()
    }
    
    func getProgress ()-> CGFloat {
        let progress = max(0, min(1, (endValue != startValue ? (currentValue - startValue) / (endValue - startValue) : 0)))

       return progress
    }
}

struct CustomSliderView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var value: CGFloat = 25

        var body: some View {
            VStack(spacing: 40) {
                CustomSliderView(
                    title: "Line Width",
                    startValue: 2,
                    endValue: 50,
                    currentValue: value,
                    iconName: "line.3.horizontal",
                    iconColor: .blue
                ) { newValue in
                    print("Line width changed to: \(newValue)")
                }

                CustomSliderView(
                    title: "Brightness",
                    startValue: 10,
                    endValue: 100,
                    currentValue: value,
                    iconName: "sun.max.fill",
                    iconColor: .yellow
                ) { newValue in
                    print("Brightness changed to: \(newValue)")
                }
            }
            .padding()
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}



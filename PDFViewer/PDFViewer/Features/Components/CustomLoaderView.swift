//
//  CustomLoaderView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 10/5/25.
//

import SwiftUI

struct CustomLoaderView: View {
    @Binding var isShowing: Bool
    var title: String

    var body: some View {
        Group {
            if isShowing {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        ProgressView()
                        Text(title)
                            .padding(.top, 8)
                            .foregroundColor(.gray)
                    }
                    
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.white.opacity(1.0))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding(20)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

struct CustomLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        CustomLoaderView(isShowing: .constant(true), title: "Preparing data...")
    }
}

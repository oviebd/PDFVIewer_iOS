//
//  Controller.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 2/4/25.
//

import PDFKit
import PencilKit
import SwiftUI

struct Controller: View {
//    @State private var selectedColor: Color = .black
//    @State private var isExpanded = false
//    @State private var showColorPalette = false
    @StateObject var vm = ControllerVM()
   
    var body: some View {
        
        ZStack {
            VStack {
               
                HStack {
                    // Main Expand Button
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                           
                            Circle()
                                .fill(Color.black)
                                .frame(width: 25, height: 25)
                        
                                .overlay(Image(systemName: "pencil.tip")
                                    .font(.system(size: 18))
                                    .rotationEffect(.init(degrees: -120))
                                    .foregroundColor(.white))
                       
                    }

                    if isExpanded {
                        HStack(spacing: 10) {
                            Button(action: {
                                withAnimation(.spring()) {
                                                           showColorPalette.toggle()
                                                       }

                            }) {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 25, height: 25)
                                
                                    .overlay(Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white))
                                       
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                .background(Rectangle().fill(Color.purple))
                .cornerRadius(5)

                Spacer()
                
                if showColorPalette {
                                ColorPaletteView(selectedColor: $selectedColor, showPalette: $showColorPalette)
                                    .transition(.scale.combined(with: .opacity))
                            }
            }
        }
    }
   
}


struct ColorPaletteView: View {
    @Binding var selectedColor: Color
    @Binding var showPalette: Bool

    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink, .black, .gray]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Color")
                .font(.headline)
                .padding(.top)

            HStack {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        withAnimation {
                            showPalette = false
                        }
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .shadow(radius: 2)
                    }
                }
            }
            .padding()
            
            Button(action: {
                          withAnimation {
                              showPalette = false
                          }
                      }) {
                          Text("Close")
                              .foregroundColor(.white)
                              .padding(.horizontal, 20)
                              .padding(.vertical, 10)
                              .background(Color.gray)
                              .cornerRadius(10)
                      }
                      .padding(.bottom)
                  }
                  .padding()
                  .background(.ultraThinMaterial)
                  .cornerRadius(20)
                  .shadow(radius: 10)
                  .padding()
              }
          }

#Preview {
    Controller()
}

//struct DrawingCanvas: UIViewRepresentable {
//    @Binding var canvasView: PKCanvasView
//    @Binding var selectedColor: Color
//
//    func makeUIView(context: Context) -> PKCanvasView {
//        canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: 5)
//        canvasView.isOpaque = false
//        canvasView.backgroundColor = .clear
//        canvasView.drawingPolicy = .anyInput
//        return canvasView
//    }
//
//    func updateUIView(_ uiView: PKCanvasView, context: Context) {
//        uiView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: 5)
//    }
//}


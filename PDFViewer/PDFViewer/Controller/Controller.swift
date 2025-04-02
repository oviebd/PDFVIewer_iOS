//
//  Controller.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 2/4/25.
//

import SwiftUI
import PDFKit
import PencilKit

struct Controller: View {
    
    @State private var selectedColor: Color = .black
    @State private var canvasView = PKCanvasView()
    
    @State private var isExpanded = false
    
    var body: some View {
        
        //                ZStack {
        //                           // PDFKitView()
        //                    PDFColorView()
        //                            // Overlay PencilKit Drawing Canvas
        //                            DrawingCanvas(canvasView: $canvasView, selectedColor: $selectedColor)
        //                                .edgesIgnoringSafeArea(.all)
        //
        //                            // Toolbar for Selecting Color
        //                          VStack {
        //                                //Spacer()
        //                                HStack {
        //                                    ColorPicker("Pick a Color", selection: $selectedColor)
        //                                        .frame(width: 150)
        //                                        .padding()
        //                                        .background(Color.white.opacity(0.8))
        //                                        .cornerRadius(10)
        //
        //        //                            Button(action: {
        //        //                                canvasView.drawing = PKDrawing()
        //        //                            }) {
        //        //                                Text("Clear")
        //        //                                    .padding()
        //        //                                    .background(Color.red.opacity(0.8))
        //        //                                    .foregroundColor(.white)
        //        //                                    .cornerRadius(10)
        //        //                            }
        //                                }
        //                                .padding()
        //                                Spacer()
        //                            }
        //                        }
        //                    }
        //                }
        //
        //
        
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
                                   
                                    .rotationEffect(.init(degrees: -120))
                                    .foregroundColor(.white)
                                    .font(.title))
                                .shadow(radius: 5)
                        }
                        
                    if isExpanded {
                        HStack(spacing: 10) {
                            Button(action: {
                                                           // print("Symbol 1 clicked")
//                            selectedColor
                            
                            
                                    
                                }) {
                                    Circle()
                                        .fill(selectedColor)
                                        .frame(width: 30, height: 30)
                                        .overlay(Image(systemName: "paintpalette.fill")
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
                }
            }
        }
    }


#Preview {
    Controller()
}



struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var selectedColor: Color
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: 5)
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: 5)
    }
}

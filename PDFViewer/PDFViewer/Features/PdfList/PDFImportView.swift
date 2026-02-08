//
//  PDFImportView.swift
//  PDFViewer
//
//  Created by Antigravity on 8/2/26.
//

import SwiftUI

struct PDFImportView: View {
    @StateObject var viewModel: PDFImportViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isImporting {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.blue.opacity(0.1), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                        
                        VStack(spacing: 4) {
                            Text(viewModel.currentlyImportingItem?.fileName ?? "Importing PDFs...")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("\(viewModel.successCount) of \(viewModel.totalCount) completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
                } else if viewModel.isCompleted {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 4) {
                            Text("Import Complete")
                                .font(.title2.bold())
                            
                            Text("Successfully imported \(viewModel.successCount) out of \(viewModel.totalCount) files")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
                } else if viewModel.isCancelled {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 4) {
                            Text("Import Cancelled")
                                .font(.title2.bold())
                            
                            Text("Import stopped after \(viewModel.successCount) files")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
                }
                
                Divider()
                
                List(viewModel.importItems) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.fileName)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            if case let .failed(error) = item.status {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if item.status == .duplicate {
                                Text("Already in Library")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if item.status == .pending {
                                Text("Waiting...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if item.status == .success {
                                Text("Success")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        if item.status == .importing {
                            ProgressView()
                        } else {
                            Image(systemName: item.status.iconName)
                                .foregroundColor(item.status.iconColor)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }
            .navigationTitle("PDF Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isImporting {
                        Button("Cancel") {
                            viewModel.cancelImport()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isCompleted || viewModel.isCancelled {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.bold)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .onAppear {
                viewModel.startImport()
            }
        }
    }
}

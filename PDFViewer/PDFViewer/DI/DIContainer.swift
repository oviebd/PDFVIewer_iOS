
import Foundation

class DIContainer: ObservableObject {
    // MARK: - Data Layer
    lazy var pdfLocalDataStore: PDFLocalDataStore = {
        do {
            return try PDFLocalDataStore()
        } catch {
            fatalError("Failed to create PDFLocalDataStore: \(error)")
        }
    }()

    lazy var pdfRepository: PDFRepositoryProtocol = {
        PDFLocalRepositoryImpl(store: pdfLocalDataStore)
    }()

    // MARK: - ViewModels
    func makePDFListViewModel() -> PDFListViewModel {
        PDFListViewModel(repository: pdfRepository)
    }

    func makePDFViewerViewModel(pdfFile: PDFModelData) -> PDFViewerViewModel {
        PDFViewerViewModel(pdfFile: pdfFile, repository: pdfRepository)
    }
}

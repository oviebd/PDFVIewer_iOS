# PDF Viewer for iOS

This is a feature-rich, high-performance, simple PDF viewer application for iOS, designed with a modern architecture and a focus on user experience, scalability, and testability. It serves as an excellent showcase of advanced iOS development techniques and best practices.


## 🚀 Key Features

*   **High-Fidelity PDF Rendering:** Utilizes Apple's native `PDFKit` for a smooth and accurate viewing experience.
*   **Advanced Drawing & Annotation:**
    *   Draw directly on PDF documents with various tools.
    *   Save and manage annotations efficiently.
    *   View a list of all annotations for easy navigation.
*   **Comprehensive File Management:**
    *   Browse and manage a local library of PDF files.
    *   Import new PDFs from the device.
*   **Customizable Viewer Settings:**
    *   Adjust screen brightness for comfortable reading.
    *   Multiple reading modes.
*   **Modern & Intuitive UI:**
    *   Built with SwiftUI for a declarative and responsive user interface.
    *   Custom UI components for a unique and polished look.
 

<p align="center">
<img src="https://github.com/oviebd/PDFVIewer_iOS/blob/main/Demo/annotation_setting.PNG" width="200"/>
<img src="https://github.com/oviebd/PDFVIewer_iOS/blob/main/Demo/annotation_with_seipa .PNG" width="200"/>
   <img src="https://github.com/oviebd/PDFVIewer_iOS/blob/main/Demo/readingMode.PNG" width="200"/>
<img src="https://github.com/oviebd/PDFVIewer_iOS/blob/main/Demo/sorting_menu.PNG" width="200"/>
</p>

  

## 🏗️ Architecture & Design

This project is built upon a solid architectural foundation, ensuring it is both scalable and maintainable.

*   **MVVM (Model-View-ViewModel):** The app employs the MVVM design pattern to create a clean separation of concerns between the UI (View), business logic (ViewModel), and data (Model).
*   **Repository Pattern:** A `PDFRepository` abstracts the data layer, decoupling the ViewModels from the underlying data source (Core Data). This makes the app more modular and easier to test.
*   **Feature-Based Grouping:** The codebase is organized by features (e.g., `PdfList`, `Viewer`), which makes the project easy to navigate and allows for independent feature development.
*   **SwiftUI with UIKit Integration:** While the primary UI framework is SwiftUI, the app intelligently wraps `PDFKit` (a UIKit component) using `UIViewRepresentable`. This demonstrates the ability to leverage the best of both frameworks.
*   **Core Data:** Core Data is used for robust and efficient local persistence of PDF metadata and annotations.

## ✅ Testability

The project is committed to quality and reliability, with a comprehensive testing suite:

*   **Unit Tests:** The `PDFViewerTests` target contains extensive unit tests for ViewModels and data-layer components, ensuring the business logic is correct and bug-free.
*   **Memory Leak Detection:** Custom extensions are in place to check for memory leaks in tests, ensuring the app is memory-efficient.

##  scalability

The application is designed with scalability in mind:

*   **Modular Codebase:** The feature-based grouping and decoupled architecture make it easy to add new features without impacting existing ones.
*   **Extensible Components:** The use of reusable SwiftUI views and a clear component hierarchy allows for easy extension and customization.
*   **SOLID Principles:** The codebase adheres to SOLID principles, making it more robust and easier to understand and maintain over time.

## Contact

For any inquiries, please [`contact me in LinkedIn`](http://www.linkedin.com/in/habibur-rahman-32547b109)

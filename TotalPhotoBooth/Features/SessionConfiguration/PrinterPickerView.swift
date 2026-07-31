import SwiftUI
import UIKit

struct PrinterPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onSelect: (UIPrinter) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, !context.coordinator.isPresenting else { return }
        context.coordinator.isPresenting = true

        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        context.coordinator.picker = picker

        picker.present(from: uiViewController.view.bounds, in: uiViewController.view, animated: true) { picker, userDidSelect, _ in
            Task { @MainActor in
                context.coordinator.isPresenting = false
                context.coordinator.picker = nil
                isPresented = false
                if userDidSelect, let printer = picker.selectedPrinter {
                    onSelect(printer)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var picker: UIPrinterPickerController?
        var isPresenting = false
    }
}

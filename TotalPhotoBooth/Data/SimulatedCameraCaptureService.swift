import UIKit

struct SimulatedCameraCaptureService: CameraCaptureServiceProtocol {
    func startHardwareSession() async throws {}

    func endHardwareSession() {}

    func capturePhoto() async throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    func makePreviewView() -> UIView {
        let view = UIView()
        view.backgroundColor = .darkGray

        let imageView = UIImageView(image: UIImage(systemName: "video.slash"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64)
        ])

        return view
    }
}

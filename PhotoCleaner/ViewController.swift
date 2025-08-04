
import UIKit
import Photos

class ViewController: UIViewController {
    
    var imageView: UIImageView!
    var photos: [PHAsset] = []
    var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupImageView()
        requestPhotoAccess()
    }

    func setupImageView() {
        imageView = UIImageView(frame: CGRect(x: 20, y: 100, width: view.frame.width - 40, height: view.frame.height - 200))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        imageView.addGestureRecognizer(panGesture)
    }

    func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.fetchPhotos()
            } else {
                DispatchQueue.main.async {
                    self.showAccessDenied()
                }
            }
        }
    }

    func showAccessDenied() {
        let alert = UIAlertController(title: "Brak dostępu", message: "Daj aplikacji dostęp do zdjęć w Ustawieniach.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        assets.enumerateObjects { (asset, _, _) in
            self.photos.append(asset)
        }
        
        DispatchQueue.main.async {
            self.showPhoto(at: self.currentIndex)
        }
    }

    func showPhoto(at index: Int) {
        guard index < photos.count else {
            self.imageView.image = nil
            return
        }
        let manager = PHImageManager.default()
        manager.requestImage(for: photos[index], targetSize: imageView.bounds.size, contentMode: .aspectFit, options: nil) { image, _ in
            self.imageView.image = image
            self.imageView.transform = .identity
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let percent = translation.x / view.frame.width
        imageView.transform = CGAffineTransform(translationX: translation.x, y: 0).rotated(by: percent * 0.3)

        if gesture.state == .ended {
            if translation.x < -100 {
                // Swipe left – DELETE
                deleteCurrentPhoto()
            } else if translation.x > 100 {
                // Swipe right – KEEP
                nextPhoto()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.imageView.transform = .identity
                }
            }
        }
    }

    func deleteCurrentPhoto() {
        guard currentIndex < photos.count else { return }
        let assetToDelete = photos[currentIndex]
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([assetToDelete] as NSArray)
        }) { success, error in
            if success {
                print("Usunięto zdjęcie")
                DispatchQueue.main.async {
                    self.photos.remove(at: self.currentIndex)
                    self.showPhoto(at: self.currentIndex)
                }
            } else {
                print("Błąd przy usuwaniu: \(String(describing: error))")
            }
        }
    }

    func nextPhoto() {
        currentIndex += 1
        showPhoto(at: currentIndex)
    }
}

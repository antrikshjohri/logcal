//
//  ImagePickerView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = max(1, Constants.Images.maxMealImages - selectedImages.count)
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else {
                print("DEBUG: [ImagePicker] No images selected")
                return
            }

            let remainingSlots = max(0, Constants.Images.maxMealImages - parent.selectedImages.count)
            guard remainingSlots > 0 else {
                print("DEBUG: [ImagePicker] Image limit already reached")
                return
            }

            var loadedImages: [UIImage] = []
            let loadedImagesLock = NSLock()
            let group = DispatchGroup()

            for result in results.prefix(remainingSlots) where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    if let error = error {
                        print("DEBUG: [ImagePicker] Error loading image: \(error.localizedDescription)")
                        return
                    }

                    if let image = object as? UIImage {
                        print("DEBUG: [ImagePicker] Image selected: \(image.size)")
                        let resizedImage = ImageUtils.resizeImage(image, maxWidth: 2048, maxHeight: 2048)
                        loadedImagesLock.lock()
                        loadedImages.append(resizedImage)
                        loadedImagesLock.unlock()
                    }
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self, !loadedImages.isEmpty else { return }
                loadedImagesLock.lock()
                let images = loadedImages
                loadedImagesLock.unlock()
                let nextImages = (self.parent.selectedImages + images).prefix(Constants.Images.maxMealImages)
                self.parent.selectedImages = Array(nextImages)
            }
        }
    }
}

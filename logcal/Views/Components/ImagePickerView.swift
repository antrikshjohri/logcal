//
//  ImagePickerView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
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
            
            guard let result = results.first else {
                print("DEBUG: [ImagePicker] No image selected")
                return
            }
            
            // Load the image
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("DEBUG: [ImagePicker] Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        if let image = object as? UIImage {
                            print("DEBUG: [ImagePicker] Image selected: \(image.size)")
                            // Resize image to reasonable size before storing
                            let resizedImage = ImageUtils.resizeImage(image, maxWidth: 2048, maxHeight: 2048)
                            self?.parent.selectedImage = resizedImage
                        }
                    }
                }
            }
        }
    }
}

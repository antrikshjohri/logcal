//
//  ImageUtils.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import UIKit

struct ImageUtils {
    /// Convert UIImage to base64 string for API transmission
    /// - Parameters:
    ///   - image: The image to convert
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Base64 encoded string with data URI prefix, or nil if conversion fails
    static func convertToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        print("DEBUG: [ImageUtils] Converting image to base64, original size: \(image.size)")
        
        // Compress image first to reduce payload size
        guard let compressedImage = compressImage(image, maxSizeKB: 1024) else {
            print("DEBUG: [ImageUtils] Failed to compress image")
            return nil
        }
        
        // Convert to JPEG data
        guard let imageData = compressedImage.jpegData(compressionQuality: compressionQuality) else {
            print("DEBUG: [ImageUtils] Failed to convert image to JPEG data")
            return nil
        }
        
        print("DEBUG: [ImageUtils] Image compressed to \(imageData.count / 1024) KB")
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        
        // Return with data URI prefix for OpenAI Vision API
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    /// Compress image to target maximum size in KB
    /// - Parameters:
    ///   - image: The image to compress
    ///   - maxSizeKB: Maximum size in kilobytes (default: 1024 KB = 1 MB)
    /// - Returns: Compressed UIImage, or original if already small enough
    static func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> UIImage? {
        let maxSizeBytes = maxSizeKB * 1024
        
        // Check current size
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return image
        }
        
        // If already small enough, return original
        if imageData.count <= maxSizeBytes {
            print("DEBUG: [ImageUtils] Image already small enough: \(imageData.count / 1024) KB")
            return image
        }
        
        print("DEBUG: [ImageUtils] Compressing image from \(imageData.count / 1024) KB to target \(maxSizeKB) KB")
        
        // Binary search for optimal compression quality
        var minQuality: CGFloat = 0.0
        var maxQuality: CGFloat = 1.0
        var bestImage: UIImage = image
        var bestSize = imageData.count
        
        // Try up to 10 iterations
        for _ in 0..<10 {
            let quality = (minQuality + maxQuality) / 2.0
            
            guard let compressedData = image.jpegData(compressionQuality: quality),
                  let compressedImage = UIImage(data: compressedData) else {
                maxQuality = quality
                continue
            }
            
            let size = compressedData.count
            
            if size <= maxSizeBytes {
                bestImage = compressedImage
                bestSize = size
                minQuality = quality
                
                // If we're within 5% of target, good enough
                if size >= Int(Double(maxSizeBytes) * 0.95) {
                    break
                }
            } else {
                maxQuality = quality
            }
        }
        
        print("DEBUG: [ImageUtils] Compression complete: \(bestSize / 1024) KB")
        return bestImage
    }
    
    /// Resize image to maximum dimensions while maintaining aspect ratio
    /// - Parameters:
    ///   - image: The image to resize
    ///   - maxWidth: Maximum width in points
    ///   - maxHeight: Maximum height in points
    /// - Returns: Resized UIImage
    static func resizeImage(_ image: UIImage, maxWidth: CGFloat = 1024, maxHeight: CGFloat = 1024) -> UIImage {
        let size = image.size
        
        // If already smaller than max dimensions, return original
        if size.width <= maxWidth && size.height <= maxHeight {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
        } else {
            newSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

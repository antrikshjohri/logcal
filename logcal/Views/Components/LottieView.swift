//
//  LottieView.swift
//  logcal
//
//  SwiftUI wrapper for Lottie animations
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        
        // Try to load animation from Animations folder first, then main bundle
        var animation: LottieAnimation?
        if let path = Bundle.main.path(forResource: animationName, ofType: "json", inDirectory: "Animations") {
            animation = LottieAnimation.filepath(path)
        } else {
            // Fallback to main bundle
            animation = LottieAnimation.named(animationName)
        }
        
        animationView.animation = animation
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}


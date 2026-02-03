//
//  SafariView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import SafariServices

/// Wrapper for SFSafariViewController to display web content in-app
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .systemBlue
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

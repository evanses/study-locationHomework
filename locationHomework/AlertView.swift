//
//  AlertView.swift
//  locationHomework
//
//  Created by eva on 05.10.2024.
//

import UIKit

final class AlertView {
    static let alert = AlertView()
    
    func show(in viewController: UIViewController, text: String, message: String? = nil) {
        let alert = UIAlertController(
            title: text,
            message: message,
            preferredStyle: .alert
        )
        
        let okButton = UIAlertAction(title: "OK", style: .cancel)
        
        alert.addAction(okButton)
        
        viewController.present(alert, animated: true)
    }
}

//
//  UIImageExtension.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 7/21/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageFromSystemBarButton(_ systemItem: UIBarButtonSystemItem, renderingMode:UIImageRenderingMode = .automatic)-> UIImage {
        
        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        
        // add to toolbar and render it
        UIToolbar().setItems([tempItem], animated: false)
        
        // got image from real uibutton
//        let itemView = tempItem.value(forKey: "view") as! UIView
//
//        for view in itemView.subviews {
//            if view is UIButton {
//                let button = view as! UIButton
//                let image = button.imageView!.image!
//                image.withRenderingMode(renderingMode)
//                return image
//            }
//        }
        
        return UIImage()
    }
}

//
//  CWFMapViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 7/7/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CWFMapViewController: CWFBaseViewController, MKMapViewDelegate {

    let mapView = MKMapView()
    var addressToDisplay : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("Map", comment: "map")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismiss(_:)))

        mapView.mapType = .standard
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        
        self.view.addSubview(mapView)
        
        let xConstraint = NSLayoutConstraint(item: mapView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: mapView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([xConstraint, yConstraint, hConstraint, wConstraint])
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss(_ sender:UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }


}

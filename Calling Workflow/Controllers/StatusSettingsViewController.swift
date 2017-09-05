//
//  StatusSettingsViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 8/14/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class StatusSettingsViewController: CWFBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, StatusSettingsCollectionViewCellDelegate {
    
    let headerView : UIView = UIView()
    let collectionView : UICollectionView = UICollectionView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: UICollectionViewFlowLayout())
    
    var unsavedStatusToExclude: [CallingStatus] = []
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .plain, target: self, action: #selector(saveButtonPressed))
        self.navigationItem.rightBarButtonItem = saveButton

        self.collectionView.register(StatusSettingsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.estimatedItemSize = CGSize(width: 100, height: 40)
        self.collectionView.collectionViewLayout = collectionLayout
        setupHeaderView()
        setupCollectionView()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            unsavedStatusToExclude = appDelegate.callingManager.statusToExcludeForUnit
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Setup
    
    func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(headerView)
        
        let xConstraint = NSLayoutConstraint(item: headerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: headerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: headerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 60)
        
        self.view.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
        
        let headerLabel = UILabel()
        headerLabel.text = NSLocalizedString("Select statuses to include", comment: "")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(headerLabel)
        
        let headerXConstraint = NSLayoutConstraint(item: headerLabel, attribute: .leading, relatedBy: .equal, toItem: headerView, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let headerYConstraint = NSLayoutConstraint(item: headerLabel, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .top, multiplier: 1, constant: 0)
        let headerWConstraint = NSLayoutConstraint(item: headerLabel, attribute: .trailing, relatedBy: .equal, toItem: headerView, attribute: .trailing, multiplier: 1, constant: -CWFMarginFloat())
        let headerHConstraint = NSLayoutConstraint(item: headerLabel, attribute: .bottom, relatedBy: .equal, toItem: headerView, attribute: .bottom, multiplier: 1, constant: 0)
        
        headerView.addConstraints([headerXConstraint, headerYConstraint, headerWConstraint, headerHConstraint])
        
    }
    
    func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = self.view.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.addSubview(collectionView)
        
        let xConstraint = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let yConstraint = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -CWFMarginFloat())
        let hConstraint = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .bottom, multiplier: 1, constant: 0)
        
        view.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
        
    }
    
    //MARK: - CollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CallingStatus.userValues.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? StatusSettingsCollectionViewCell
        collectionCell?.translatesAutoresizingMaskIntoConstraints = false
        collectionCell?.button.setupForSelected()
        collectionCell?.button.setTitle(CallingStatus.userValues[indexPath.row].description, for: .normal)
        collectionCell?.callingStatus = CallingStatus.userValues[indexPath.row]
        collectionCell?.delegate = self
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if appDelegate.callingManager.statusToExcludeForUnit.contains(item: CallingStatus.userValues[indexPath.row]) {
                collectionCell?.button.setupForUnselected()
            }
        }
        
        return collectionCell!
    }
    


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = self.collectionView.cellForItem(at: indexPath) as? StatusSettingsCollectionViewCell {
            cell.buttonSelected(sender: cell.button)
        }
    }
    
    func updateStatusSettings(status: CallingStatus) {
        if !unsavedStatusToExclude.contains(item: status) {
            unsavedStatusToExclude.append(status)
        }
    }
    
    //MARK: - Save Button Action
    
    func saveButtonPressed() {
        for cell in collectionView.visibleCells {
            if let statusCell = cell as? StatusSettingsCollectionViewCell, let callingStatus = statusCell.callingStatus {
                if !statusCell.button.isSelected {
                    if !unsavedStatusToExclude.contains(item: callingStatus) {
                        unsavedStatusToExclude.append(callingStatus)
                    }
                }
                else {
                    unsavedStatusToExclude = unsavedStatusToExclude.filter() { $0 != callingStatus }
                }
            }
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.callingManager.statusToExcludeForUnit = unsavedStatusToExclude
        }
        self.navigationController?.popViewController(animated: true)
    }
}

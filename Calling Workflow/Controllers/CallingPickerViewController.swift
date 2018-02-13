//
//  CallingPickerViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 7/10/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingPickerViewController: CWFBaseTableViewController {
    
    var org : Org? = nil

    var callingsToDisplay : [Position] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var delegate : CallingPickerTableViewControllerDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Callings", comment: "callings")

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Do any additional setup after loading the view.
        setupCallings()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Setup
    
    func setupCallings() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        if let orgCallings = org?.potentialNewPositions {
            var tmpNewPositions : [Position] = []
            for position in orgCallings {
                if position.metadata.positionTypeId == -1 {
                    let positionMD = appDelegate?.callingManager.positionMetadataMap[position.positionTypeId] ?? PositionMetadata()
                    var tmpPosition = position
                    tmpPosition.metadata = positionMD
                    tmpNewPositions.append(tmpPosition)
                }
                else {
                    tmpNewPositions.append(position)
                }
            }

            callingsToDisplay = tmpNewPositions
        }
    }
    

    //MARK: - Table View Delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if callingsToDisplay.count > 0 {
            return callingsToDisplay.count
        }
        else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if callingsToDisplay.count > 0 {
            cell.textLabel?.text = callingsToDisplay[indexPath.row].metadata.mediumName
        }
        else {
            cell.textLabel?.text = NSLocalizedString("No available callings to add", comment: "no callings")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.setReturnedPostiton(position: callingsToDisplay[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }
}

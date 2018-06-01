//
//  CallingPickerViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 7/10/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingPickerViewController: CWFBaseTableViewController, CallingPickerCustomCellDelegate {
    
    var org : Org? = nil

    var positionsToDisplay : [Position] = [] {
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
        tableView.register(CallingPickerCustomTableViewCell.self, forCellReuseIdentifier: "customCell")

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

            positionsToDisplay = tmpNewPositions
        }
    }
    

    //MARK: - Table View Delegates
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if positionsToDisplay.count > 0 {
            //we want the number of callings plus a custom calling cell
            return positionsToDisplay.count + 1
        }
        else {
            // This will be the custom calling cell
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if positionsToDisplay.count > 0 && indexPath.row < positionsToDisplay.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = positionsToDisplay[indexPath.row].mediumName
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? CallingPickerCustomTableViewCell
            cell?.delegate = self
            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (positionsToDisplay.count > 0 && indexPath.row < positionsToDisplay.count) {
            self.delegate?.setReturnedPostiton(position: positionsToDisplay[indexPath.row])
            self.navigationController?.popViewController(animated: true)
        }
        else {
            print("custom calling pressed")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setCustomTitle(titleString: String) {
        let position = Position(customPosition: titleString, inUnitNum: org?.unitNum)
        self.delegate?.setReturnedPostiton(position: position)
        self.navigationController?.popViewController(animated: true)
    }
}

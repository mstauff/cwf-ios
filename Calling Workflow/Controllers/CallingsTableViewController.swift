 //
//  CallingsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class CallingsTableViewController: CWFBaseTableViewController {
    
    var callingsToDisplay : [Calling] = []
    
    var delegate : CallingsTableViewControllerDelegate? = nil
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallingsToDisplay()
        self.title = "Callings"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup
    
    func setupCallingsToDisplay() {
        if delegate == nil {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if (appDelegate?.callingManager.ldsOrgUnit != nil) {
                callingsToDisplay = (appDelegate?.callingManager.ldsOrgUnit?.allOrgCallings)!
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return callingsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NameCallingProposedTableViewCell
        
        let callingForRow = callingsToDisplay[indexPath.row]
        
        cell?.nameLabel.text = callingForRow.position.name
        if callingForRow.existingIndId != nil {
            let currentyCalled = appDelegate?.callingManager.getMemberWithId(memberId: callingForRow.existingIndId!)
            cell?.currentCallingLabel.text = currentyCalled?.name
        }
        else {
            cell?.currentCallingLabel.text = ""
        }
        
        if callingForRow.proposedStatus != CallingStatus.Unknown {
            cell?.callingInProcessLabel.text = callingForRow.proposedStatus.description
        }
        else {
            cell?.callingInProcessLabel.text = ""
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if delegate == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let nextVc = storyboard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
            
            nextVc?.callingToDisplay = callingsToDisplay[indexPath.row]
            
            navigationController?.pushViewController(nextVc!, animated: true)
        }
        else {
            self.delegate?.setReturnedCalling(calling: callingsToDisplay[indexPath.row])
            self.navigationController?.popViewController(animated: true)
        }
    }
}

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

    var callingsToDisplay : [Calling] = [] {
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
        if var orgCallings = org?.allOrgCallings {
            orgCallings = orgCallings.filter() {
                return ($0.position.hidden || $0.position.multiplesAllowed)
            }
            callingsToDisplay = orgCallings
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
            cell.textLabel?.text = callingsToDisplay[indexPath.row].position.name
        }
        else {
            cell.textLabel?.text = NSLocalizedString("No available callings to add", comment: "no callings")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.setReturnedCalling(calling: callingsToDisplay[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }
}

//
//  MemberPickerTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberPickerTableViewController: UITableViewController {
    
    var delegate: MemberPickerDelegate?

    var members : [Member] = []
    var memberDetailView: MemberInfoView?
    
    var selectedMember : Member?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonPressed))

        tableView.register(TitleAdjustableSubtitleTableViewCell.self, forCellReuseIdentifier: "cell")
        
        //todo - Remove this. it is only here to assign a calling to a member so we can test the view
        if (members.count > 4) {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            members[1].currentCallings = (appDelegate?.callingManager.getCallingsForMember(member: members[1]))!
            members[3].currentCallings = (appDelegate?.callingManager.getCallingsForMember(member: members[3]))!


        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return members.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TitleAdjustableSubtitleTableViewCell.getHeightForCellForMember(member: members[indexPath.row])
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TitleAdjustableSubtitleTableViewCell
        let currentMember = members[indexPath.row]
        cell?.infoButton.addTarget(self, action: #selector(showMemberDetails(_:)), for: .touchUpInside)
        cell?.infoButton.tag = indexPath.row

        cell?.setupCell(subtitleCount: currentMember.currentCallings.count)
        cell?.titleLabel.text = members[indexPath.row].name
        if currentMember.currentCallings.count > 0 {
            for i in 0...currentMember.currentCallings.count-1 {
                cell?.leftSubtitles[i].text = currentMember.currentCallings[i].position.name
                cell?.rightSubtitles[i].text = "\(currentMember.currentCallings[i].existingMonthsInCalling) Months"
            }
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMember = members[indexPath.row]
    }

    // MARK: - Done Button Methods
    func doneButtonPressed() {
        if selectedMember != nil {
            delegate?.setProspectiveMember(member: selectedMember!)
        }
        self.navigationController?.popViewController(animated: true)
    }

    func showMemberDetails(_ sender: UIButton) {
        memberDetailView = MemberInfoView()
        print(sender.tag)
        if (memberDetailView != nil) {
            memberDetailView?.setupView(member: members[sender.tag])
            self.view.addSubview(memberDetailView!)
            //self.tableView.isUserInteractionEnabled = false
            
            
            let constraintWidth = NSLayoutConstraint(item: memberDetailView!, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            let constraintHeight = NSLayoutConstraint(item: memberDetailView!, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 1, constant: 0)
            let constraintV = NSLayoutConstraint(item: memberDetailView!, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            self.view.addConstraints([constraintWidth, constraintHeight])
        }
    }

}

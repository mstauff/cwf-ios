//
//  MemberPickerTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberPickerTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var delegate: MemberPickerDelegate?

    var members : [Member] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: UIBarButtonItemStyle.done, target: self, action: #selector(filterButtonPressed))

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
         memberSelected(selectedMember: members[indexPath.row])
    }
    
    // Mark: - UIPopoverPresentationControllerDelegate
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.permittedArrowDirections = .any
        popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return (traitCollection.horizontalSizeClass == .compact) ? .popover : .none
    }
    
    // MARK: - Button Methods
    func memberSelected(selectedMember: Member?) {
        if selectedMember != nil {
            delegate?.setProspectiveMember(member: selectedMember!)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func filterButtonPressed(sender : UIView){
        let mainBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let popoverContentController = mainBoard.instantiateViewController(withIdentifier: "PopoverViewController")
        popoverContentController.popoverPresentationController?.delegate = self
        popoverContentController.popoverPresentationController?.sourceView = sender
        popoverContentController.popoverPresentationController?.sourceRect = sender.bounds
        popoverContentController.view.backgroundColor = UIColor.blue
        
        
        // Set the presentation style to modal so that the above methods get called.
        popoverContentController.modalPresentationStyle = UIModalPresentationStyle.popover
        
        
        // Present the popover.
        self.present(popoverContentController, animated: true, completion: nil)
        
        
        
    }

    func showMemberDetails(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = members[sender.tag]
        memberDetailView?.modalPresentationStyle = .overCurrentContext

        self.present(memberDetailView!, animated: true, completion: nil)        
    }
}

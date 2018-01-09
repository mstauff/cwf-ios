//
//  ControllerProtocols.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

protocol MemberPickerDelegate {
    func setProspectiveMember(member: Member?)
}

protocol StatusPickerDelegate {
    func setStatusFromPicker(status: CallingStatus)
}

protocol LDSLoginDelegate {
    func setLoginDictionary(returnedLoginDictionary: Dictionary<String, Any>)
}

protocol CallingsTableViewControllerDelegate {
    func setReturnedCalling(calling: Calling)
    func setNewCalling(calling: Calling)
    func setDeletedCalling(calling: Calling)
}

protocol CallingPickerTableViewControllerDelegate {
    func setReturnedPostiton(position: Position)
}

protocol FilterTableViewCellDelegate {
    func updateFilterOptionsForFilterView()
}

protocol FilterTableViewControllerDelegate {
    func setFilterOptions(memberFilterOptions: FilterOptions)
}

protocol StatusSettingsCollectionViewCellDelegate {
    func updateStatusSettings(status: CallingStatus)
}

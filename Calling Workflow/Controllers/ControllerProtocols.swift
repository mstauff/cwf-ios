//
//  ControllerProtocols.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

protocol MemberPickerDelegate {
    func setProspectiveMember(member: Member)
}

protocol StatusPickerDelegate {
    func setStatusFromPicker(status: CallingStatus)
}
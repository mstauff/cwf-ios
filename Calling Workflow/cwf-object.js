{
    "member": {
        "individualId": 123,
        "formattedName": "Adams, Steve",
        "individualPhone": "555-433-2222",
        "householdPhone": "555-433-1111",
        "email": "steve@adams.com",
    },
    "statuses": [{
            "name": "CONSIDERING",
            "active": true,
            "priority": 10
        }, {
            "name": "PROPOSED",
            "active": true,
            "priority": 20
        }, {
            "name": "APPROVED",
            "active": true,
            "priority": 30
        }, {
            "name": "REJECTED",
            "active": true,
            "priority": 40
        }, {
            "name": "APPT_SET",
            "active": true,
            "priority": 50
        }, {
            "name": "ACCEPTED",
            "active": true,
            "priority": 60
        }, {
            "name": "DECLINED",
            "active": true,
            "priority": 70
        }, {
            "name": "SUSTAINED",
            "active": true,
            "priority": 80
        }, {
            "name": "SET_APART",
            "active": true,
            "priority": 90
        }, {
            "name": "CURRENT_HOLDER_NOTIFIED",
            "active": true,
            "priority": 100
        }, {
            "name": "RELEASED",
            "active": true,
            "priority": 110
        }
    ],
    "org": {
        "orgTypeId": 25,
        "orgName": "Primary",
        "id": 7428354,
        "subOrgs": [{
                "orgTypeId": 35,
                "orgName": "CTR 7",
                "id": 38432972,
                "subOrgs": [],
                "positions": [{
                        "currentIndId": 123,
                        "proposedIndId": 456,
                        "position": {
                            "positionId": 734829,
                            "positionTypeId": 1481,
                            "positionName" : "PRIMARY_WORKER_CTR_7",
                            "name": "Primary Teacher",
                            "description": "CTR 7",
                            "positionOrgTypeId": 25
                        },
                        "status": "PROPOSED",
                        "notes": "Some String",
                        "editableByOrg": true
                        // something to mark if the owning org can view/edit. Primary Presidency members belong in the Primary, but
                        // the presidency can't recommend changes to them.
                        // isSynced???
                        // syncDate?? - probably need one of these just to make sure it's been pushed to google drive, but maybe not if google drive handles it all for us
                    },
                ]

            }
        ],
        "positions": []
    }
}
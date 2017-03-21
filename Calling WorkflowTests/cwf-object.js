{
    "orgWithCallingsInSubOrg": {
    "orgTypeId": 77,
        "defaultOrgName": "Primary",
        "displayOrder": 700,
        "customOrgName": null,
        "subOrgId": 7428354,
        "children": [
        {
            "displayOrder": 320,
            "orgTypeId": 35,
            "defaultOrgName": "CTR 7",
            "customOrgName": null,
            "subOrgId": 38432972,
            "children": [],
            "callings": [
                {
                    "memberId": 123,
                    "existingStatus": "ACTIVE",
                    "activeDate": null,
                    "positionId": 734829,
                    "positionTypeId": 1481,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_7",
                    "position": "Primary Teacher",
					"allowMultiple": true,
                    "hidden": false,
                    "proposedStatus": "PROPOSED",
                    "proposedIndId": 456,
                    "notes": "Some String",
                    "editableByOrg": true
                },
                {
                    "memberId": 234,
                    "existingStatus": "ACTIVE",
                    "activeDate": "20150922",
                    "positionId": 734820,
                    "positionTypeId": 1481,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_7",
                    "position": "Primary Teacher",
					"allowMultiple": true,
                    "hidden": false,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": null,
                    "editableByOrg": true
                },
                {
                    "memberId": 345,
                    "existingStatus": null,
                    "activeDate": null,
                    "positionId": null,
                    "positionTypeId": null,
                    "positionTypeEnum": "",
                    "position": "An invalid position ID, should result in a nil calling",
                    "hidden": false,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": null,
                    "editableByOrg": true
                }
            ]
        },
        {
            "displayOrder": 350,
            "orgTypeId": 40,
            "defaultOrgName": "CTR 8",
            "customOrgName": null,
            "subOrgId": 752892,
            "children": [],
            "callings": [
                {
                    "memberId": null,
                    "existingStatus": null,
                    "activeDate": null,
                    "positionId": null,
                    "positionTypeId": 1482,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_8",
                    "position": "Primary Teacher",
					"allowMultiple": true,
                    "hidden": false,
                    "proposedStatus": "PROPOSED",
                    "proposedIndId": 567,
                    "notes": "A proposed calling without an existing calling",
                    "editableByOrg": true
                },
                {
                    "memberId": 678,
                    "existingStatus": "ACTIVE",
                    "activeDate": "20150922",
                    "positionId": 728220,
                    "positionTypeId": 1482,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_8",
                    "position": "Primary Teacher",
					"allowMultiple": true,
                    "hidden": false,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": null,
                    "editableByOrg": true
                }
            ]
        },
        {
            "displayOrder": 400,
            "orgTypeId": 41,
            "defaultOrgName": "CTR 9",
            "customOrgName": null,
            "subOrgId": 750112,
            "children": [],
            "callings": [
                {
                    "memberId": 678,
                    "existingStatus": "ACTIVE",
                    "activeDate": null,
                    "positionId": 90239,
                    "positionTypeId": 1483,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_9",
                    "position": "Primary Teacher",
					"allowMultiple": true,
                    "hidden": false,
                    "proposedStatus": "PROPOSED",
                    "proposedIndId": 567,
                    "notes": "multiple callings for one individual",
                    "editableByOrg": true
                }
            ]
        }
    ],
        "callings": []
},
    "orgWithMultiDepthSubOrg": {
    "orgTypeId": 73,
        "defaultOrgName": "Young Men",
        "displayOrder": 1500,
        "customOrgName": null,
        "subOrgId": 839202,
        "children": [
        {
            "displayOrder": 1400,
            "orgTypeId": 739,
            "defaultOrgName": "Boy Scouts",
            "customOrgName": null,
            "subOrgId": 839500,
            "children": [
                {
                    "displayOrder": 1440,
                    "orgTypeId": 1700,
                    "defaultOrgName": "Varsity",
                    "customOrgName": null,
                    "subOrgId": 839510,
                    "children": [],
                    "callings": [
                        {
                            "memberId": 890,
                            "existingStatus": "ACTIVE",
                            "activeDate": null,
                            "positionId": 275893,
                            "positionTypeId": 1459,
                            "positionTypeEnum": "VARSITY_COACH",
                            "position": "Varsity Coach",
							"allowMultiple": false,
                            "hidden": false,
                            "proposedStatus": null,
                            "proposedIndId": null,
                            "notes": "calling two levels deep",
                            "editableByOrg": true
                        }
                    ]
                }
            ],
            "callings": [
                {
                    "memberId": 789,
                    "existingStatus": "ACTIVE",
                    "activeDate": null,
                    "positionId": 14727,
                    "positionTypeId": 165,
                    "positionTypeEnum": "SCOUTMASTER",
                    "position": "Scoutmaster",
					"allowMultiple": false,
                    "hidden": false,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": "Callings & Org at same level of structure",
                    "editableByOrg": true
                }
            ]
        }
    ],
        "callings": []
},
    "orgWithDirectCallings": {
    "notUsed": "Ignore this",
        "orgTypeId": 1179,
        "defaultOrgName": "Bishopric",
        "displayOrder": 100,
        "customOrgName": null,
        "subOrgId": 7428354,
        "children": [],
        "callings": [
        {
            "memberId": 123,
            "existingStatus": "ACTIVE",
            "activeDate": "20150922",
            "positionId": 734829,
            "positionTypeId": 1481,
            "positionTypeEnum": "PRIMARY_WORKER_CTR_7",
            "position": "Primary Teacher",
			"allowMultiple": true,
            "hidden": true,
            "proposedStatus": "PROPOSED",
            "proposedIndId": 456,
            "notes": "Some String",
            "editableByOrg": true
        }
    ]
},
    "invalidOrgs": [
    {
        "orgTypeId": null
    },
    {},
    {
        "subOrgId": null,
        "orgTypeId": 1179
    },
    {
        "subOrgId": 1234
    },
    {
        "subOrgId": 1234,
        "orgTypeId": 1179,
        "orgName": null
    },
    {
        "subOrgId": 1234,
        "orgTypeId": 1179,
        "orgName": "Bishopric",
        "displayOrder": null
    }
]
}

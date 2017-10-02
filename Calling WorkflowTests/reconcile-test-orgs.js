{
    "lcrOrg": [{
    "orgTypeId": 77,
	"unitNumber" : 1111,
        "defaultOrgName": "Primary",
        "displayOrder": 700,
        "customOrgName": null,
        "subOrgId": 7428354,
        "children": [
        {
            "displayOrder": 320,
            "orgTypeId": 35,
			"unitNumber" : 1111,
            "defaultOrgName": "CTR 7",
            "customOrgName": null,
            "subOrgId": 38432972,
            "children": [],
            "callings": [
                {
                    "memberId": 123,
                    "activeDate": null,
                    "positionId": 734829,
                    "positionTypeId": 1481,
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
					"comment": "matches app - no calling change"
                },
                {
                    "memberId": 234,
                    "activeDate": "20150922",
                    "positionId": 734821,
                    "positionTypeId": 1481,
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
					"comment": "changed ID"
                }
            ]
        },
        {
            "displayOrder": 350,
            "orgTypeId": 40,
			"unitNumber" : 1111,
            "defaultOrgName": "CTR 8",
            "customOrgName": null,
            "subOrgId": 752892,
            "children": [],
            "callings": [
                {
                    "memberId": null,
                    "activeDate": null,
                    "positionId": null,
                    "positionTypeId": 1482,
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
					"comment": "They've been released outside the app"
                }
            ]
        },
        {
            "displayOrder": 400,
            "orgTypeId": 41,
			"unitNumber" : 1111,
            "defaultOrgName": "CTR 9",
            "customOrgName": null,
			"comment": "Org that exists in LCR but not app",
            "subOrgId": 750112,
            "children": [],
            "callings": [
                {
                    "memberId": 678,
                    "activeDate": null,
                    "positionId": 90239,
                    "positionTypeId": 1483,
                    "hidden": false,
                    "allowMultiple": true,
                    "notes": "should be added to app data"
                }
            ]
        }
    ],
        "callings": []
},
{
		"orgTypeId": 73,
			"unitNumber" : 1111,
        "defaultOrgName": "Young Men",
        "displayOrder": 1500,
        "customOrgName": null,
        "subOrgId": 839202,
        "children": [
        {
            "displayOrder": 1400,
            "orgTypeId": 739,
			"unitNumber" : 1111,
            "defaultOrgName": "Boy Scouts",
            "customOrgName": null,
            "subOrgId": 839500,
            "children": [
                {
                    "displayOrder": 1440,
                    "orgTypeId": 1700,
			"unitNumber" : 1111,
                    "defaultOrgName": "Varsity",
                    "customOrgName": null,
                    "subOrgId": 839510,
                    "children": [],
                    "callings": [
                        {
                            "memberId": 890,
                            "activeDate": null,
                            "positionId": 275893,
                            "positionTypeId": 1459,
                            "position": "Varsity Coach",
                            "hidden": false,
							"allowMultiple": false,
							"notes": "was finalized outside the app - was just a proposed in app"
                        },
						{
                            "memberId": null,
                            "activeDate": null,
                            "positionId": null,
                            "positionTypeId": 1461,
                            "position": "Asst. Varsity Coach",
                            "hidden": false,
							"allowMultiple": false,
							"notes": "was released outside the app"
                        },
                                 {
                                 "memberId": 895,
                                 "activeDate": null,
                                 "positionId": 275894,
                                 "positionTypeId": 1465,
                                 "position": "Scoutmaster",
                                 "hidden": false,
                                 "allowMultiple": false,
                                 "notes": "Changed ID - no multiples - This is similar to the CTR 7 teacher, but no multiples allowed"
                                 },
                                 {
                                 "memberId": 900,
                                 "activeDate": null,
                                 "positionId": 275900,
                                 "positionTypeId": 1470,
                                 "position": "Explorer Advisor",
                                 "hidden": false,
                                 "allowMultiple": false,
                                 "notes": "Changed ID - no multiples - This is similar to the CTR 7 teacher, but no multiples allowed. Here the proposed doesn't match the actual, so the proposed should be retained"
                                 }


                    ]
                }
            ],
            "callings": [
                {
                    "memberId": 789,
                    "activeDate": null,
                    "positionId": 14727,
                    "positionTypeId": 165,
                    "hidden": false,
                    "allowMultiple": false,
                    "notes": "completely new - added outside app"
                }
            ]
        }
    ],
        "callings": []
}],
 "appOrg" : [ {
    "orgTypeId": 77,
			"unitNumber" : 1111,
        "defaultOrgName": "Primary",
        "displayOrder": 700,
        "customOrgName": null,
        "subOrgId": 7428354,
        "children": [
        {
            "displayOrder": 320,
            "orgTypeId": 35,
			"unitNumber" : 1111,
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
                    "cwfId": null,
                    "positionTypeId": 1481,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_7",
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": "Some String",
                    "editableByOrg": true,
					"comment" : "matches lcr - no calling change"
                },
                {
                    "memberId": 222,
                    "existingStatus": "ACTIVE",
                    "activeDate": "20150922",
                    "positionId": 734820,
                    "cwfId": null,
                    "positionTypeId": 1481,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_7",
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": null,
                    "editableByOrg": true,
					"comment" : "changed ID & changed member ID"
                }
            ]
        },
        {
            "displayOrder": 350,
            "orgTypeId": 40,
			"unitNumber" : 1111,
            "defaultOrgName": "CTR 8",
            "customOrgName": null,
            "subOrgId": 752892,
            "children": [],
            "callings": [
                {
                    "memberId": 678,
                    "existingStatus": "ACTIVE",
                    "activeDate": "20150922",
                    "positionId": 728220,
                    "cwfId": null,
                    "positionTypeId": 1482,
                    "positionTypeEnum": "PRIMARY_WORKER_CTR_8",
                    "position": "Primary Teacher",
                    "hidden": false,
                    "allowMultiple": true,
                    "proposedStatus": null,
                    "proposedIndId": null,
                    "notes": null,
                    "editableByOrg": true,
					"comment" : "released oustide the app"
                },
                         {
                         "memberId": 222,
                         "existingStatus": "ACTIVE",
                         "activeDate": "20150922",
                         "positionId": 728250,
                         "cwfId": null,
                         "positionTypeId": 1482,
                         "positionTypeEnum": "PRIMARY_WORKER_CTR_8",
                         "position": "Primary Teacher",
                         "hidden": false,
                         "allowMultiple": true,
                         "proposedStatus": null,
                         "proposedIndId": null,
                         "notes": null,
                         "editableByOrg": true,
                         "comment" : "deleted oustide the app - calling doesn't exist in lcr"
                         }

            ]
        }
    ],
        "callings": []
},
{
    "orgTypeId": 73,
			"unitNumber" : 1111,
        "defaultOrgName": "Young Men",
        "displayOrder": 1500,
        "customOrgName": null,
        "subOrgId": 839202,
        "children": [
        {
            "displayOrder": 1400,
            "orgTypeId": 739,
			"unitNumber" : 1111,
            "defaultOrgName": "Boy Scouts",
            "customOrgName": null,
            "subOrgId": 839500,
            "children": [
                {
                    "displayOrder": 1440,
                    "orgTypeId": 1700,
			"unitNumber" : 1111,
                    "defaultOrgName": "Varsity",
                    "customOrgName": null,
                    "subOrgId": 839510,
                    "children": [],
                    "callings": [
                        {
                            "memberId": null,
                            "existingStatus": null,
                            "activeDate": null,
                            "positionId": null,
							"cwfId": "278423-384728-237482-2247",
                            "positionTypeId": 1459,
                            "positionTypeEnum": "VARSITY_COACH",
                            "position": "Varsity Coach",
                            "hidden": false,
							"allowMultiple": false,
                            "proposedStatus": "PROPOSED",
                            "proposedIndId": 890,
                            "notes": "calling two levels deep",
                            "editableByOrg": true,
							"comment": "With no active holder, was finalzied outside the app - is actual in LCR, just proposed in app, should result in an actual calling with no proposed"
                        },{
                            "memberId": 950,
                            "activeDate": null,
                            "positionId": 275950,
                            "positionTypeId": 1461,
                            "position": "Asst. Varsity Coach",
                                 "proposedIndId" : 952,
                                 "proposedStatus" : "APPROVED",
                            "hidden": false,
							"allowMultiple": false,
							"notes": "has data in app - was released outside the app"
                        },
                                 {
                                 "memberId": 896,
                                 "activeDate": null,
                                 "positionId": 275895,
                                 "proposedIndId": 895,
                                 "positionTypeId": 1465,
                                 "position": "Scoutmaster",
                                 "hidden": false,
                                 "allowMultiple": false,
                                 "notes": "with active holder, Changed ID - no multiples - This is similar to the CTR 7 teacher, but no multiples allowed. Here the proposed matches the actual, so shouldn't be marked as a conflict"
                                 },
                                 {
                                 "memberId": 885,
                                 "activeDate": null,
                                 "positionId": 275885,
                                 "proposedIndId": 955,
                                 "proposedStatus": "ON_HOLD",
                                 "positionTypeId": 1470,
                                 "position": "Explorer Advisor",
                                 "hidden": false,
                                 "allowMultiple": false,
                                 "notes": "Changed ID - no multiples - This is similar to the CTR 7 teacher, but no multiples allowed. Here the proposed doesn't match the actual, so the proposed should be retained"
                                 }

                                 

                    ]
                }
            ],
            "callings": []
        }
    ],
        "callings": []
}




]
}

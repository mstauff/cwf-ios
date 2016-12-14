{
	"member": {
		"individualId": 123,
		"formattedName": "Adams, Steve",
		"individualPhone": "555-433-2222",
		"householdPhone": "555-433-1111",
		"email": "steve@adams.com"
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
		"name": "RELEASED",
		"active": true,
		"priority": 110
	}],
	"orgWithCallingsInSubOrg": {
		"orgTypeId": 77,
		"defaultOrgName": "Primary",
		"displayOrder": 700,
		"customOrgName": null,
		"subOrgId": 7428354,
		"children": [{
			"displayOrder": 320,
			"orgTypeId": 35,
			"defaultOrgName": "CTR 7",
			"customOrgName": null,
			"subOrgId": 38432972,
			"children": [],
			"callings": [{
				"memberId": 123,
				"positionId": 734829,
				"positionTypeId": 1481,
				"positionTypeEnum": "PRIMARY_WORKER_CTR_7",
				"position": "Primary Teacher",
				"hidden": false,
				"status": "PROPOSED",
				"proposedIndId": 456,
				"notes": "Some String",
				"editableByOrg": true
			}, {
				"memberId": 234,
				"positionId": 734820,
				"positionTypeId": 1481,
				"positionTypeEnum": "PRIMARY_WORKER_CTR_7",
				"position": "Primary Teacher",
				"hidden": false,
				"status": null,
				"proposedIndId": null,
				"notes": null,
				"editableByOrg": true
			}]

		}],
		"callings": []
	},
	"orgWithDirectCallings": {
		"notUsed" : "Ignore this",
		"orgTypeId": 1179,
		"defaultOrgName": "Bishopric",
		"displayOrder": 100,
		"customOrgName": null,
		"subOrgId": 7428354,
		"children": [],
		"callings": [{
			"memberId": 123,
			"positionId": 734829,
			"positionTypeId": 1481,
			"positionTypeEnum": "PRIMARY_WORKER_CTR_7",
			"position": "Primary Teacher",
			"hidden": true,
			"status": "PROPOSED",
			"proposedIndId": 456,
			"notes": "Some String",
			"editableByOrg": true
		}]
	},
	"invalidOrgs" : [
		{ "orgTypeId" : null },
		{},
		{ "subOrgId" : null, "orgTypeId" : 1179 },
		{ "subOrgId" : 1234 },
		{ "subOrgId" : 1234, "orgTypeId" : 1179, "orgName" : null },
		{ "subOrgId" : 1234, "orgTypeId" : 1179, "orgName" : "Bishopric", "displayOrder" : null }
	]
}

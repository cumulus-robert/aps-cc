/**
 * @Business: Test class for Handler class for AlarmCompanyRosterBatchTrgHandler
 * @Date: 2016-08-26
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-363   2016-09-07     Initial development
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/
@IsTest
private class AlarmCompanyRosterBatchTrgHandlerTest {
	@TestSetup
    static void setupTestData() {
        Schema.RecordTypeInfo rtInfo = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Police Department');
        Account testAccount = new Account(Name = 'Test Police Deparment');
        testAccount.RecordTypeId = rtInfo.getRecordTypeId();
        insert testAccount;
        
        Contact testBillingContact = new Contact(LastName = 'Person', FirstName = 'Test');
        insert testBillingContact;
        
        License__c unmatchedLicense = buildLicense('Unmatched License', '01', 'Albert', 'ST',
        							  			   testAccount.Id, 'Permitted');
        insert unmatchedLicense;
        
        testAccount.Unmatched_License__c = unmatchedLicense.Id;
        update testAccount;
    }
    
    static License__c buildLicense(String name, String streetNumber, String streetName, 
    		String streetType, Id policDeptId, String status) {
        return new License__c(
            //Name = 'Test License 1',
            Location_Street_Number__c = streetNumber,
            Location_Street_Name__c = streetName,
            Location_Street_Type__c = streetType,
            Location_City__c = 'Chicago',
            Location_State__c = 'CA',
            Location_Zip__c = streetNumber,
            Police_Department__c = policDeptId,
            License_Status__c = status
        );
    }
    
    static Alarm_Company_Roster_Batch__c buildACRBFromLicense(License__c license, String pdName, String alarmCompanyName) {
        return new Alarm_Company_Roster_Batch__c(
            Police_Department__c = pdName,
            Location_Street_Number__c = license.Location_Street_Number__c,
            Location_Street_Type__c = license.Location_Street_Type__c,
            Location_Street_Name__c = license.Location_Street_Name__c,
            Location_City__c = license.Location_City__c,
            Location_State__c = license.Location_State__c,
            Location_Zip__c = license.Location_Zip__c,
            Alarm_Company__c = alarmCompanyName
        );   
    }
     
    /**
     * Insert ACRB records for which only single License's Address & Police_Department will match
     */
    static testMethod void testLinkACRBRecordToLicense_A() {
    	Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Person' AND FirstName = 'Test' LIMIT 1];
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Police Deparment'];
        
        // Create License records
        List<License__c> listNewLicense = new List<License__c>();
        for(Integer index = 0; index < 100; index++) {
            String name = 'Test License-' + index;        
            License__c testLicense = buildLicense(name, String.valueOf(index), 'Taylor', 'ST', 
            						 	testAccount.Id, 'Permitted');
			testLicense.Billing_Contact__c = testContact.Id;
            listNewLicense.add(testLicense);
        }
        
		insert listNewLicense;
        
        Test.startTest();
        
        List<Alarm_Company_Roster_Batch__c> listACRB = new List<Alarm_Company_Roster_Batch__c>();
        for(Integer index = 0; index < 100; index++) {
            Alarm_Company_Roster_Batch__c newACRB = buildACRBFromLicense(listNewLicense[index], 
            											testAccount.Name, testAccount.Name);
            listACRB.add(newACRB);
        }
        insert listACRB;
        Test.stopTest();
        
        // Verify ACRB record linked to Licenses properly
        for(AggregateResult ar : [SELECT License__c license, COUNT(Id) linkedACRBCount
                                  FROM Alarm_Company_Roster_Batch__c 
                                  WHERE Id IN :listACRB
                                  GROUP by License__c]) {
			System.assertEquals(ar.get('linkedACRBCount'), 1);      
		}
		
		// Verify "Alarm Company" updated properly
		for(License__c license : [SELECT Alarm_Company__c FROM License__c WHERE Id IN :listNewLicense]) {
			System.assertEquals(testAccount.Id, license.Alarm_Company__c);          
		}
		
		// Verify chatter post created for Licenses & Contact
		for(License__c license : [SELECT Id, (SELECT Body FROM Feeds ORDER BY CreatedDate DESC LIMIT 1) 
							   FROM License__c WHERE Id IN :listNewLicense]) {
			System.assert(!license.Feeds.isEmpty());
			System.assert(license.Feeds[0].Body.startsWithIgnoreCase('Alarm Company Roster Matched to License'));					   	
		}
		
		testContact = [SELECT Id, (SELECT Body FROM Feeds ORDER BY CreatedDate DESC LIMIT 1) 
							      FROM Contact WHERE Id = :testContact.Id];			
		System.assert(testContact.Feeds[0].Body.startsWithIgnoreCase('Alarm Company Roster Matched to Contact'));
    }
    
    /**
     * Insert ACRB records for which there are two License's Address & Police_Department will match
     */
    static testMethod void testLinkACRBRecordToLicense_B() {
        Account testAccount = [SELECT Id, Name, Unmatched_License__c  FROM Account WHERE Name = 'Test Police Deparment'];
        
        // Create License records
        List<License__c> listNewLicense = new List<License__c>();
        for(Integer index = 0; index < 50; index++) {
            String name = 'Test License-' + index;        
            License__c testLicense1 = buildLicense(name, String.valueOf(index), 'Taylor', 'ST', 
            									   testAccount.Id, 'Permitted');
            License__c testLicense2 = buildLicense(name, String.valueOf(index), 'Taylor', 'ST', 
            									   testAccount.Id, 'Permitted');
            listNewLicense.add(testLicense1);
            listNewLicense.add(testLicense2);
        }
        
		insert listNewLicense;
        
        Test.startTest();
        
        List<Alarm_Company_Roster_Batch__c> listACRB = new List<Alarm_Company_Roster_Batch__c>();
        for(Integer index = 0; index < 50; index++) {
            Alarm_Company_Roster_Batch__c newACRB = buildACRBFromLicense(listNewLicense[index + 1], testAccount.Name, testAccount.Name);
            listACRB.add(newACRB);
        }
        insert listACRB;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM Alarm_Company_Roster_Batch__c 
                         WHERE Id IN :listACRB AND License__c = :testAccount.Unmatched_License__c];        
		System.assertEquals(listACRB.size(), count);           		
    }
    
    /**
     * Insert ACRB records for which there is no matching License.
     */
    static testMethod void testLinkACRBRecordToLicense_C() {
        Account testAccount = [SELECT Id, Name, Unmatched_License__c  FROM Account WHERE Name = 'Test Police Deparment'];
        
        // Create License records
        List<License__c> listNewLicense = new List<License__c>();
        for(Integer index = 0; index < 200; index++) {
            String name = 'Test License-' + index;        
            License__c testLicense = buildLicense(name, String.valueOf(index), 
                                                  'Taylor', 'ST', testAccount.Id, 'Permitted');
            listNewLicense.add(testLicense);
        }
        
        Test.startTest();
        
        List<Alarm_Company_Roster_Batch__c> listACRB = new List<Alarm_Company_Roster_Batch__c>();
        for(Integer index = 0; index < 200; index++) {
            Alarm_Company_Roster_Batch__c newACRB = buildACRBFromLicense(listNewLicense[index], testAccount.Name, testAccount.Name);
            newACRB.Contact_Last_Name__c = 'Person' + index;
            listACRB.add(newACRB);
        }
        insert listACRB;
        Test.stopTest();
        
        List<License__c> listLicenseCreated = [SELECT Id FROM License__c 
                         					   WHERE Id IN (SELECT License__c FROM Alarm_Company_Roster_Batch__c WHERE Id IN :listACRB)];
        System.assertEquals(listACRB.size(), listLicenseCreated.size());
        
        
        Integer count = [SELECT COUNT() FROM Contact 
                         WHERE Id IN (SELECT Billing_Contact__c 
                                      FROM License__c WHERE Id IN :listLicenseCreated)];
		System.assertEquals(listACRB.size(), count);
    }
}
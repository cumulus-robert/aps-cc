/**
 * @Business: Test class for Handler class for FalseAlarmBatchTriggerHandler
 * @Date: 2016-08-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-358   2016-08-23     Initial development
 * APS-368   2016-08-30
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/
@IsTest
private class FalseAlarmBatchTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        Schema.RecordTypeInfo rtInfo = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Police Department');
        Account testAccount = new Account(Name = 'Test Police Deparment');
        testAccount.RecordTypeId = rtInfo.getRecordTypeId();
        insert testAccount;
        
        // Create License records
        License__c defaultLicense = new License__c(                                        
                                        Police_Department__c = testAccount.Id,
										License_Status__c = 'Permitted');
        
        License__c testLicense = new License__c(
										Location_Street_Number__c = '012',
										Location_Street_Name__c = 'XYZ Street',
										Location_Street_Type__c = 'SF',
                                        Police_Department__c = testAccount.Id,
										License_Status__c = 'Permitted');
        insert new List<License__c> {defaultLicense, testLicense};
            
		testAccount.Unmatched_License__c = defaultLicense.Id;
        update testAccount;
    }
    
    /**
     * Test insertFalseAlarmRecords() function with False_Alarm record's 
     * Address is either matching with only one Licens's Address or not with any License's address
     */
    static testMethod void testInsertFalseAlarmRecords_A() {
        Account policeDept = [SELECT Id, Unmatched_License__c FROM Account WHERE Name = 'Test Police Deparment'];
        License__c testLicense = [SELECT Id, Location_Address__c FROM License__c WHERE id !=: policeDept.Unmatched_License__c];
        
        List<False_Alarm_Batch__c> listFABWithValidAddress = new List<False_Alarm_Batch__c>();
        for(Integer index = 0; index < 100; index++) {
            False_Alarm_Batch__c newFAB = new False_Alarm_Batch__c();
            newFAB.Police_Department__c = policeDept.Id;
            newFAB.Street_Address__c = testLicense.Location_Address__c;
            listFABWithValidAddress.add(newFAB);
        }
        
        List<False_Alarm_Batch__c> listFABWithInvalidAddress = new List<False_Alarm_Batch__c>();
        for(Integer index = 0; index < 100; index++) {
            False_Alarm_Batch__c newFAB = new False_Alarm_Batch__c();
            newFAB.Police_Department__c = policeDept.Id;
            newFAB.Street_Address__c = '123 Street, CA';
            listFABWithInvalidAddress.add(newFAB);
        }
        
        Test.startTest();
        
        List<False_Alarm_Batch__c> listFABToInsert = new List<False_Alarm_Batch__c>();
        listFABToInsert.addAll(listFABWithValidAddress);
        listFABToInsert.addAll(listFABWithInvalidAddress);
        
        insert listFABToInsert;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM False_Alarm__c 
                         WHERE False_Alarm_Batch__c IN :listFABWithValidAddress
                             AND License__c = :testLicense.Id];
        System.assertEquals(listFABWithValidAddress.size(), count);
        
        count = [SELECT COUNT() FROM False_Alarm__c 
                 WHERE False_Alarm_Batch__c IN :listFABWithInvalidAddress
                 	AND License__c = :policeDept.Unmatched_License__c];
        System.assertEquals(listFABWithInvalidAddress.size(), count);
    }
    
    /**
     * Test insertFalseAlarmRecords() function with False_Alarm record's 
     * Address is matching with more than one Licens's Address
     */
    static testMethod void testInsertFalseAlarmRecords_B() {
   		Account policeDept = [SELECT Id, Unmatched_License__c FROM Account WHERE Name = 'Test Police Deparment'];
    	License__c testLicense2 = new License__c(
						              Location_Street_Number__c = '012',
									  Location_Street_Name__c = 'XYZ Street',
									  Location_Street_Type__c = 'SF',
                                      Police_Department__c = policeDept.Id,
									  License_Status__c = 'Permitted');
		insert testLicense2;
		testLicense2 = [SELECT Id, Location_Address__c FROM License__c WHERE Id = :testLicense2.Id];
		
		Test.startTest();
		
		List<False_Alarm_Batch__c> listFABWithValidAddress = new List<False_Alarm_Batch__c>();
        for(Integer index = 0; index < 200; index++) {
            False_Alarm_Batch__c newFAB = new False_Alarm_Batch__c();
            newFAB.Police_Department__c = policeDept.Id;
            newFAB.Street_Address__c = testLicense2.Location_Address__c;
            listFABWithValidAddress.add(newFAB);
        }
        
		insert listFABWithValidAddress;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM False_Alarm__c 
                         WHERE False_Alarm_Batch__c IN :listFABWithValidAddress
                             AND License__c = :policeDept.Unmatched_License__c];
        System.assertEquals(listFABWithValidAddress.size(), count);
    }
    
    /**
     * Test insertFalseAlarmRecords() function with False_Alarm record's 
     * Address is matching with exactly one Licens's Location_Address_1_OASIS__c field
     */
    static testMethod void testInsertFalseAlarmRecords_C() {
   		Account policeDept = [SELECT Id, Unmatched_License__c FROM Account WHERE Name = 'Test Police Deparment'];
    	License__c testLicense = new License__c(
						              Location_Address_1_OASIS__c = '007 James Street HD',
                                      Police_Department__c = policeDept.Id,
									  License_Status__c = 'Permitted');
		insert testLicense;
		testLicense = [SELECT Id, Location_Address_1_OASIS__c FROM License__c WHERE Id = :testLicense.Id];
		
		Test.startTest();
		
		List<False_Alarm_Batch__c> listFABWithValidAddress = new List<False_Alarm_Batch__c>();
        for(Integer index = 0; index < 200; index++) {
            False_Alarm_Batch__c newFAB = new False_Alarm_Batch__c();
            newFAB.Police_Department__c = policeDept.Id;
            newFAB.Street_Address__c = testLicense.Location_Address_1_OASIS__c;
            listFABWithValidAddress.add(newFAB);
        }
        
		insert listFABWithValidAddress;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM False_Alarm__c 
                         WHERE False_Alarm_Batch__c IN :listFABWithValidAddress
                             AND License__c = :testLicense.Id];
        System.assertEquals(listFABWithValidAddress.size(), count);
    }
}
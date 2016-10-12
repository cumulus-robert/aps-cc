/*
 * @Business: Test Class for LicenseTriggerHandler
 * @Date: 4/15/2016
 * @Author: Cumulus Vision
 * @Request: APS-264
 * Modified      ModifiedDate  Description
 * APS-264       04/19/2016    Initial Phase
 * APS-347       8/9/2016     Create Invoice & Invoice_Line_Item records on insert of Statement record 
*/
@isTest 
public class LicenseTriggerHandlerTest {
            
    @testSetup
    static void setupData() {
        Schema.RecordTypeInfo rtInfo = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Police Department');
        Account testAccount = new Account(Name = 'Test Police Deparment');
        testAccount.RecordTypeId = rtInfo.getRecordTypeId();
        insert testAccount;
        
        License__c oldLicense = new License__c(Location_Address_1_OASIS__c = 'Test Address',
                                               Police_Department__c = testAccount.Id);
        insert oldLicense;
        
        List<False_Alarm__c> falseAlarmList = new List<False_Alarm__c>();
        for(Integer count = 0; count < 10; count++){            
            falseAlarmList.add(new False_Alarm__c(License__c = oldLicense.id,
                                                  Location__c = 'Test Address' + count));            
        }      
        insert falseAlarmList;
    }
    
    private static testMethod void testAssociateFalseAlarmsToNewLicenses() {
        
        List<License__c> licenseList = new List<License__c>();        
        Account policeDept = [SELECT Id FROM Account WHERE Name = 'Test Police Deparment'];
        for(Integer count = 0; count < 5; count++){
            licenseList.add(new License__c(Location_Address_1_OASIS__c = 'Test Address' + count,
                           				   Police_Department__c = policeDept.Id));
        }
        for(Integer count = 5; count < 10; count++){
            licenseList.add(new License__c(Location_Address_2_OASIS__c = 'Test Address' + count,
                           				   Police_Department__c = policeDept.Id));
        }
        Test.startTest();
        insert licenseList;
        Test.stopTest();
        
        List<False_Alarm__c> falseAlarmList = [SELECT Name, License__c, Location__c 
                                               FROM False_Alarm__c 
                                               WHERE License__c IN :licenseList];
        
    }
    
    private static testMethod void testPopulateLicenseFields() {
        
        List<License__c> licenseList = new List<License__c>();        
        Account policeDept = [SELECT Id FROM Account WHERE Name = 'Test Police Deparment'];
        for(Integer count = 0; count < 10; count++){
            licenseList.add(new License__c(Location_Address_1_OASIS__c = '1234 Address aly',
                                            Police_Department__c = policeDept.Id));
        }
        Test.startTest();
        insert licenseList;
        Test.stopTest();
        
        List<License__c> licenseUpdatedList = [SELECT Id,Location_Street_Number__c,
                                                   Location_Street_Name__c,
                                                   Location_Street_Type__c
                                               FROM License__c
                                               WHERE Name = 'Test'];
                
        //System.assertEquals(10, licenseUpdatedList.size());
        
        /*for(Integer count = 0; count < 10; count++){                                    
            System.assertEquals('ALY', licenseUpdatedList [count].Location_Street_Type__c);
            System.assertEquals('ADDRESS', licenseUpdatedList [count].Location_Street_Name__c);
            System.assertEquals('1234', licenseUpdatedList [count].Location_Street_Number__c);
        }*/
    }
    
    private static testMethod void testInsertInvoiceAndLineItems() {
        List<License__c> licenseList = new List<License__c>();        
        Account policeDept = [SELECT Id FROM Account WHERE Name = 'Test Police Deparment'];
        for(Integer count = 0; count < 50; count++){
            licenseList.add(new License__c(Location_Address_1_OASIS__c = '1234 Address aly',Police_Department__c = policeDept.Id));
        }
        Test.startTest();
        insert licenseList;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM Invoice__c WHERE License__c IN :licenseList AND Type__c = 'Permit'];
        //System.assertEquals(licenseList.size(), count);
        
        count = [SELECT COUNT() FROM Invoice_Line_Item__c 
                 WHERE Invoice__c IN (SELECT Id FROM Invoice__c 
                                      WHERE License__c IN :licenseList AND Type__c = 'Permit')];
		//System.assertEquals(licenseList.size(), count);
    }
}
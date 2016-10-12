/*
 * @Business: test for Controller for New License Visualforce page
 * @Date: 2016-04-20
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-367   2016-09-07     Added test method - testUpdateLicenseOfFalseAlarm
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/ 
@isTest
private class NewLicenseControllerTest {
            
    @isTest static void newLicenseTest() {
        string pd = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        Account pdacct = new Account(Name='testAcc', recordTypeId = pd);
        insert pdacct;      
        License__c l = new License__c();
        License__c license = new License__c(Police_Department__c = pdacct.id, License_Type__c='Government');
        insert license;
        List<False_Alarm__c> listFAcontact = new List<False_Alarm__c>();
        for(Integer i=0;i<10 ;i++) {
            False_Alarm__c f = new False_Alarm__c(Attention_First_Name__c = 'Jane', Attention_Last_Name__c = 'Doe' + i, license__c = license.id);
            listFAcontact.add(f);
        }
        
        insert ListFAcontact;  
        ApexPages.StandardController sc = new ApexPages.StandardController(l);
        NewLicenseController controller = new NewLicenseController(sc);
        controller.theAlarmCompany = '---NONE---';
        controller.getAlarmCompanies();
        controller.getPoliceDepartments();        
        controller.thePD = pdacct.id;
        controller.submit();        
    }
    
    static testMethod void testUpdateLicenseOfFalseAlarm() {
        RecordTypeInfo rtPoliceDepartment = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department');
        Account testPD = new Account(Name = 'Test Police Department', recordTypeId = rtPoliceDepartment.getRecordTypeId());
        insert testPD;
        
        License__c testLicense = new License__c(Police_Department__c = testPD.Id);
        insert testLicense;
        
 
        
        False_Alarm__c testFA = new False_Alarm__c(License__c = testLicense.id,
                                 Location__c = 'Test Location',
                                 Location_Business_Name__c = 'Test Business', 
                                 Date_Received__c = '01/01/2000 18:00:22');
        insert testFA;
        
        Test.startTest();
        
        Test.setCurrentPageReference(new PageReference('/apex/NewLicense?faId=' + testFA.Id));
        License__c newLicense = new License__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(newLicense);
        NewLicenseController controller = new NewLicenseController(sc);
        
        controller.submit(); 
        
        Test.stopTest();                
    }
}
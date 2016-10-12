/*
 * @Business: Test unit for cover code in class CulverCityFalseAlarmBatchTriggerHandler
 * @Date: 2016-04-12
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/
@isTest
private class CulverCityFalseAlarmBatchTriggerTest {

    @testSetup static void testSetup() {
        string alarmCompany = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Alarm Company').getRecordTypeId();
        string pd = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        
        Account acc = new Account(Name='testAcc', recordTypeId = alarmCompany);
        insert acc;
        Account pdacct = new Account(Name='CULVER CITY POLICE DEPARTMENT', recordTypeId = pd);
        insert pdacct;
        
        // create default license
        License__c dl = new License__c(Police_Department__c = pdacct.id);        
        License__c l1 = new License__c(Alarm_Company__c = acc.Id, Police_Department__c = pdacct.id, Location_Address_1_OASIS__c = 'test address', Location_Address_2_OASIS__c = 'address2222');
        
        insert new List<License__c>{dl, l1};
        pdacct.Unmatched_License__c = dl.id;
        update pdacct;
    }
    
    @isTest static void testFalseAlarmCreation() {
        
        List<License__c> listLicenses = [SELECT Id FROM License__c];
        system.debug('listLicenses ==== '+listLicenses);
        
            CC_False_Alarm_Batch__c fab = new CC_False_Alarm_Batch__c();
            fab.Incident_Address__c = 'test address';
            fab.Incident_Date_And_Time__c = '03/28/2016 12:10:18';
            fab.Incident_Type__c = '459 PC- BURGLARY';
            fab.Incident_Unit_Disposition__c = '3';
            fab.Document_Text__c = 'test document';

            CC_False_Alarm_Batch__c fab1 = new CC_False_Alarm_Batch__c();
            fab1.Incident_Address__c = 'test';
            fab1.Incident_Date_And_Time__c = '03/28/2016 12:10:18';
            fab1.Incident_Type__c = '459 PC- BURGLARY';
            fab1.Incident_Unit_Disposition__c = '3';
            fab1.Document_Text__c = 'test document123';

            INSERT new List<CC_False_Alarm_Batch__c>{fab, fab1};

    }
}
/*
 * @Business: test for BatchSetFalseAlarmCounts
 * @Date: 2016-08-23
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/
@isTest
public class BatchSetFalseAlarmCountsTest {
    
        @testSetup static void testSetup() {
        string alarmCompany = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Alarm Company').getRecordTypeId();
        string pd = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        
        Account acc = new Account(Name='testAcc', recordTypeId = alarmCompany);
        insert acc;
        Account pdacct = new Account(Name='testAcc', recordTypeId = pd);
        insert pdacct;
        
        // create default license
        License__c dl = new License__c(Police_Department__c = pdacct.id);        
        License__c l1 = new License__c(Alarm_Company__c = acc.Id, Police_Department__c = pdacct.id, Location_Address_1_OASIS__c = 'test address', Location_Address_2_OASIS__c = 'address2222');
        
        insert new List<License__c>{dl, l1};
    }

    static testMethod void fatest1() {

      List<License__c> lictest = [select id from License__c where Name != '00-000000'];
      List<False_Alarm__c> fatest = new List<False_Alarm__c>();

      test.startTest();

      fatest.add(new False_Alarm__c(License__c = lictest[0].id, Date_Received__c = '01/01/2000',Time_Received__c='18:00:22'));
      fatest.add(new False_Alarm__c(License__c = lictest[0].id, Date_Received__c = '01/01/2000 18:00:22'));

      insert fatest;

      test.stopTest();

    }
    
    private static License__c buildLicense(String licenseName, Id policeDeptartmentId) {
        return new License__c(
                   //Name = licenseName,
                 Police_Department__c = policeDeptartmentId
             );
    }
    
    private static False_Alarm__c buildFalseAlarm(Id licenseId, DateTime eventDateTime) {
        return new False_Alarm__c(
                   License__c = licenseId,
                 Event_Date_Time__c = eventDateTime
             );
    }
    
    private static testMethod void testUpdateFalseAlarmCount() {
        // Insert Account record
        Id rtPoliceDepartmentId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        Account testAccount1 = new Account(Name = 'CULVER CITY POLICE DEPARTMENT', RecordTypeId = rtPoliceDepartmentId);
        Account testAccount2 = new Account(Name = 'CULVER CITY POLICE DEPARTMENT', RecordTypeId = rtPoliceDepartmentId);
        testAccount2.False_Alarm_Billing_Logic__c = 'Calendar Year';
        insert new List<Account> {testAccount1, testAccount2};
        
        // Insert two License
        License__c license1 = buildLicense('TL-0001', testAccount1.Id);
        License__c license2 = buildLicense('TL-0002', testAccount2.Id);
        insert new List<License__c> {license1, license2};
        
        // Insert False_Alarm records for License1
        List<False_Alarm__c> listFA = new List<False_Alarm__c>();
        Time defaultTime = Time.newInstance(0, 0, 0, 0);
        Date defaultDate = System.today().addDays(-364);
        for(Integer index = 0; index < 100; index++) {            
            listFA.add(buildFalseAlarm(license1.Id, DateTime.newInstanceGMT(defaultDate.addDays(index), defaultTime)));
            listFA.add(buildFalseAlarm(license2.Id, DateTime.newInstanceGMT(defaultDate.addDays(index), defaultTime)));            
        }
        insert listFA;
            
        Test.startTest();        
        Database.executeBatch(new BatchSetFalseAlarmCounts(), 100);           
        Test.stopTest();
        
                Integer index = 1;
        for(False_Alarm__c fa : [SELECT Id, False_Alarm_Count__c FROM False_Alarm__c
                                 WHERE License__c = :license1.Id AND In_Last_Year__c = true
                                   AND Event_Date_Time__c >= LAST_N_DAYS:365
                                 ORDER BY Event_Date_Time__c]) {
        //System.assertEquals(String.valueOf(index++), fa.False_Alarm_Count__c);
        }
        
        index = 1;
        for(False_Alarm__c fa : [SELECT Id, License__c, False_Alarm_Count__c FROM False_Alarm__c
                                 WHERE License__c = :license2.Id AND Event_Date_Time__c = THIS_YEAR
                                 ORDER BY Event_Date_Time__c]) {
        //System.assertEquals(index++, Integer.valueOf(fa.False_Alarm_Count__c));
        }
    }
}
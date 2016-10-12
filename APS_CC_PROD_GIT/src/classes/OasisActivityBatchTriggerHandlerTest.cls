/*
 * @Business: see OASIS_Activity_Batch__c Trigger Handler
 * @Date: 2016-04-04
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-378   2016-09-17     Updated to account for license name change to auto number
*/


@isTest 
public class OasisActivityBatchTriggerHandlerTest {

    @testSetup static void testSetup() {
        string alarmCompany = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Alarm Company').getRecordTypeId();
        string pd = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        
        Account acc = new Account(Name='AC', recordTypeId = alarmCompany);
        insert acc;
        Account pdacct = new Account(Name='PD', recordTypeId = pd);
        insert pdacct;
        
        // create default license
        License__c dl = new License__c(Police_Department__c = pdacct.id);        
        License__c l1 = new License__c(Alarm_Company__c = acc.Id, Police_Department__c = pdacct.id, Location_Address_1_OASIS__c = 'test address', Location_Address_2_OASIS__c = 'address2222');
        
        insert new List<License__c>{dl, l1};
    }
            
    private static testMethod void batch1() {
        
        List<License__c> lictest = [select id from License__c where Name != '00-000000'];
        List<OASIS_Activity_Batch__c> oatest = new List<OASIS_Activity_Batch__c>();
        List<OASIS_Activity_Batch__c> oatest1 = new List<OASIS_Activity_Batch__c>();
    	
    	test.startTest();
        
    	oatest.add(new OASIS_Activity_Batch__c(License__c = lictest[0].id, BillingActivityId__c='1',ActivityType__c = '1',ActivityDate__c=system.today(),Amount__c='100',Billing_Note__c='Test',Item__c='Test'));
        oatest.add(new OASIS_Activity_Batch__c(License__c = lictest[0].id, BillingActivityId__c='2',ActivityType__c = '11',ActivityDate__c=system.today(),Amount__c='100',Billing_Note__c='Test',Item__c='Test'));

        insert oatest;

        oatest1.add(new OASIS_Activity_Batch__c(License__c = lictest[0].id, BillingActivityId__c='3',ActivityType__c = '22',ActivityDate__c=system.today(),Amount__c='100',Billing_Note__c='Test',Item__c='Test'));
        oatest1.add(new OASIS_Activity_Batch__c(License__c = lictest[0].id, BillingActivityId__c='4',ActivityType__c = '13',ActivityDate__c=system.today(),Amount__c='100',Billing_Note__c='Test',Item__c='Test'));
        oatest1.add(new OASIS_Activity_Batch__c(License__c = lictest[0].id, BillingActivityId__c='5',ActivityType__c = '2',ActivityDate__c=system.today(),Amount__c='100',Billing_Note__c='Test',Item__c='Test'));
        insert oatest1;

        test.stopTest();

    }
}
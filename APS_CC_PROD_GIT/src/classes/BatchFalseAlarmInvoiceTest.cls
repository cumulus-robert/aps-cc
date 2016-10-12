@isTest
private class BatchFalseAlarmInvoiceTest {
	public static Account accounttest {get; set;}
	public static List<License__c> lstlicenses {get; set;}
	public static List<False_Alarm__c> lstfalsealarm {get; set;}

	/**
    * @description Method create admin using to avoid validation rule on account
    * @date 12/01/2016
    * @author N52
    */
    private static User createAdmin() {

      Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
      User u = new User(Alias = 'Admin', Email='admin123@testorg.com',
                      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                      LocaleSidKey='en_US', ProfileId = p.Id,
                      TimeZoneSidKey='America/Los_Angeles', UserName='admin123@testorg.com'); 

      return u;
    }

    static void CreateRecords() {
       
        System.runAs(createAdmin()) {
			Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
                        
            accounttest = new Account(Name='testAcc', BillingPostalCode='3256', RecordTypeId = policeDepartmentRecordTypeId);
            insert accounttest;

            lstlicenses = new List<License__c>();
            lstlicenses.add(new License__c(License_Status__c='Permitted',License_Type__c='Residential', Police_Department__c = accounttest.Id));
            lstlicenses.add(new License__c(License_Status__c='Permitted',License_Type__c='Residential', Police_Department__c = accounttest.Id));
            lstlicenses.add(new License__c(License_Status__c='Unpermitted',License_Type__c='Residential', Police_Department__c = accounttest.Id));
            lstlicenses.add(new License__c(License_Status__c='Exempt',License_Type__c='Residential', Police_Department__c = accounttest.Id));
            lstlicenses.add(new License__c(License_Status__c='Inactivated',License_Type__c='Residential', Police_Department__c = accounttest.Id));
            insert lstlicenses;
            
            
            lstfalsealarm = new List<False_Alarm__c>();
            for(License__c license : lstlicenses) {
                False_Alarm__c falseAlarm = new False_Alarm__c();
                falseAlarm.License__c = license.Id;
                falseAlarm.False_Alarm_Count__c = '2';
                lstfalsealarm.add(falseAlarm);
            }            
            insert lstfalsealarm;
        }
    }
    static testMethod void falseAlarmInvoiceBatch() {
        CreateRecords();
        
        Test.startTest();
        
        database.executeBatch(new BatchFalseAlarmInvoice());
                
        Test.stopTest();
    }

}
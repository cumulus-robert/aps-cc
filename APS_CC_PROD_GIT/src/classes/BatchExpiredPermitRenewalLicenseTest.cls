/**
 * @author Mahesh G.
 * @createdDate 2016-08-06
 * RequestId    ModifiedDate    Comment
 * APS-345      2016-08-08      Initial Phase
 * APS-369      2016-09-02    
 * APS-378      2016-09-17      Updated to account for license name change to auto number 
 */
@isTest
private class BatchExpiredPermitRenewalLicenseTest {
    
    static testMethod void testBatchClass() {
        Schema.RecordTypeInfo rtInfo = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Police Department');
        Account testAccount = new Account(Name = 'Test Police Deparment');
        testAccount.RecordTypeId = rtInfo.getRecordTypeId();
        insert testAccount;
        
        List<License__c> listLicense = new List<License__c>();
        
        for(Integer index = 1; index <= 100; index++) {
        	// Insert License status = 'Permitted'
            License__c newLicense = new License__c(//Name = 'License ' + index,
                                         Location_Address_1_OASIS__c = 'Test Address',
                                         Permit_Date_OASIS__c = DateTime.now().addDays(-370),                                                  
                                         Police_Department__c = testAccount.Id,
                                         License_Status__c = 'Permitted');
            listLicense.add(newLicense);
        }
        insert listLicense;

		License__c inactiveLicense = new License__c(//Name = 'Test Inactiv License',
                                     	Location_Address_1_OASIS__c = 'Test Address',
                                        Permit_Date_OASIS__c = DateTime.now().addDays(-370),                                                  
                                        Police_Department__c = testAccount.Id,
                                        License_Status__c = 'Permitted');
        insert inactiveLicense;
		inactiveLicense.License_Status__c = 'Inactivated';
        update inactiveLicense; 
        
        Test.startTest();
        
        Database.executeBatch(new BatchExpiredPermitRenewalLicense());
        
        Test.stopTest();
        
        listLicense = [SELECT License_Status__c FROM License__c WHERE Id IN :listLicense];
        for(License__c license : listLicense) {
            System.assertEquals('Unpermitted', license.License_Status__c);
        }
        
        inactiveLicense = [SELECT License_Status__c FROM License__c WHERE Id = :inactiveLicense.Id];
        System.assertNotEquals('Unpermitted', inactiveLicense.License_Status__c);
    }
    
    static testMethod void testScheduler() {
        Date scheduleDate = Date.today().addDays(1);
        Integer day = scheduleDate.day();
        Integer month = scheduleDate.month();
        Integer year = scheduleDate.year();
        String cronExp= '0 0 0 ' + day  + ' ' + month  + ' ? ' + year;        

        Test.startTest();
        System.schedule('BatchExpiredPermitRenewalLicense Scheduler', cronExp, new BatchExpiredPermitRnwlLicenseScheduler());
        
        Test.stopTest();
    }
}
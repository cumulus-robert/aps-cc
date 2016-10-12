/**
*  @author Amol K
*  @createdOn 17 May 2016
*  @description  test bacth class that manage the license status and renewal invoice for all permitted licenses with a permit date
*  less than today. 
*/
@isTest
public class LicenseRenewalBatchTest {
	private static Date todayDate;
	
	private static License__c buildLicense(String status, String type, Id policeDeptId, Date oasisDate) {
		return new License__c(
			License_Status__c = status,
			License_Type__c = type,
			Police_Department__c = policeDeptId,
			Permit_Date_OASIS__c = oasisDate	
		);
	} 
	
	
    @testSetup static void createTestData(){
        
        Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        
        Account accounttest = new Account(Name='testAcc', BillingPostalCode='3256', RecordTypeId = policeDepartmentRecordTypeId);
        insert accounttest;
        
        List<License__c> lstlicenses = new List<License__c>();
        lstlicenses.add(buildLicense('Permitted','Residential', accounttest.Id,System.Today().addDays(-400)));
        lstlicenses.add(buildLicense('Permitted','Residential', accounttest.Id, System.Today().addDays(-401)));
        lstlicenses.add(buildLicense('Unpermitted','Residential', accounttest.Id, System.Today().addDays(-403)));
        lstlicenses.add(buildLicense('Exempt','Residential', accounttest.Id, System.Today().addDays(-404)));
        lstlicenses.add(buildLicense('Inactivated','Residential', accounttest.Id, System.Today().addDays(-405)));
        insert lstlicenses;
        // On License there is trigger which insert "Invoic" and "Invoice Line Item" records, so need to delete those
        delete [SELECT Id FROM Invoice__c WHERE License__c IN :lstlicenses];        
        
        List<Invoice__c>listInvoices = new List<Invoice__c>();
        
        for(License__c license: lstlicenses){
            listInvoices.add( new Invoice__c(Type__c = 'Test', Permit_Billing_Year__c = String.ValueOf(System.Today().year()-1), License__c= license.Id));           
        }
        License__c testLicence = buildLicense('Inactivated','Residential', accounttest.Id, System.Today()-1);
        insert testLicence;
        
        testLicence =  buildLicense('Inactivated','Residential', accounttest.Id, System.Today()-1);
        insert testLicence;
        
        listInvoices.add( new Invoice__c(Type__c = 'Permit', Permit_Billing_Year__c = String.ValueOf(System.Today().year()-1), 
                                         License__c= testLicence.Id));                                
        
        testLicence =  buildLicense('Inactivated','Residential', accounttest.Id,System.Today()-1);
        insert testLicence;
        
        listInvoices.add( new Invoice__c(Type__c = 'Permit', Permit_Billing_Year__c = String.ValueOf(System.Today().year()), 
                                         License__c= testLicence.Id));                       
        
        testLicence =  buildLicense('Inactivated','Residential', accounttest.Id, System.Today()-1);
        insert testLicence;
        
        listInvoices.add( new Invoice__c(Type__c = 'Permit', Permit_Billing_Year__c = String.ValueOf(System.Today().year()-1), Status__c= 'Cancelled', 
                                         Credit_Notes__c = 'Automatically cancelled in Permit renewal job. New Invoice created for current permit billing year',
                                         License__c= testLicence.Id));                       
        insert listInvoices;
        
    }
    
    public static testMethod  void testSLicenseRenewalBatchScheduler() {
        
        Test.startTest();            
        // Schedule Batch EveryDay at Midnight
        String cronExp = '0 0 0 * * ?';               
        
        // create a list of CronTrigger records that are scheduled to fire again and abort all 
        List<CronTrigger> cronTriggersReadyToFireAgain = [SELECT Id FROM CronTrigger]; 
        
        // if the list is not empty abort the job
        if (!cronTriggersReadyToFireAgain.isEmpty()) { 
            for (CronTrigger t : cronTriggersReadyToFireAgain) { 
                System.abortJob(t.Id); 
            }
        }
        
        // Schedule Job
        String ScheduledJobID = system.schedule('test' + cronExp, cronExp, new LicenseRenewalBatchScheduler());                
        
        CronTrigger jobScheduled =  [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType 
                                     FROM CronTrigger 
                                     WHERE Id = :ScheduledJobID];
        system.assertNotEquals(null, jobScheduled.Id);        
        Test.stopTest();                               
    }
    public static testMethod  void testSLicenseRenewalBatch() {    
        Test.startTest();
        // excute batch class that renews License 
        Database.executeBatch(new LicenseRenewalBatch());    
        Test.stopTest();
        
        
        /*Invoice_Line_Item__c invoiceLineItem = [SELECT Id, Invoice__r.Permit_Billing_Year__c, Invoice__r.License__r.Permit_Date_OASIS__c, Item__c, Item_Type__c
                                                FROM Invoice_Line_Item__c
                                                WHERE Item__c = 'Renewal Permit'
                                                	AND Item_Type__c = 'Permit' 
                                                LIMIT 1];
        system.assertEquals('Renewal Permit', invoiceLineItem.Item__c);    
        system.assertEquals('Permit', invoiceLineItem.Item_Type__c);
        system.assertEquals(String.ValueOf(System.Today().year()), invoiceLineItem.Invoice__r.Permit_Billing_Year__c);    
        system.assertNotEquals(System.Today(), invoiceLineItem.Invoice__r.License__r.Permit_Date_OASIS__c);*/        
    }
    
    /**
     * Testing for License related to 'PARADISE POLICE DEPARTMENT' and created in month 
     * other than July
     */
    private static testMethod void testBatchForParadisePoliceDepartment_A() {
    	Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
    	Account paradisePoliceDept = new Account(Name = 'PARADISE POLICE DEPARTMENT', 
    								     BillingPostalCode = '1234', 
    								     RecordTypeId = policeDepartmentRecordTypeId);
        insert paradisePoliceDept;
        
        List<License__c> lstlicenses = new List<License__c>();
        lstlicenses.add(buildLicense('Permitted','Residential', paradisePoliceDept.Id,System.Today().addDays(-325)));
        lstlicenses.add(buildLicense('Permitted','Residential', paradisePoliceDept.Id, System.Today().addDays(-325)));
        insert lstlicenses;
        
        // On License there is trigger which insert "Invoic" and "Invoice Line Item" records, so need to delete those
        delete [SELECT Id FROM Invoice__c WHERE License__c IN :lstlicenses];
        
        List<Invoice__c> listInvoices = new List<Invoice__c>();        
        for(License__c license: lstlicenses){
            listInvoices.add(new Invoice__c(Type__c = 'Test',
            				     Permit_Billing_Year__c = String.ValueOf(System.today().addYears(-1).year()),
            				     License__c= license.Id));           
        }
        insert listInvoices;
        
        Test.startTest();
        // Set today's date in any of date excluding of "July" month
        LicenseRenewalBatchTest.setTodayDate(Date.newInstance(2016, 8, 2));
        Database.executeBatch(new LicenseRenewalBatch());    
        Test.stopTest();

		Integer count = [SELECT COUNT() FROM Invoice_Line_Item__c WHERE Invoice__r.License__c IN :lstlicenses];
		System.assertEquals(0, count);      
    }
    
    /**
     * Testing for License related to 'PARADISE POLICE DEPARTMENT' and created in July month    
    **/
    private static testMethod void testBatchForParadisePoliceDepartment_B() {
    	Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
    	Account paradisePoliceDept = new Account(Name = 'PARADISE POLICE DEPARTMENT', 
    								     BillingPostalCode = '1234', 
    								     RecordTypeId = policeDepartmentRecordTypeId);
        insert paradisePoliceDept;
        
        List<License__c> lstlicenses = new List<License__c>();
        lstlicenses.add(buildLicense('Permitted','Residential', paradisePoliceDept.Id,System.Today().addDays(-325)));
        lstlicenses.add(buildLicense('Permitted','Residential', paradisePoliceDept.Id, System.Today().addDays(-325)));
        insert lstlicenses;
        
        // On License there is trigger which insert "Invoic" and "Invoice Line Item" records, so need to delete those
        delete [SELECT Id FROM Invoice__c WHERE License__c IN :lstlicenses];
        
        List<Invoice__c> listInvoices = new List<Invoice__c>();        
        for(License__c license: lstlicenses){
            listInvoices.add(new Invoice__c(Type__c = 'Test',
            				     Permit_Billing_Year__c = String.ValueOf(System.today().addYears(-1).year()),
            				     License__c= license.Id));           
        }
        insert listInvoices;
        
        Test.startTest();
        // Set today's date in any of date of "July" month
        LicenseRenewalBatchTest.setTodayDate(Date.newInstance(2016, 7, 2));
        Database.executeBatch(new LicenseRenewalBatch());    
        Test.stopTest();

		Integer count = [SELECT COUNT() FROM Invoice_Line_Item__c WHERE Invoice__c IN :listInvoices];
		//System.assertEquals(listInvoices.size(), count);      
    }
    
    /**
     * Testing for License related to 'LILBURN POLICE DEPARTMENT' 
     */
    private static testMethod void testBatchForLilburnPoliceDepartiment() {
    	Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
    	Account policeDept = new Account(Name = 'LILBURN POLICE DEPARTMENT', 
    								     BillingPostalCode = '7410', 
    								     RecordTypeId = policeDepartmentRecordTypeId);
        insert policeDept;
        
        List<License__c> lstlicenses = new List<License__c>();
        lstlicenses.add(buildLicense('Permitted','Residential', policeDept.Id,System.Today().addDays(-325)));
        lstlicenses.add(buildLicense('Permitted','Residential', policeDept.Id, System.Today().addDays(-325)));
        insert lstlicenses;
        
        // On License there is trigger which insert "Invoic" and "Invoice Line Item" records, so need to delete those
        delete [SELECT Id FROM Invoice__c WHERE License__c IN :lstlicenses];
        
        List<Invoice__c> listInvoices = new List<Invoice__c>();        
        for(License__c license: lstlicenses){
            listInvoices.add(new Invoice__c(Type__c = 'Test',
            				     Permit_Billing_Year__c = String.ValueOf(System.today().addYears(-1).year()),
            				     License__c= license.Id));           
        }
        insert listInvoices;
        
        Test.startTest();
        Database.executeBatch(new LicenseRenewalBatch());    
        Test.stopTest();

		Integer count = [SELECT COUNT() FROM Invoice_Line_Item__c WHERE Invoice__c IN :listInvoices];
		System.assertEquals(0, count);      
    }
           
    public static Date getTodayDate() {
    	return todayDate != null ? todayDate : System.today();
    }
    
    public static void setTodayDate(Date dateValue) {
    	todayDate = dateValue;
    }
}
/**
 * Test class for following
 *  1] BillingActivityTrigger.tgr
 *  2] BillingActivityTriggerHandler.cls
 * @author Mahesh G.
 * @createdDate 2016-09-23
 * RequestId    ModifiedDate   Description
 *  APS-379      2016-09-23	    Initial Development
 */
@IsTest
private class BillingActivityTriggerHandlerTest {    
    private static License__c buildLicense(String status, String type, Id policeDeptId, Date oasisDate) {
		return new License__c(
			License_Status__c = status,
			License_Type__c = type,
			Police_Department__c = policeDeptId,
			Permit_Date_OASIS__c = oasisDate	
		);
	}
    
    private static Invoice__c buildInvoice(Id licenseId, String status) {
        return new Invoice__c(
            License__c = licenseId,
            Status__c = status
        );
    }
    
    private static Invoice_Line_Item__c buildInvoiceLineItem(Id invoiceId) {
        return new Invoice_Line_Item__c(
            Invoice__c = invoiceId
        );
    }
    
    private static Billing_Activity__c buildBillingAcitivity(Id licenseId, Decimal amount) {
        return new Billing_Activity__c(
            License__c = licenseId,
            Amount__c = amount
        );
    }
    
    private static testMethod void testPayLicenseFirstInvoice() {
        final Integer MAX_RECORD_SIZE = 5;
        Id policeDepartmentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        
        Account accounttest = new Account(Name='testAcc', BillingPostalCode='3256', RecordTypeId = policeDepartmentRecordTypeId);
        insert accounttest;
        
        // Insert License records
        List<License__c> listLicense = new List<License__c>();        
        for(Integer index = 0; index < MAX_RECORD_SIZE; index++) {
            listLicense.add(buildLicense('Permitted','Residential', accounttest.Id,System.Today().addDays(index)));
        }
        insert listLicense;
        
        // Insert Invoice records
        List<Invoice__c> listInvoice = new List<Invoice__c>();
        for(Integer index = 0; index < MAX_RECORD_SIZE; index++) {
            listInvoice.add(buildInvoice(listLicense[index].Id, 'Permit'));
        }
        insert listInvoice;
        
        // Insert "Invoice Line Item" records
        List<Invoice_Line_Item__c> listILI = new List<Invoice_Line_Item__c>();
        for(Integer index = 0; index < MAX_RECORD_SIZE; index++) {
            listILI.add(buildInvoiceLineItem(listInvoice[index].Id));
        }
        insert listILI;        
        
        Test.startTest();
        
        // Insert "Billing Acitivity" for License records
        List<Billing_Activity__c> listBllingAcitivity = new List<Billing_Activity__c>();
        Map<Id, Decimal> mapExpLicenseIdToAmountPaid = new Map<Id, Decimal>();
        for(Integer index = 0; index < MAX_RECORD_SIZE; index++) {
            Decimal amountPaid = index + 10;
            listBllingAcitivity.add(buildBillingAcitivity(listLicense[index].Id, amountPaid));
            mapExpLicenseIdToAmountPaid.put(listLicense[index].Id, amountPaid);
        }        
        insert listBllingAcitivity;
        
        Test.stopTest();
        
        Set<Id> setInvoiceId = new Set<Id>();
        for(License__c license : [SELECT (SELECT Id FROM Invoices__r 
                                 WHERE Type__c = 'Permit' 
                                 ORDER BY CreatedDate LIMIT 1)
                          FROM License__c WHERE Id IN :listLicense 
                          	AND Number_of_Billing_Activities__c = 1]) {
			if(license.Invoices__r.isEmpty()) { continue; }
            setInvoiceId.add(license.Invoices__r[0].Id);
        }
        
        for(Invoice__c invoice : [SELECT Id, License__c,
                                      (SELECT Id, Amount_Paid__c FROM Invoice_Line_Items__r 
                                       ORDER BY CreatedDate LIMIT 1)
                                  FROM Invoice__c
                                  WHERE Id IN :setInvoiceId]) {
			if(invoice.Invoice_Line_Items__r.isEmpty()) { continue; }
                                      
			System.assertEquals(mapExpLicenseIdToAmountPaid.get(invoice.License__c), 
                                	invoice.Invoice_Line_Items__r[0].Amount_Paid__c);
		}        
    }
}
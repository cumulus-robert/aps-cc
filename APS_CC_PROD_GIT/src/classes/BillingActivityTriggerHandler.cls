/**
 * @Business: Trigger handler class for BillingActivityTrigger
 * @Date: 2016-09-21
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-379   2016-09-23	    Initial Development
 * APS-394   2016-09-26     bug fix - set processed to true on records process
 * APS-396   2016-10-04     split payment up if payment is larger than an unpaid permit invoice. leave remainder of payment to flow through daily payment processing job.
*/
public class BillingActivityTriggerHandler {
	public Boolean isBefore;
    public Boolean isAfter;
    public Boolean isInsert;
    public Boolean isUpdate;
    public Boolean isDelete;
    public Boolean isUndelete;
    public List<Billing_Activity__c> listOldBA;
    public List<Billing_Activity__c> listNewBA;
    public Map<Id, Billing_Activity__c> mapOldBA;
    public Map<Id, Billing_Activity__c> mapNewBA;
    
    public void process() {
        if(isAfter) {
            if(isInsert) {
                doAfterInsertProcessing();
            }
        }
    }
    
    private void doAfterInsertProcessing() {
        // APS-379
        payLicenseFirstInvoice(listNewBA);
    }
    
    private void payLicenseFirstInvoice(List<Billing_Activity__c> listBillingActivity) {
        Set<Id> setLicenseId = new Set<Id>();
        // Build set of License Id
        for(Billing_Activity__c ba : listBillingActivity) {
            setLicenseId.add(ba.License__c);
        }
        System.debug('\n setLicenseId:' + JSON.serialize(setLicenseId));

        if(!System.isBatch() && !System.isFuture()) {
        	payLicenseFirstInvoice(setLicenseId);
        }
    }
    
    @Future
    private static void payLicenseFirstInvoice(Set<Id> setLicenseId) {
        Set<Id> setInvoiceId = new Set<Id>();
        Map<Id, Billing_Activity__c> mapLicenseIdToBillActvity = new Map<Id, Billing_Activity__c>();
        List<Billing_Activity__c> listBAToUpsert = new List<Billing_Activity__c>();
        
		// Build set of Invoice having type = "Permit" and its License has only
		// one "Billing Activity".
		List<License__c> license = [SELECT Id, 
                                      (SELECT Id FROM Invoices__r 
                                       WHERE Type__c = 'Permit' 
                                       ORDER BY CreatedDate LIMIT 1),
                                  	  (SELECT Id, Amount__c FROM Billing_Activities__r),
                                  	  Number_of_Billing_Activities__c
                                   FROM License__c
                                   WHERE Id IN :setLicenseId 
                                       AND Number_of_Billing_Activities__c = 1];        
        for(License__c x : license) {
			// If License has at least one Invoice record having type = "Permit" and
			// there is only one "Billing Activity" record then build map of LicenseId to
			// Amount of that "Billing Activity" record
        	if(!x.Invoices__r.isEmpty() 
            		&& x.Billing_Activities__r.size() == 1) {
                setInvoiceId.add(x.Invoices__r[0].Id);
                mapLicenseIdToBillActvity.put(x.Id, x.Billing_Activities__r[0]);
            }
		}
        System.debug('\n setInvoiceId:' + JSON.serialize(setInvoiceId)
                     + '\n mapLicenseIdToBillActvity:' + JSON.serialize(mapLicenseIdToBillActvity));
		
        List<Invoice_Line_Item__c> listILIToPay = new List<Invoice_Line_Item__c>();
        for(Invoice__c invoice : [SELECT Id, License__c, Amount_Due__c,
                                      (SELECT Id FROM Invoice_Line_Items__r 
                                       ORDER BY CreatedDate LIMIT 1)
                                  FROM Invoice__c
                                  WHERE Id IN :setInvoiceId]) {
			Id licenseId = invoice.License__c;
			if(invoice.Invoice_Line_Items__r.isEmpty() 
            		|| !mapLicenseIdToBillActvity.containsKey(licenseId)) { continue; }
			Billing_Activity__c ba = mapLicenseIdToBillActvity.get(licenseId);
			Decimal baAmount = ba.Amount__c;
			Decimal amountToPay = invoice.Amount_Due__c != null ? invoice.Amount_Due__c : 0;
						
			Decimal finalAmount;              
			if(baAmount - amountToPay > 0 ) {                    
            	Billing_Activity__c newBA = new Billing_Activity__c(License__c = licenseId,
                                                                    Amount__c = baAmount - amountToPay,
                                                                    Processed__c = false);
                listBAToUpsert.add(newBA);
                
                newBA = new Billing_Activity__c(Id = ba.Id, 
                                                Amount__c = amountToPay,
                                                Processed__c = true);
                listBAToUpsert.add(newBA);
                
                finalAmount = invoice.Amount_Due__c;                                        
            } else {
                finalAmount = baAmount;
                
                Billing_Activity__c newBA = new Billing_Activity__c(Id = ba.Id, Processed__c = true);
                listBAToUpsert.add(newBA);
            }
                
			invoice.Invoice_Line_Items__r[0].Amount_Paid__c = finalAmount;
            listILIToPay.add(invoice.Invoice_Line_Items__r[0]);
		}
        System.debug('\n listILIToPay:' + JSON.serialize(listILIToPay));
        if(listILIToPay.isEmpty()) { return; }
        
        try {
            Database.SaveResult[] saveResults = Database.update(listILIToPay, false);
            BillingActivityTriggerHandler.logDBUpdateErrors(saveResults, listILIToPay);

            upsert listBAToUpsert;
        } catch(Exception ex) {
            System.debug('\n Error:' + ex.getMessage() + '\n Stack Trace:' + ex.getStackTraceString());
        }
    }
    
    /**
     * Log Errors of Database.update() operation
     * Error format: <sobject_record_id>|<database_update_error_message>
     * @param saveResults: Result of Database.update() operation
     * @param listRecordToUpdate: List of records used in Database.update() operation
     */
    public static void logDBUpdateErrors(Database.SaveResult[] saveResults, List<SObject> listRecordToUpdate) {
        List<String> listError = new List<String>();
        for(Integer index = 0; index < saveResults.size(); index++) {
            Database.SaveResult sr = saveResults[index];
            if(sr.success) { continue; }
            
            listError.add(listRecordToUpdate[index].Id + '|' + sr.errors[0].message);
        }
        
        if(!listError.isEmpty()) {
            System.debug('\n listError:' + String.join(listError, '\n'));
        }
    }
}
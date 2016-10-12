/**
 * @Business: InvoiceLineItem Trigger Handling
 * @Date: 2016-05-17
 * @Author: Cumulus Vision
 * @Request: APS-313
 * Modified  ModifiedDate   Description
 * APS-313   2016-05-17     delete any new invoice created @ $235. then set related license to unmatched.
 * APS-348   2016-08-10     set fee amount based on matching fee schedule record
*/
public class InvoiceLineItemTriggerHandler {
	public InvoiceLineItemTriggerHandler() {
		
	}
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,Invoice_Line_Item__c> oldMap {get; set;}
    public List<Invoice_Line_Item__c> NewI { get; set; }
    public List<Invoice_Line_Item__c> OldI { get; set; }

    public void process() {

        if (isBefore && isInsert) {
        	//APS-348
            setFee();
        	
        }if (IsAfter && IsInsert) {

            //unmatchedProcess();
            
        }

    }
    //APS-313
    private void unmatchedProcess() {

        List<Invoice_Line_Item__c> invoiceLineItemsFiltered = new List<Invoice_Line_Item__c>();

        // filter to collect only invoice line item has fee amount equal 235
        for (Invoice_Line_Item__c il : NewI) {

            if (il.Fee_Amount__c == 235) invoiceLineItemsFiltered.add(il);            
        }

        List<License__c> licensesUpdate = new List<License__c>();

        if (!invoiceLineItemsFiltered.isEmpty()) {

            for (Invoice_Line_Item__c ili : [SELECT Invoice__r.License__c, Invoice__c, Id FROM Invoice_Line_Item__c WHERE Id IN :invoiceLineItemsFiltered]) {              
                 licensesUpdate.add(new License__c(Id=ili.Invoice__r.License__c, Unmatched__c = true));
            }

            // update unmatched field on license to true
            UPDATE licensesUpdate;

            // delete invoice and invoice line item of license unmatched
            DELETE [SELECT Id FROM Invoice__c WHERE License__c IN :licensesUpdate];
        }
    }
    //APS-348
    private void setFee() {
    	set<id> invoice_set = new set<id>();
    	for (Invoice_Line_Item__c x : newI) {
    		invoice_set.add(x.Invoice__c);
    	}
    	List<Invoice__c> i = [select id, License__r.Police_Department__c from Invoice__c where id in: invoice_set];
    	set<id> pd = new set<id>();
    	map<id,id> invoice_pd_map = new map<id,id>();
    	for (Invoice__c x : i) {
    		invoice_pd_map.put(x.id,x.License__r.Police_Department__c);    		
    	}
    	List<Fee_Schedule__c> fs = [select id, Police_Department__c, Type__c, Amount__c from Fee_Schedule__c where Police_Department__c in: invoice_pd_map.values()];
    	map<id,List<Fee_Schedule__c>> pd_fs_map = new map<id,List<Fee_Schedule__c>>();
    	system.debug(fs);
    	for (Fee_Schedule__c x : fs) {
    		if (pd_fs_map.get(x.Police_Department__c)==null) {
    			system.debug('Adding New Map');
    			List<Fee_Schedule__c> lstFs = new List<Fee_Schedule__c>();    			
    			lstFs.add(x);
    			pd_fs_map.put(x.Police_Department__c,lstFs);
    		} else {
    			system.debug('Adding To Existing Map');
    			List<Fee_Schedule__c> lstFs = pd_fs_map.get(x.Police_Department__c);    			
    			lstFs.add(x);
    			pd_fs_map.put(x.Police_Department__c,lstFs);
    		}
    	}
    	for (Invoice_Line_Item__c x : newI) {
    		system.debug('Updating Fee');
    		List<Fee_Schedule__c> lstFS = pd_fs_map.get(invoice_pd_map.get(x.Invoice__c));
            lstFS = lstFS != null ? lstFS : new List<Fee_Schedule__c>();
    		system.debug(lstFS.size());
    		for (Fee_Schedule__c x1 : lstFS) {
    			system.debug(x1.Type__c);
    			system.debug(x.Item__c);
    			if (x.Item__c == x1.Type__c) {
    				x.Fee_Amount__c = x1.Amount__c;
    			}
    		}
    	}    	
    }
}
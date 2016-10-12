/**
 * @Business: Invoice Trigger Handling
 * @Date: 2016-09-21
 * @Author: Cumulus Vision
 * @Request: APS-390
 * Modified  ModifiedDate   Description
*/
public class InvoiceTriggerHandler {
	public InvoiceTriggerHandler() {
		
	}
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,Invoice__c> oldMap {get; set;}
    public List<Invoice__c> NewI { get; set; }
    public List<Invoice__c> OldI { get; set; }

    public void process() {
    	set<id> permitted_set = new set<id>();
    	string permitBillingThisYear = string.valueOf(system.today().year());
    	if (isAfter && isUpdate) {
    		for (Invoice__c x : NewI) {
    			if (x.Type__c == 'Permit' && x.Status__c == 'Paid' && oldmap.get(x.id).Status__c != x.Status__c && x.Permit_Billing_Year__c == permitBillingThisYear) {
    				permitted_set.add(x.id);
    			}
    		}
    	}
    	if (!permitted_set.isEmpty()) {
    		handlePermitted(permitted_set);
    	}
    }
    private void handlePermitted(set<id> permitted_set) {
    	
    	List<Invoice__c> i = [select id, License__c from Invoice__c where id in: permitted_set];
    	set<id> license_Set = new set<id>();
    	for (Invoice__c x : i){
    		license_set.add(x.License__c);
    	}
    	List<License__c> l = [select id, Permit_Date_OASIS__c, Permit_Added__c, License_Status__c from License__c where id in: license_set];
    	for (License__c x : l) {
    		if (x.Permit_Date_OASIS__c == null) {
    			x.Permit_Date_OASIS__c = system.now();
    			x.Permit_Added__c = system.now();
    			x.License_Status__c = 'Permitted';    			
    		} else {
    			dateTime newPermitDate = dateTime.newInstance(system.today().year(),x.Permit_Date_OASIS__c.month(),x.Permit_Date_OASIS__c.day(),x.Permit_Date_OASIS__c.hour(),x.Permit_Date_OASIS__c.minute(),x.Permit_Date_OASIS__c.second()); 
    			x.Permit_Date_OASIS__c = newPermitDate;
    			x.License_Status__c = 'Permitted';
    		}
    	}
    	update l;
    }
}
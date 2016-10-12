/**
 * @Business: OasisActivityBatch Trigger Handling
 * @Date: 2016-04-04
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-378   2016-09-17     Updated to account for invoice name change to auto number
*/
public class OasisActivityBatchTriggerHandler {
    public OasisActivityBatchTriggerHandler() {
        
    }
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,OASIS_Activity_Batch__c> oldMap {get; set;}
    public List<OASIS_Activity_Batch__c> NewO { get; set; }
    public List<OASIS_Activity_Batch__c> OldO { get; set; }

    public void process() {
        List<Invoice_Line_Item__c> newIli = new List<Invoice_Line_Item__c>();

        if (isAfter && isInsert) {
            //get all raw feed ids for false alarms
            //set<string> fa_raw_set = new set<string>();
            map<string,string> fee_amt_map = new map<string,string>();
            map<string,string> raw_feed_map = new map<string,string>();
            map<string,string> invoiceType_map = new map<string,string>();
            map<string,string> invoiceNote_map = new map<string,string>();
            map<string,string> license_map = new map<string,string>();

            for (OASIS_Activity_Batch__c x : NewO) {
                fee_amt_map.put(x.BillingActivityId__c,x.Amount__c);
                invoiceType_map.put(x.BillingActivityId__c,x.Item__c);
                invoiceNote_map.put(x.BillingActivityId__c,x.Billing_Note__c);
                license_map.put(x.BillingActivityId__c,x.License__c);
                if (x.RawDataId__c != null) {
                    raw_feed_map.put(x.BillingActivityId__c,x.RawDataId__c);
                }
            }
            //List<License__c> llookup = [select id from License__c where id in : license_map.values()];
            List<Invoice__c> openInvoices = [select id, Invoice_Date__c from Invoice__c where Status__c != 'Paid' and License__c in : license_map.values() order by Invoice_Date__c DESC];
            //get a map of any related false alarms
            List<False_Alarm__c> falookup = [select id, FeedId__c from False_Alarm__c where FeedId__c in :raw_feed_map.values()];
            map<string,id> fa_map = new map<string,id>();
            for (False_Alarm__c x : falookup) {
                fa_map.put(x.FeedId__c,x.id);
            }

            List<Invoice__c> newInvoice = new List<Invoice__c>();
            List<Billing_Activity__c> newBillingActivity = new List<Billing_Activity__c>();
            //do more work
            for (OASIS_Activity_Batch__c x : NewO) {
                //create false alarm invoices
                //set up invoice name                    
                string invoiceNumber;
                string invoiceYear;
                string invoiceName;
                if (x.BillingActivityId__c != null && x.ActivityDate__c != null) {
                    invoiceNumber = x.BillingActivityId__c;
                    invoiceYear = string.valueOf(x.ActivityDate__c.year()).right(2);
                    invoiceName = 'INV-' + invoiceYear + '-'+ invoiceNumber;
                }
                //create invoice
                //add false alarm invoices                
                if (x.ActivityType__c == '1') {                    
                    Invoice__c i = new Invoice__c();
                    i.License__c = x.License__c;
                    i.OASIS_BillingActivityId__c = x.BillingActivityId__c;
                    //i.Name = invoiceName;
                    i.Invoice_Date__c = date.valueOf(x.ActivityDate__c);
                    i.Type__c = x.Item__c;
                    newInvoice.add(i);
                } 
                //add permit bills                
                else if (x.ActivityType__c == '10' || x.ActivityType__c == '11' ) {
                    Invoice__c i = new Invoice__c();
                    i.License__c = x.License__c;
                    i.OASIS_BillingActivityId__c = x.BillingActivityId__c;
                    //i.Name = invoiceName;
                    i.Invoice_Date__c = date.valueOf(x.ActivityDate__c);
                    i.Permit_Billing_Year__c = string.valueOf(x.ActivityDate__c.year());
                    i.Type__c = 'Permit';
                    i.Note__c = x.Billing_Note__c;
                    newInvoice.add(i);
                }
                //add late fee
                else if (x.ActivityType__c == '22' || x.ActivityType__c == '5' ) {
                    for (Invoice__c x1 : openInvoices) {
                        system.debug(x.ActivityDate__c);
                        system.debug(x1.Invoice_Date__c);
                        if (x.ActivityDate__c > x1.Invoice_Date__c) {
                            newIli.add(new Invoice_Line_Item__c(Invoice__c=x1.id,Item__c='Penalty',Item_Type__c='Late Fee Legacy',Fee_Amount__c=integer.valueOf(fee_amt_map.get(x.BillingActivityId__c))));
                            break;
                        }
                    }
                }
                //add returned check
                else if (x.ActivityType__c == '20') {
                    for (Invoice__c x1 : openInvoices) {
                        system.debug(x.ActivityDate__c);
                        system.debug(x1.Invoice_Date__c);
                        if (x.ActivityDate__c > x1.Invoice_Date__c) {
                            newIli.add(new Invoice_Line_Item__c(Invoice__c=x1.id,Item__c='Penalty',Item_Type__c='Returned Check Fee Legacy',Fee_Amount__c=integer.valueOf(fee_amt_map.get(x.BillingActivityId__c))));
                            break;
                        }
                    }
                }
                //add misc charge
                else if (x.ActivityType__c == '13') {
                    for (Invoice__c x1 : openInvoices) {
                        system.debug(x.ActivityDate__c);
                        system.debug(x1.Invoice_Date__c);
                        if (x.ActivityDate__c > x1.Invoice_Date__c) {
                            newIli.add(new Invoice_Line_Item__c(Invoice__c=x1.id,Item__c='Other',Item_Type__c='Misc Charge Legacy',Fee_Amount__c=decimal.valueOf(fee_amt_map.get(x.BillingActivityId__c))));
                            break;
                        }
                    }
                }
                //add credits
                else if (x.ActivityType__c == '17' || 
                            x.ActivityType__c == '14' || 
                            x.ActivityType__c == '18' ||
                            x.ActivityType__c == '2' ||
                            x.ActivityType__c == '15' ||
                            x.ActivityType__c == '16' ||
                            x.ActivityType__c == '4' ||
                            x.ActivityType__c == '3' ||
                            x.ActivityType__c == '9' ||
                            x.ActivityType__c == '8' ||
                            x.ActivityType__c == '21' ||
                            x.ActivityType__c == '6' ||
                            x.ActivityType__c == '12' //manual credit
                        ) {

                    string type;
                    //alarm school credit = 8
                    //manual credit = 9,12
                    if (x.ActivityType__c == '12' || x.ActivityType__c == '9' || x.ActivityType__c == '8') {
                        type = 'Manual Credit Legacy';
                    } else {
                        type = 'Payment Legacy';
                    }
                    newBillingActivity.add(new Billing_Activity__c(License__c=x.License__c,Type__c=type,Amount__c=decimal.valueOf(x.Amount__c),Note__c=x.Billing_Note__c));
                }
            }
            if (!newInvoice.isEmpty()) {
                insert newInvoice;
                List<Invoice__c> ilookup = [select id, Type__c, OASIS_BillingActivityId__c from Invoice__c where id in: newInvoice];                
                for (Invoice__c x : ilookup) {
                    Invoice_Line_Item__c ili = new Invoice_Line_Item__c();
                    ili.Invoice__c = x.id;
                    ili.Fee_Amount__c = decimal.valueOf(fee_amt_map.get(x.OASIS_BillingActivityId__c));
                    ili.Note__c = invoiceNote_map.get(x.OASIS_BillingActivityId__c);
                    ili.Item_Type__c = invoiceType_map.get(x.OASIS_BillingActivityId__c) + ' Legacy';
                    if (fee_amt_map.get(x.OASIS_BillingActivityId__c) != null && x.Type__c == 'False Alarm') {
                        ili.Item__c = 'False Alarm';
                        ili.False_Alarm__c = fa_map.get(raw_feed_map.get(x.OASIS_BillingActivityId__c));
                        newIli.add(ili);
                    } else if (fee_amt_map.get(x.OASIS_BillingActivityId__c) != null && x.Type__c == 'Permit') {
                        ili.Item__c = 'Permit';
                        newIli.add(ili);
                    }
                }
                
            }
            if (!newIli.isEmpty()) {
                insert newIli;
            }
            if (!newBillingActivity.isEmpty()) {
                insert newBillingActivity;
            }
        }
    }
    

}
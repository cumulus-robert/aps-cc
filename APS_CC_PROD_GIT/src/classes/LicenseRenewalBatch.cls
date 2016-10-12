/**
 * @Business: License Renewal Billing
 * @Date: 2016-05-16
 * @Author: Cumulus Vision
 * @Request: APS-325
 * Modified  ModifiedDate   Description
 * APS-342   2016-08-25     modify logic to be a reference of permit date is less than 320 days from today.
 * APS-359   2016-09-13     Create Invoice_Line_Item records for License related to "PARADISE POLICE DEPARTMENT"
 *							account if the job is running in July month    
 * APS-360   2016-09-13     Exculde Licenses related to "LILBURN POLICE DEPARTMENT" account
*/
global class LicenseRenewalBatch implements Database.Batchable<sObject> {
    
    private String strCurrentYear = String.ValueOf(System.Today().year());
        
    // @description get Permitted license with a permit date less than today and there unpaid invoice for previous year    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        // Get last year Value as String 
        String strLastYear = String.ValueOf(System.Today().year()-1);
        date d = system.today().addDays(45);
        // get unpaid and renewed invoices related to License 
        return Database.getQueryLocator ([SELECT Id, Police_Department__r.Name,
        								            (SELECT Id, Status__c, 
                                                     Credit_Notes__c, Type__c, Closed__c, Permit_Billing_Year__c  
                                                     FROM Invoices__r 
                                                     WHERE ( 
                                                         Permit_Billing_Year__c =:strLastYear 
                                                         AND Closed__c = false
                                                     ) 
                                                     OR (Type__c = 'Permit' 
                                                         AND Permit_Billing_Year__c =:strCurrentYear ))
                                          FROM License__c
                                          WHERE (Permit_Expiration_Date__c <=: d OR Permit_Expiration_Date__c = null)
                                          AND License_Status__c IN ('Unpermitted', 'Permitted') 
                                              AND Police_Department__r.Name != 'LILBURN POLICE DEPARTMENT']);
        
    }        
    
    // @description  manage the license status and renewal invoice for all permitted licenses with a permited date    
    global void execute(Database.BatchableContext BC, List<License__c> listLicensesToManage) {
        if(!listLicensesToManage.isEmpty()) {
            String strRenewalinvoiceType = 'Permit';
            
            // set string varibles to set expired invoices Values and for which renewal Invoice will be created 
            String strCreditNote = 'Automatically cancelled in Permit renewal job. New Invoice created for current permit billing year';            
            String strStatusToUpdaeForUnpaidInvoice = 'Cancelled';                  
            boolean isRenewationRequired = false;
            
            // list to hold new updated invoices that are expired now
            List<Invoice__c>listUpdatedInvoices = new List<Invoice__c>(); 
            
            List<Invoice__c>listTempUpdatedInvoices = new List<Invoice__c>(); // list to hold temp. updaetd invoices 
            
            
            // Filter out Licenses of which Police_Department = "PARADISE POLICE DEPARTMENT" 
            // and current month is not "July"
            Date todayDate = Test.isRunningTest() ? LicenseRenewalBatchTest.getTodayDate() : System.today();
            System.debug('Today Date:' + todayDate);
            if(todayDate.month() != 7) {        
            	final String PARADISE_PD = 'PARADISE POLICE DEPARTMENT';    
            	Integer index = 0;
	            while(index < listLicensesToManage.size()) {
	            	if(listLicensesToManage[index].Police_Department__r.Name == PARADISE_PD) {
	            		listLicensesToManage.remove(index);
	            	} else {
	            		index++;
	            	}
	            } 
            }
            
            system.debug(listLicensesToManage);
            // list to hold new renewed invoices   
            List<Invoice__c>listRenewedInvoices = new List<Invoice__c>();
            for(License__c licenseToManage :listLicensesToManage) {
                isRenewationRequired = true;
                listTempUpdatedInvoices = new List<Invoice__c>();
                system.debug(licenseToManage);
                if(!licenseToManage.Invoices__r.isEmpty()) {
                    for(Invoice__c invoiceToUpdate : licenseToManage.Invoices__r) {                 
                        
                        // If Renewal invoice type exist then do not update and do not create new invoice else update invoices                        
                        if(strRenewalinvoiceType.equalsIgnoreCase(invoiceToUpdate.Type__c)
                           && strCurrentYear.equalsIgnoreCase(invoiceToUpdate.Permit_Billing_Year__c)) {
                            // no need to create invoice                           
                            isRenewationRequired = false;
                            system.debug('breaking ...');
                            system.debug(invoiceToUpdate);
                            break;
                        } else 
                        {
                            if(!((strStatusToUpdaeForUnpaidInvoice.equalsIgnoreCase(invoiceToUpdate.Status__c))
                                 && (strCreditNote.equalsIgnoreCase(invoiceToUpdate.Credit_Notes__c))
                                 && (invoiceToUpdate.Closed__c == false)
                                 )) 
                            { 
                                invoiceToUpdate.Status__c = strStatusToUpdaeForUnpaidInvoice;  
                                invoiceToUpdate.Credit_Notes__c = strCreditNote; 
                                listTempUpdatedInvoices.add(invoiceToUpdate);
                            }
                        }
                    }
                    
                    // If unpaid and Open invoice exist for licence then create renewal Invoice for this year if renewation is not done
                    if(isRenewationRequired) {
                        system.debug('adding invoice ...');
                        // creaete new renewal Invoice                      
                        listRenewedInvoices.add( new Invoice__c(Type__c = strRenewalinvoiceType, 
                                                                Permit_Billing_Year__c = strCurrentYear, License__c= licenseToManage.Id, Invoice_Date__c = system.today()));                        
                        // update expired invoices if renewation licence is not done 
                        if(!listTempUpdatedInvoices.isEmpty()) {
                            listUpdatedInvoices.addAll(listTempUpdatedInvoices );
                        }
                        
                    }
                } else {
                	//create permit invoice for current billing year since no permit invoice was found
                	listRenewedInvoices.add( new Invoice__c(Type__c = strRenewalinvoiceType, 
                                                                Permit_Billing_Year__c = strCurrentYear, License__c= licenseToManage.Id,Invoice_Date__c = system.today()));
                }                                
            }
            
            if(!listUpdatedInvoices.isEmpty()) {
                try {
                    
                    // update Invoice that are cancelled 
                    database.update(listUpdatedInvoices,false);
                }catch(Exception ex){
                    system.debug('Error: ' + ex.getStackTraceString() );
                }
                
            }
            
            if(!listRenewedInvoices.isEmpty()) {     
                Database.SaveResult[] srRenewedInvoiceList;
                try {                         
                    // create new Invoices for licences
                    srRenewedInvoiceList = database.insert(listRenewedInvoices);
                }catch(Exception ex){
                    system.debug('Error: ' + ex.getStackTraceString() );
                }
                
                // list to store invoice line items for new Invoices 
                List<Invoice_Line_Item__c>listInvoiveLineItems = new List<Invoice_Line_Item__c>();
                for(Database.SaveResult srRenewedInvoice : srRenewedInvoiceList) {
                    if (srRenewedInvoice.isSuccess()) {

                        //  create Invoice line Item 
                        listInvoiveLineItems.add(new Invoice_Line_Item__c(Invoice__c = srRenewedInvoice.getId(), 
                            Item__c = 'Renewal Permit', Item_Type__c = 'Permit' ));
                    }

                }
                
                if(!listInvoiveLineItems .isEmpty()) {  
                    try {                         
                        // insert new Invoice line Item 
                        srRenewedInvoiceList = database.insert(listInvoiveLineItems );
                    }catch(Exception ex){
                        system.debug('Error: ' + ex.getStackTraceString() );
                    }                
                }
            }
        }
        
    }
    
    //  @description finish batch    
    global void finish(Database.BatchableContext BC) {
        system.debug('Sucessfully updated licenses status and completed renewal of invoices');        
    } 
}
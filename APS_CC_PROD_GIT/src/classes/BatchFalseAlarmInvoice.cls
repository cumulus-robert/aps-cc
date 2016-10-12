/**
 * @Business: Batch job which builds false alarm invoices
 * @Date: 2016-04-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-257   2016-04-19     Initial Deployment
 * APS-309   2016-05-19		Modified False_Alarm__c query criteria
 * APS-353   2016-08-19     Update False_Alarm record count in item__c field value based on
 *                          License__r.Police_Department__r.Max_False_Alarms__c field
 * APS-354   2016-08-19     Add Licnese's License_Type__c field value for Item__c field of
 *                          Invoice_Line_Item record insert if False_Alarm record meet with
 *                          following criteria
 *                          License__r.Police_Department__r.Name = "HUNTSVILLE POLICE DEPARTMENT"
 * APS-372   2016-09-05     Exclude False_Alarm records related to Unmatched Licneses i.e. License which
 *                          are related to Police_Department(Account) using field Unmatched_License__c of
 *                          Account.
*/
global with sharing class BatchFalseAlarmInvoice implements Database.Batchable<sObject>{
    
    static final String TYPE = 'False Alarm';
    static final String STATUS = 'Draft';
    private Boolean isFromPage;
    public String nextBatchJobId;
    
    global String  query = 'SELECT Name, License__r.License_Status__c, Event_Date_Time__c,'
        				   + ' LastModifiedDate, False_Alarm_Count__c,'
        				   + ' License__c, License__r.License_Type__c,' 
        				   + ' License__r.Police_Department__r.Max_False_Alarms__c, '
                           + ' License__r.Police_Department__r.Name'
                           + ' From False_Alarm__c'
        				   + ' WHERE License__r.License_Status__c IN: licensestatus'
        				   + ' AND License__r.Name != \'00-000000\''
                           + ' AND License__c NOT IN (SELECT Unmatched_License__c FROM Account WHERE Unmatched_License__c != null)'
                           + ' AND False_Alarm_Count__c != null';
    
    public static Set<String> licensestatus = new Set<String> {'Permitted','Unpermitted'};
    
    global BatchFalseAlarmInvoice(){
        isFromPage = false;
    }
    global BatchFalseAlarmInvoice(Boolean isFromVFPage){
        isFromPage = isFromVFPage;
    }
        
    //start method
    global Database.Querylocator start(Database.BatchableContext BC){
        if(isFromPage) {            
            query += ' AND DAY_ONLY(Event_Date_Time__c) > 2016-09-01';
        }
        System.debug('\n query:' + query);
        return Database.getQueryLocator(query);
    }
    // Execute Logic
    global void execute(Database.BatchableContext BC, List<False_Alarm__c> scope){
        Map<ID,False_Alarm__c> mFA = new Map<ID,False_Alarm__c>();
        Map<id,String> license_status_map = new map<id,string>();
        Map<Id, Integer> mapPoliceDeptToMaxFalseAlarms = new Map<Id, Integer>();
		final String HUNTSVILLE_PD_NAME = 'HUNTSVILLE POLICE DEPARTMENT';
 
        // group false alarms by license.
        for(False_Alarm__c fa :scope){
            mFA.put(fa.Id,fa);
            license_status_map.put(fa.id,fa.License__r.License_Status__c);
            if(!mapPoliceDeptToMaxFalseAlarms.containsKey(fa.License__c)) {
                Decimal maxFalseAlarmCount =  fa.License__r.Police_Department__r.Max_False_Alarms__c;
                maxFalseAlarmCount = maxFalseAlarmCount != null ? maxFalseAlarmCount : 0;
            	mapPoliceDeptToMaxFalseAlarms.put(fa.License__c, (Integer)maxFalseAlarmCount);    
            }
        }
        system.debug('Found total of ' + mFA.size() + ' False Alarms to process.');
        //Load exists invoice line item
        Set<String> existInvoiceLineItem = new Set<String>();
        for(Invoice_Line_Item__c inl :[Select Id, False_Alarm__c from Invoice_Line_Item__c where False_Alarm__c in :mFA.keySet()]){
            existInvoiceLineItem.add(inl.False_Alarm__c);
        }
        system.debug(existInvoiceLineItem.size() + ' existing Invoice Line Items were found.');
                
        // create invoice 
        List<Invoice__c> lstInvoice = new List<Invoice__c>();
        set<id> license_set = new set<id>();
            
        List<InvoiceWrapper> lstInvoiceWrapper = new List<InvoiceWrapper>();    
        for(False_Alarm__c f :mFA.values()){
            system.debug('Processing False Alarms ... ');       

            if(existInvoiceLineItem.contains(f.Id)) continue;
                system.debug('Creating Invoice ... ');              
                Invoice__c i = new Invoice__c();
                i.License__c = f.License__c;
                license_set.add(f.License__c);
                i.Type__c = TYPE;
                i.Status__c = STATUS;
                i.False_Alarm_Event_Date_Time__c = f.Event_Date_Time__c;
                i.Invoice_Date__c = system.today();
                system.debug('Creating Invoice Line Items ...');
                List<Invoice_Line_Item__c> lstili = new List<Invoice_Line_Item__c>();                               
                // create line item for false alarm status is register 
                String licenseType = '';            	
                if(f.License__r.Police_Department__r.Name == HUNTSVILLE_PD_NAME) {
	                licenseType = f.License__r.License_Type__c != null ? f.License__r.License_Type__c : '';
    	        }
				
            	Integer num = Integer.valueOf(f.False_Alarm_Count__c);
                Integer maxFalseAlarmAllowed = mapPoliceDeptToMaxFalseAlarms.get(f.License__c);
            	String faCountForILI = (num <= maxFalseAlarmAllowed) 
                    				   ? String.valueOf(num) : (maxFalseAlarmAllowed + '+');
                
                String[] fillers = new String[] { licenseType, license_status_map.get(f.id), faCountForILI };
            	String item = String.format('{0} {1} False Alarm {2}', fillers);
				item = item.trim();                
                            	                
                //IF Invoice Line Item is created and Includes a lookup to False Alarm THEN update False Alarm.Invoice__c with related Invoice.                
                lstili.add(new Invoice_Line_Item__c(Invoice__c=i.Id, Item_Type__c='False Alarm', Item__c=item, False_Alarm__c=f.Id));
                system.debug('False Alarm: ' + f);
                system.debug('Invoice: ' + i);
                system.debug('Invoice Line Item: ' + lstili);
                lstInvoiceWrapper.add(new InvoiceWrapper(i, f, lstili));

                lstInvoice.add(i);      
        }
        if(!lstInvoice.isEmpty()){
            system.debug('Inserting Invoices ... ');
            insert lstInvoice;
            List<Invoice_Line_Item__c> invoiceitemlist = new List<Invoice_Line_Item__c>();
            set<id> falseAlarmsSet = new set<id>();
            system.debug('Linking Invoice Line Items to Invoices ...');
            for (InvoiceWrapper iw :lstInvoiceWrapper) {
                for(Invoice_Line_Item__c ili :iw.listili) {
                    ili.Invoice__c = iw.i.Id;
                    falseAlarmsSet.add(ili.False_Alarm__c);
                    invoiceitemlist.add(ili);
                }
            }
            if (!invoiceitemlist.isEmpty()) {
                system.debug('Inserting Invoice Line Items ... ');
                insert invoiceitemlist;
            }
        }   
    }
    global void finish(Database.BatchableContext BC){
        
    }
    
    class InvoiceWrapper {
        Invoice__c i;
        False_Alarm__c f;
        List<Invoice_Line_Item__c> listili;
        
        public InvoiceWrapper(Invoice__c i, False_Alarm__c f, List<Invoice_Line_Item__c> listili) {
            this.i = i;
            this.f = f;
            this.listili = listili;
        }
        
    }
}
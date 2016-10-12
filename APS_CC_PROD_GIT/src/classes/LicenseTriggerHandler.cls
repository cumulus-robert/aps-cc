/**
 * @Business: License Trigger Handling
 * @Date: 2016-04-15
 * @Author: Cumulus Vision
 * @Request: APS-264
 * Modified  ModifiedDate  Description
 * APS-277   2016-04-29    Added populateLicenseFields() function
 * 		     2016-05-05	   Modified logic in populateLicenseFields() function
 * APS-347   2016-08-09    Create Invoice & Invoice_Line_Item records on insert of License record
             2016-08-11    Added Permit Billing Year, Invoice Date to invoice created on license creation   
*/
public class LicenseTriggerHandler {
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,License__c> oldMap {get; set;}
    public List<License__c> NewL { get; set; }
    public List<License__c> OldL { get; set; }
    
    public LicenseTriggerHandler() {
        
    }
    
    public void process() {
        // Before Actions
        if(isBefore) {            
            // Before Insert Action
            beforeInsertProcessing();
            if(IsInsert) {
                
            }
        }
        
        // After Insert Actions
        if(isAfter && IsInsert) {
            afterInsertProcessing();
        }                      
    }
            
    private void afterInsertProcessing() {
        // Assoicate  "False Alarm" records to newly created License records
        associateFalseAlarmsToNewLicenses(newL);
        
        // APS-347
        insertInvoiceAndLineItems(newL);
    }
    
    private void beforeInsertProcessing() {
        // populate "License" fields 
        populateLicenseFields(newL);
    }
    
    private void associateFalseAlarmsToNewLicenses(List<License__c> listNewLicense) {
        // Filter newly inserted License records which having non-empty value for either of following fields
        // 1. Location_Address_1_OASIS__c
        // 2. Location_Address_2_OASIS__c
        Map<String, Id> mapAddressToLicenseId = new Map<String, Id>();
        for(License__c newLicense : listNewLicense) {
            if(String.isNotBlank(newLicense.Location_Address_1_OASIS__c) 
                    || String.isNotBlank(newLicense.Location_Address_2_OASIS__c)) {
                String address = String.isNotBlank(newLicense.Location_Address_1_OASIS__c)
                                 ? newLicense.Location_Address_1_OASIS__c 
                                 : newLicense.Location_Address_2_OASIS__c;
                mapAddressToLicenseId.put(address.toLowerCase(), newLicense.Id);                                        
            }
        }
        System.debug('\n mapAddressToLicenseId:' + JSON.serialize(mapAddressToLicenseId));
        
        try {
            // Fetch all "False Alarm" records having Location field value matching with 
            // License's Location fields and those are related to License having name "00-000000"
            List<False_Alarm__c> listFalseAlarms = [SELECT Id, Location__c FROM False_Alarm__c
                                                    WHERE Location__c IN :mapAddressToLicenseId.keySet()
                                                        AND Location__c != null
                                                        AND License__r.Name = '00-000000'];
            
            // Associate "False Alarm" record to new License record if match is found
            for(False_Alarm__c fa : listFalseAlarms) {
                String faLocation = fa.Location__c.toLowerCase();
                if(mapAddressToLicenseId.containsKey(faLocation)) {
                    fa.License__c = mapAddressToLicenseId.get(faLocation);
                        
                }
            }
            System.debug('\n listFalseAlarms:' + JSON.serialize(listFalseAlarms));
            
            update listFalseAlarms;
        } catch(Exception ex) {
            System.debug('\n Error in updating "False Alarm" record License field'
                         + '\n MSG:' + ex.getMessage() + '\n STACK TRACE:' + ex.getStackTraceString());
        }        
    }
    
    /*
        @Purpose : Populate fields of newly added license record.
        @Param   : List of license records
    */
    private void populateLicenseFields(List<License__c> listOfLicense){
        
        String strStreetTypes = 'ALY,ANX,ARC,AVE,BYU,BCH,BND,BLF,BLFS,BTM,BLVD,BR,BRG,BRK,BRKS,BG,BGS,BYP,CP,CYN,CPE,CSWY,CTR,CTRS,'+
                                'CIR,CIRS,CLF,CLFS,CLB,CMN,CMNS,COR,CORS,CRSE,CT,CTS,CV,CVS,CRK,CRES,CRST,XING,XRD,XRDS,CURV,DL,DM,DV,'+
                                'DR,DRS,EST,ESTS,EXPY,EXT,EXTS,FALL,FLS,FRY,FLD,FLDS,FLT,FLTS,FRD,FRDS,FRST,FRG,FRGS,FRK,FRKS,FT,FWY,'+
                                'GDN,GDNS,GTWY,GLN,GLNS,GRN,GRNS,GRV,GRVS,HBR,HBRS,HVN,HTS,HWY,HL,HLS,HOLW,INLT,IS,ISS,ISLE,JCT,JCTS,'+
                                'KY,KYS,KNL,KNLS,LK,LKS,LAND,LNDG,LN,LGT,LGTS,LF,LCK,LCKS,LDG,LOOP,MALL,MNR,MNRS,MDW,MDWS,MEWS,ML,MLS,'+
                                'MSN,MTWY,MT,MTN,MTNS,NCK,ORCH,OVAL,OPAS,PARK,PKWY,PASS,PSGE,PATH,PIKE,PNE,PNES,PL,PLN,PLNS,PLZ,PT,PTS,'+
                                'PRT,PRTS,PR,RADL,RAMP,RNCH,RPD,RPDS,RST,RDG,RDGS,RIV,RD,RDS,RTE,ROW,RUE,RUN,SHL,SHLS,SHR,SHRS,SKWY,SPG,'+
                                'SPGS,SPUR,SQ,SQS,STA,STRA,STRM,ST,STS,SMT,TER,TRWY,TRCE,TRAK,TRFY,TRL,TRLR,TUNL,TPKE,UPAS,UN,UNS,VLY,'+
                                'VLYS,VIA,VW,VWS,VLG,VLGS,VL,VIS,WALK,WALL,WAY,WAYS,WL,WLS';
                                
        Set<String> streetType = new Set<String>(strStreetTypes.split(','));                        
        List<License__c> listOfLicensesToUpdate = new List<License__c>();                                      
        for (License__c recordOfLicense : listOfLicense) {
            
            if (String.isBlank(recordOfLicense.Location_Address_1_OASIS__c)) { continue; }
            
            string [] addressSplit = recordOfLicense.Location_Address_1_OASIS__c.split(' ');
                
            if (addressSplit.size() == 3) {                    
                for (String strType : streetType) {
                    if (strType.trim() == addressSplit[2].trim()) {                     
                    	recordOfLicense.Location_Street_Number__c = addressSplit[0];
                    	recordOfLicense.Location_Street_Name__c = addressSplit[1];
                    	recordOfLicense.Location_Street_Type__c = addressSplit[2].toUppercase(); 
                    }
                }
            }
        }
    }
    
    /**
     * For each newly inserted License record, insert Invoice records and for that Invoice record
     * insert Invoice_Line_Item record.
     * @param listLicense: List of Licenses for which child records to create
     */
    private void insertInvoiceAndLineItems(List<License__c> listLicense) {
        List<Invoice__c> listInvoiceToAdd = new List<Invoice__c>();        
        for(License__c license : listLicense) {
            Invoice__c newInvoice = new Invoice__c(Type__c = 'Permit', License__c = license.Id, Invoice_Date__c=system.today(), Permit_Billing_Year__c = string.valueOf(system.today().year()));
            listInvoiceToAdd.add(newInvoice);
            
        }
        map<id,string> pdname_lic = new map<id,string>();
        map<id,string> licenseTypeMap = new map<id,string>();
        List<License__c> l = [select id, Police_Department__r.Name, License_Type__c from License__c where id in: listLicense];
        for(License__c x : l) {
        	pdname_lic.put(x.id, x.Police_Department__r.Name);
        	licenseTypeMap.put(x.id,x.License_Type__c);
        }

        Database.SaveResult[] saveResults = Database.insert(listInvoiceToAdd, false);
        map<id,id> license_inv_map = new map<id,id>();
        for (Invoice__c x : listInvoiceToAdd) {
        	license_inv_map.put(x.id,x.License__c);
        }
        List<String> listError = new List<String>();
        List<Invoice_Line_Item__c> listILI = new List<Invoice_Line_Item__c>();
        Integer index = 0;
        for(Database.SaveResult saveResult : saveResults) {
            if(saveResult.isSuccess()) {
                Invoice_Line_Item__c newILI = new Invoice_Line_Item__c();
                newILI.Item_Type__c =  'Permit';                
                newILI.Invoice__c = listInvoiceToAdd[index].Id;
                string pdName = pdname_lic.get(license_inv_map.get(listInvoiceToAdd[index].Id));
                system.debug(pdName);
                if (pdName == 'HUNTSVILLE POLICE DEPARTMENT' || pdName == 'PARADISE POLICE DEPARTMENT') {
                	newILI.Item__c = 'New Permit ' + licenseTypeMap.get(license_inv_map.get(listInvoiceToAdd[index].Id));
                } else {
                	newILI.Item__c = 'New Permit';	
                }
                
                listILI.add(newILI);
            } else {
                listError.add(listLicense[index].Id + '| Invoice record create failed | ' + saveResult.errors[0].message);
            }
            index++;
        }
        System.debug('\n Invoice insert error' + String.join(listError, '\n'));
        
        if(!listILI.isEmpty()) {
            saveResults = Database.insert(listILI, false);
            
            listError.clear();
            index = 0;
            for(Database.SaveResult saveResult : saveResults) {
                if(!saveResult.isSuccess()) {
                    listError.add(listILI[index].Invoice__c + '| Invoice Line Item Create falied |' + saveResult.errors[0].message);
                }
                index++;
            }
        }
        System.debug('\n Invoice_Line_Item insert error' + String.join(listError, '\n'));
    }
}
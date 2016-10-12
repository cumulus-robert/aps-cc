/*
 * @Business: Controller for New License Visualforce page
 * @Date: 2016-04-20
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-367   2016-09-07     1) Prepopulate following field of License if faId parameter is present in URL parameters: Field: [Police_Department__c, New_Location_Address__c, Location_Business_Name__c]
 * APS-378   2016-09-17     Updated to account for license name change to auto number
 * APS-393   2016-09-21     Updated to prefill Location type, city, state and zip if faId is present and to debug for when prefill is not working
 * 2016-10-11 AKH - Updated to prefill Contact name to Alarm Owner and to fill in Location Address 1 (legacy) and Location Address 2 (Legacy) for additional matching
*/
public class NewLicenseController {

    private final License__c l;
    private String falseAlarmId;
    public String theAlarmCompany { get; set; }
    public String thePD { get; set; }

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public NewLicenseController(ApexPages.StandardController stdController) {
        this.l = (License__c)stdController.getRecord();
        init();
    }
    
    public void init() {
        Map<String, String> mapURLparams = ApexPages.currentPage().getParameters();
        System.debug('\n mapURLparams:' + JSON.serialize(mapURLparams));
        
        // Logic specific to "fa" URL parameter     
        if(mapURLparams.containsKey('faId')) {          
            falseAlarmId = mapURLparams.get('faId');
            System.debug('FalseAlarmID:' + mapURLparams.get('faId'));
            
            List<False_Alarm__c> listFA = [SELECT Location__c, City__c, State__c, Location_Type__c, Location_Zip__c, Location_Business_Name__c,
                                               License__r.Police_Department__c 
                                           FROM False_Alarm__c 
                                           WHERE Id = :falseAlarmId];
            
            if(listFA.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Provided False Alarm not found.'));
            } else {
                this.l.Unmatched__c = true;
                this.l.New_Location_Address__c = listFA[0].Location__c;
                this.l.Location_Address_1_OASIS__c = listFA[0].Location__c;
                this.l.Location_Business_Name__c = listFA[0].Location_Business_Name__c;
                thePD = listFA[0].License__r.Police_Department__c; 
                //APS-393 - added by Amanda Howell 9-21-2016 for Type, City, State and Zip 
                this.l.License_Type__c = listFA[0].Location_Type__c;
                this.l.Location_City__c = listFA[0].City__c;
                this.l.Location_State__c = listFA[0].State__c;
                this.l.Location_Zip__c = listFA[0].Location_Zip__c;
            }                   
        }        
        System.debug('\n License with prepoulated values:' + JSON.serialize(this.l));                               
    }
    

    public List<SelectOption> getAlarmCompanies() {     
        string alarmCompany = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Alarm Company').getRecordTypeId();
        List<SelectOption> options = new List<SelectOption>();
        List<Account> alookup = [select id, Name from Account where RecordTypeId = :alarmCompany ORDER BY Name ASC];        
        for (Account x : alookup) {
            options.add(new SelectOption(x.id,x.Name));
        }        
        return options;
    }
    
    public List<SelectOption> getPoliceDepartments() {     
        string alarmCompany = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId();
        List<SelectOption> options = new List<SelectOption>();
        List<Account> alookup = [select id, Name from Account where RecordTypeId = :alarmCompany ORDER BY Name ASC];
        for (Account x : alookup) {
            options.add(new SelectOption(x.id,x.Name));
        }        
        return options;
    }

    public PageReference submit() {        
        //add submission process here
        //insert billing contact
        //insert license
        //link license/billing contact                
        if (theAlarmCompany != '---NONE---') l.Alarm_Company__c = theAlarmCompany;
        l.Police_Department__c = thePD;
        insert l;
        //create and relate billing contact
        License__c license = [select id, Location_Address__c, Location_State__c, Location_City__c, Location_Zip__c, Location_Business_Name__c from License__c where id = :l.id];
        List<False_Alarm__c> listFAcontact = [SELECT Attention_First_Name__c, Attention_Last_Name__c, Location_Business_Name__c 
                                           FROM False_Alarm__c 
                                           WHERE Id = :falseAlarmId];
        Contact newContact = new Contact();
        newContact.AccountId = thePD;
        //added by Amanda Howell 9-22-2016 for Contact Name and Business Name
        if(listFAcontact.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Provided False Alarm not found.'));
        } else {
        if ( listFAcontact[0].Attention_First_Name__c != Null || listFAcontact[0].Attention_Last_Name__c != Null ){
        newContact.FirstName = listFAcontact[0].Attention_First_Name__c;
        newContact.LastName = listFAcontact[0].Attention_Last_Name__c;
        }
        else if (listFAcontact[0].Location_Business_Name__c != NULL ){
        newContact.FirstName = 'Licensing';
        newContact.LastName = 'Permits';
        }
        else {
        newContact.FirstName = 'Alarm';
        newContact.LastName = 'Owner';
        }
        newContact.Business_Name__c = license.Location_Business_Name__c;
        newContact.MailingStreet = license.Location_Address__c;
        System.debug('License Location Address field:' + license.Location_Address__c);
        newContact.MailingState = l.Location_State__c;
        System.debug('License Location State field:' + license.Location_State__c);
        newContact.MailingCity = l.Location_City__c;
        System.debug('License Location city:' + license.Location_City__c);
        newContact.MailingPostalCode = l.Location_Zip__c;
        System.debug('License Location zip:' + license.Location_Zip__c);
        newContact.Billing_Street_Number__c = l.Location_Street_Number__c;
        System.debug('License Location Street Number:' + l.Location_Street_Number__c);
        newContact.Billing_Street_Name__c = l.Location_Street_Name__c;
        System.debug('License Location Street Name' + l.Location_Street_Name__c);
        newContact.Billing_Street_Type__c = l.Location_Street_Type__c;
        System.debug('License Location Street Type:' + l.Location_Street_Type__c);
        newContact.Billing_Street_Direction_Prefix__c = l.Location_Street_Direction_Prefix__c;
        newContact.Billing_Street_Unit_Number__c = l.Location_Unit_Number__c;
        newContact.Billing_Street_Direction_Suffix__c = l.Location_Street_Direction_Suffix__c;
        newcontact.Billing_Zip__c = l.Location_zip__c;
        newcontact.Billing_City__c = l.Location_City__c;
        newcontact.Billing_State__c = l.Location_State__c;
        insert newContact;
        System.debug('New Contact MailingStreet field:' + newcontact.MailingStreet);
        System.debug('New Contact MailingCity field:' + newcontact.MailingCity);
        System.debug('New Contact MailingState field:' + newcontact.MailingState);
        System.debug('New Contact MailingZip field:' + newcontact.MailingPostalCode);
        System.debug('New Contact Street Name field:' + newcontact.Billing_Street_Name__c);
        System.debug('New Contact Street Number field:' + newcontact.Billing_Street_Number__c);
        System.debug('New Contact Street Type field:' + newcontact.Billing_Street_Type__c);
        System.debug('New Contact Zip field:' + newcontact.Billing_Zip__c);
        System.debug('New Contact City field:' + newcontact.Billing_City__c);
        System.debug('New Contact State field:' + newcontact.Billing_State__c);
        }

        license.Billing_Contact__c = newContact.id;
        update license;
        //link false alarm record to license
        updateLicenseOfFalseAlarm(falseAlarmId, license.Id);
        //redirect to new license page
        return new PageReference('/' + l.id);
    }
    
    private void updateLicenseOfFalseAlarm(String faId, Id licenseId) {     
        if(String.isNotBlank(faId) && isValidSObjectId(faId)) {             
            False_Alarm__c fa = new False_Alarm__c(Id = faId);
            fa.License__c = licenseId;
            update fa;
        }       
    }
    
    private Boolean isValidSObjectId(String sObjectId) {
        try {
            Id recordId = (Id)sObjectId;
        } catch(Exception ex) {
            return false;
        }
        return true;
    }
}
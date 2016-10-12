/**
 * @Business: Handler class for AlarmCompanyRosterBatchTrigger Trigger
 * @Date: 2016-08-26
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-363   2016-09-07     Initial Phase 
*/
public class AlarmCompanyRosterBatchTrgHandler {
	public Boolean isBefore;
    public Boolean isAfter;
    public Boolean isInsert;
    public Boolean isUpdate;
    public Boolean isDelete;
    public Boolean isUndelete;
    public List<Alarm_Company_Roster_Batch__c> listOldACRB;
    public List<Alarm_Company_Roster_Batch__c> listNewACRB;
    public Map<Id, Alarm_Company_Roster_Batch__c> mapOldACRB;
    public Map<Id, Alarm_Company_Roster_Batch__c> mapNewACRB;
    
    // Static variable to stop recursive execution
    private static Boolean hasLicenseLinked = false; 
    
    public void process() {
        if(isAfter) {
            if(isInsert) {
                afterInsertProcessing();
            }
        }
    }
    
    public void afterInsertProcessing(){
        // APS-363
        linkACRBRecordToLicense(listNewACRB);
    }
    
    /**
     * Link Alarm_Company_Roster_Batch records to License if adderss fields of 
     * Alarm_Company_Roster_Batch records matches with any License's address fields
     * @param listACRB: List of Alarm_Company_Roster_Batch record to link with Licesnse.
     */
    public void linkACRBRecordToLicense(List<Alarm_Company_Roster_Batch__c> listACRB) {
		Map<String, List<License__c>> mapAddressToLicense = new Map<String, List<License__c>>();
        List<Alarm_Company_Roster_Batch__c> listACRBToUpdate = new List<Alarm_Company_Roster_Batch__c>();
        List<Alarm_Company_Roster_Batch__c> listUnmatchedACRBToUpdate = new List<Alarm_Company_Roster_Batch__c>();
        List<License__c> listLicenseToUpdate = new List<License__c>();
        List<Contact> listContactToUpdate = new List<Contact>();
        List<License__c> listNewLicense = new List<License__c>();
        Map<Id, Contact> mapACRBIdToNewContact = new Map<Id, Contact>();
        List<FeedItem> listTextChatterPost = new List<FeedItem>();
        Map<String, Id> mapAlarmCompanyNameToId = new Map<String, Id>();
        
        if(hasLicenseLinked) { return; }
        
        Set<String> setStreetNumber = new Set<String>();
        Set<String> setStreetName = new Set<String>();
        Set<String> setStreetType = new Set<String>();
        Set<String> setAlarmCompany = new Set<String>();
        final String POLICE_DEPARTMENT = listACRB[0].Police_Department__c;
        
        if(String.isBlank(POLICE_DEPARTMENT)) { return; }
        
        // Build set of Address fields of ARCB records
        for(Alarm_Company_Roster_Batch__c acrb : listACRB) {
            setStreetNumber.add(acrb.Location_Street_Number__c);
            setStreetName.add(acrb.Location_Street_Name__c);
            setStreetType.add(acrb.Location_Street_Type__c);
            setAlarmCompany.add(acrb.Alarm_Company__c);
        }
        // Remove null if any
        setStreetNumber.remove(null);
        setStreetName.remove(null);
        setStreetType.remove(null);
        setAlarmCompany.remove(null);
        
        Account policeDept = [SELECT Id, Unmatched_License__c FROM Account 
                              WHERE Name = :POLICE_DEPARTMENT];
        
        for(Account alarmCompany : [SELECT Id, Name FROM Account WHERE Name IN :setAlarmCompany]) {
            mapAlarmCompanyNameToId.put(alarmCompany.Name.toLowerCase(), alarmCompany.Id);
        }
        System.debug('\n mapAlarmCompanyNameToId:' + JSON.serialize(mapAlarmCompanyNameToId));
        
        
		System.debug('\n Unmatched License Id:' + policeDept.Unmatched_License__c);
        
        // Build set of License's Location_Address__c field value to License's record
        for(License__c license : [SELECT Id, Location_Street_Number__c, Location_Street_Name__c, Location_Street_Type__c,
                                      Billing_Contact__c 
                                  FROM License__c
                                  WHERE Police_Department__r.Name = :POLICE_DEPARTMENT
                                      AND (Location_Street_Number__c IN :setStreetNumber
                                      OR Location_Street_Name__c IN :setStreetName
                                      OR Location_Street_Type__c IN :setStreetType)]) {
        	String address = buildUniqueAddress(license.Location_Street_Number__c, 
                             	license.Location_Street_Name__c, license.Location_Street_Type__c);
        	if(!mapAddressToLicense.containsKey(address)) {
                mapAddressToLicense.put(address, new List<License__c>());
            }
			mapAddressToLicense.get(address).add(license);
		}
		System.debug('\n mapAddressToLicense:' + JSON.serialize(mapAddressToLicense));

        // Link ACRB records to License if Address field match with License else
        // build new License & Contact for unmatched ACRB record
        for(Alarm_Company_Roster_Batch__c acrb : listACRB) {
            String adddress = buildUniqueAddress(acrb.Location_Street_Number__c,
            					  acrb.Location_Street_Name__c,
                                  acrb.Location_Street_Type__c);
            
            // If License found for ACRB reocrd based on Address fields and Police_Department
            if(mapAddressToLicense.containsKey(adddress)) {
                // If single License Found
            	if(mapAddressToLicense.get(adddress).size() == 1) {
                    License__c license = mapAddressToLicense.get(adddress)[0];
                    String chatterPostBody = 'Alarm Company Roster Matched to {6}'
                    						 + '\n Alarm Company: {0} \n Address: {1} {2} {3} \n Contact: {4} {5}';
					String[] fillers = new String[] {
									       String.isBlank(acrb.Alarm_Company__c) ? '' : acrb.Alarm_Company__c, 
									       String.isBlank(acrb.Location_Street_Number__c) ? '' : acrb.Location_Street_Number__c,
									       String.isBlank(acrb.Location_Street_Name__c) ? '' : acrb.Location_Street_Name__c,
									       String.isBlank(acrb.Location_Street_Type__c) ? '' : acrb.Location_Street_Type__c,
									       String.isBlank( acrb.Contact_Last_Name__c) ? '' : acrb.Contact_Last_Name__c,
									       String.isBlank(acrb.Contact_First_Name__c) ? '' : acrb.Contact_First_Name__c,
									       'License'
									   };     						 
                            
                    // Link ACRB record to License
                    Alarm_Company_Roster_Batch__c acrbToLink = new Alarm_Company_Roster_Batch__c();
                    acrbToLink.Id = acrb.Id;
                    acrbToLink.License__c = license.Id;
                    listACRBToUpdate.add(acrbToLink);
                            
                    // Update License information if ACRB has any Alarm_Company value
                    String alarmCompanyName = String.isNotBlank(acrb.Alarm_Company__c) ? acrb.Alarm_Company__c : '';
                    alarmCompanyName = alarmCompanyName.toLowerCase();
                    if(mapAlarmCompanyNameToId.containskey(alarmCompanyName)) {                    	
                    	listLicenseToUpdate.add(buildLicenseWithUpdateAlarmCompany(acrbToLink.License__c, 
                						    		mapAlarmCompanyNameToId.get(alarmCompanyName)));	
                    }
                    
                    // Create chatter post for License
                    listTextChatterPost.add(buildTextChatterPost(license.Id, String.format(chatterPostBody, fillers)));
                    
                    // Create chatter post for Contact
                    fillers = new String[] {
							      String.isBlank(acrb.Alarm_Company__c) ? '' : acrb.Alarm_Company__c,
							      String.isBlank(acrb.Billing_Street_Number__c) ? '' : acrb.Billing_Street_Number__c,
							      String.isBlank(acrb.Billing_Street_Name__c) ? '' : acrb.Billing_Street_Name__c,
							      String.isBlank(acrb.Billing_Street_Type__c) ? '' : acrb.Billing_Street_Type__c,
							      String.isBlank(acrb.Contact_Last_Name__c) ? '' : acrb.Contact_Last_Name__c,
							      String.isBlank(acrb.Contact_First_Name__c) ? '' : acrb.Contact_First_Name__c,
							      'Contact'
							  };					
                    listTextChatterPost.add(buildTextChatterPost(license.Billing_Contact__c, String.format(chatterPostBody, fillers)));
                } else if(policeDept.Unmatched_License__c != null) {
                    // If multiple License Found, link ACRB record to Unmatched License
                    Alarm_Company_Roster_Batch__c acrbToLink = new Alarm_Company_Roster_Batch__c();
                    acrbToLink.Id = acrb.Id;
                    acrbToLink.License__c = policeDept.Unmatched_License__c;
                    listACRBToUpdate.add(acrbToLink);
                }
            } else {                               
                // Add ACRB record to list of "Unmatched ACRB" which will be useful 
                // for further processing
                listUnmatchedACRBToUpdate.add(acrb);
                
                if(String.isNotBlank(acrb.Contact_Last_Name__c)) {
                	mapACRBIdToNewContact.put(acrb.Id, buildNewBillingContactFromACRB(acrb));	
                }                
            }
        }
        
        // Insert "Contact" for Unmatched ACRB records
        if(!mapACRBIdToNewContact.isEmpty()) {
        	// Insert new Billing Contact for ACRB of which Address & Police_Department 
            // not match to any License record
            System.debug('\n mapACRBIdToNewContact:' + mapACRBIdToNewContact.size());
            Database.SaveResult[] saveResults = Database.insert(mapACRBIdToNewContact.values(), false);
            System.debug('\n New Contact create - Result');
            logDBSaveErrors(saveResults, mapACRBIdToNewContact.keySet());
        }
                        
        if(!listUnmatchedACRBToUpdate.isEmpty()) {
            // Create new License for ACRB of which Address & Police_Department not 
            // match to any License record
            for(Integer index = 0; index < listUnmatchedACRBToUpdate.size(); index++) {
                Alarm_Company_Roster_Batch__c acrb = listUnmatchedACRBToUpdate[index];
                Id alarmCompanyId = String.isNotBlank(acrb.Alarm_Company__c)
                                    ? mapAlarmCompanyNameToId.get(acrb.Alarm_Company__c.toLowerCase())
                                    : null;
                
                Id contactId = mapACRBIdToNewContact.containsKey(acrb.Id) ? mapACRBIdToNewContact.get(acrb.Id).Id : null;
                listNewLicense.add(buildNewLicenseFroACRB(acrb, policeDept.Id, alarmCompanyId, contactId));
            }
            System.debug('\n listNewLicense:' + listNewLicense.size());
            Database.SaveResult[] saveResults = Database.insert(listNewLicense, false);
            System.debug('\n New License create - Result');
            logDBSaveErrors(saveResults, listUnmatchedACRBToUpdate);
            
            for(Integer index = 0; index < listUnmatchedACRBToUpdate.size(); index++) {
                Alarm_Company_Roster_Batch__c acrbToLink = new Alarm_Company_Roster_Batch__c();
                acrbToLink.Id = listUnmatchedACRBToUpdate[index].Id;
                acrbToLink.License__c = listNewLicense[index].Id;
                listACRBToUpdate.add(acrbToLink);
            }
        }
        System.debug('\n listACRBToUpdate:' +  JSON.serialize(listACRBToUpdate));
        
        if(!listACRBToUpdate.isEmpty()) {
            hasLicenseLinked = true;
            Database.SaveResult[] saveResults = Database.update(listACRBToUpdate, false);
            System.debug('\n ACRB Update: Link to License - Result');
            logDBSaveErrors(saveResults, listACRBToUpdate);
        }
        
        // Update License's with updated Alarm_Company__c field
        if(!listLicenseToUpdate.isEmpty()) {
        	System.debug('\n listLicenseToUpdate:' + JSON.serialize(listLicenseToUpdate));
        	Database.SaveResult[] saveResults = Database.update(listLicenseToUpdate, false);
            System.debug('\n License Alarm_Company__c field Update - Result');
            logDBSaveErrors(saveResults, listLicenseToUpdate);
        }
        
        // Insert chatter post
        if(!listTextChatterPost.isEmpty()) {
        	Database.SaveResult[] saveResults = Database.insert(listTextChatterPost, false);
            System.debug('\n Chatter post for License and Contact: Insert - Result');
            logDBSaveErrors(saveResults, listTextChatterPost);
        }
    }

    /**
     * Build Unique address text separated by "<=>" using provided parameters     
     */
    private String buildUniqueAddress(String streetNumber, String streetName, String streetType) {
                String addressFormat = '{0}<=>{1}<=>{2}';
        String[] fillers = new String[] {
            			       streetNumber != null ? 	streetNumber : '',
                               streetName != null ? streetName : '',
                               streetType != null ? streetType : ''
        				   };
				        
        return String.format(addressFormat, fillers).toLowerCase();  
	}
    
    /**
     * Create record of License with values in Location fields coming from provided
     * Alarm_Company_Roster_Batch record
     * @param licenseId: Id of License record in which Location fields to update
     * @param alarmCompanyId: Value for Alarm_Comany__c field of License record.
     * @return License record with updated info
     */
    private License__c buildLicenseWithUpdateAlarmCompany(Id licenseId, Id alarmCompanyId) {
        License__c licenseToUpdate = new License__c(Id = licenseId);        
        licenseToUpdate.Alarm_Company__c = alarmCompanyId;
        return licenseToUpdate;
    }
               
	/**
	 * Create record of License using provided parameters
     * Alarm_Company_Roster_Batch record     
     * @param acrb: Alarm_Comany_Roster_Batch records of which Location fields to be used to
     *              create License record.
     * @param policeDeptId: Value for Police_Department__c field of new License
     * @param alarmCompanyId: Value for Alarm_Company__c field of new License
     * @param billingContactId: Value for Billing_Contact__c field of new License
     * @return new License record
     */
	private License__c buildNewLicenseFroACRB(Alarm_Company_Roster_Batch__c acrb, Id policeDeptId, 
            Id alarmCompanyId, Id billingContactId) {
        License__c newLicense = new License__c();
        
        newLicense.Location_Street_Direction_Prefix__c = acrb.Location_Street_Direction_Prefix__c;
        newLicense.Location_Street_Name__c = acrb.Location_Street_Name__c;
        newLicense.Location_Street_Number__c = acrb.Location_Street_Number__c;
        newLicense.Location_Street_Direction_Suffix__c = acrb.Location_Street_Direction_Suffix__c;
        newLicense.Location_Street_Type__c = acrb.Location_Street_Type__c;
        newLicense.Location_Unit_Number__c = acrb.Location_Unit_Number__c;
        newLicense.Location_City__c = acrb.Location_City__c;
        newLicense.Location_State__c = acrb.Location_State__c;
        newLicense.Location_Zip__c = acrb.Location_Zip__c;
        newLicense.Police_Department__c = policeDeptId;
        newLicense.Alarm_Company__c = alarmCompanyId;
        newLicense.Billing_Contact__c = billingContactId;
                
        return newLicense;
    }
    
    /** 
     * Create record of Contact with values in Location fields coming from provided
     * Alarm_Company_Roster_Batch record
     * @param acrb: Alarm_Comany_Roster_Batch records of which Location fields to be used to
     *              create License record.
     * @return new Contact record
     */
    private Contact buildNewBillingContactFromACRB(Alarm_Company_Roster_Batch__c acrb) {
        Contact billingContact = new Contact();
		
        billingContact.FirstName = acrb.Contact_First_Name__c;
        billingContact.LastName = acrb.Contact_Last_Name__c;	
        billingContact.Billing_Street_Direction_Prefix__c = acrb.Billing_Street_Direction_Prefix__c;
        billingContact.Billing_Street_Number__c = acrb.Billing_Street_Number__c;
        billingContact.Billing_Street_Name__c = acrb.Billing_Street_Name__c;
        billingContact.Billing_Street_Direction_Suffix__c = acrb.Billing_Street_Direction_Suffix__c;
        billingContact.Billing_Street_Type__c = acrb.Billing_Street_Type__c;
        billingContact.Billing_Street_Unit_Number__c = acrb.Billing_Street_Unit_Number__c;
        billingContact.Billing_City__c = acrb.Billing_City__c;
        billingContact.Billing_State__c = acrb.Billing_State__c;
        billingContact.Billing_Zip__c = acrb.Billing_Zip__c;        
        
        return billingContact;
    }
    
    /**
     * build chatter post for sObject with provided text body
     * @param recordId: Id of sObject record
     * @param textBody: Text body for chatter post
     * @return Text FeedItem(Chater Post) for sObject record
     */
	public FeedItem buildTextChatterPost(Id recordId, String textBody) {
		FeedItem textFeed = new FeedItem();
		textFeed.Type = 'TextPost';
		textFeed.ParentId = recordId;
		textFeed.Body = textBody;
		
		return textFeed;
	}     
    
    /**
     * Log Errors of Database.update() operation
     * Error format: <sobject_record_id>|<database_update_error_message>
     * @param saveResults: Result of Database.update() operation
     * @param listRecordToUpdate: List of records used in Database.update() operation
     */
    public void logDBSaveErrors(Database.SaveResult[] saveResults, List<SObject> listRecordToUpdate) {
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
    
    /**
     * Log Errors of Database.update() operation
     * Error format: <sobject_record_id>|<database_update_error_message>
     * @param saveResults: Result of Database.update() operation
     * @param setRecordId: Set of record Id
     */
    public void logDBSaveErrors(Database.SaveResult[] saveResults, Set<Id> setRecordId) {
        List<String> listError = new List<String>();
        List<Id> listId = new List<Id>(setRecordId);
        for(Integer index = 0; index < saveResults.size(); index++) {
            Database.SaveResult sr = saveResults[index];
            if(sr.success) { continue; }
            
            listError.add(listId[index] + '|' + sr.errors[0].message);
        }
        
        if(!listError.isEmpty()) {
            System.debug('\n listError:' + String.join(listError, '\n'));
        }
    }
}
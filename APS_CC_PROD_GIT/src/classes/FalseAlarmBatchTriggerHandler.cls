/**
 * @Business: Handler class for FalseAlarmBatchTrigger Trigger
 * @Date: 2016-08-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-358   2016-08-19     Initial Deployment
 *           2016-08-22     Added additional logic matching addresses to licenses from other cities, 
 *                          Added before insert process populating police department based on text field,
 *                          Populated event date time and linked false alarm batch record
 * APS-368   2016-08-30     Added condition to associate "False Alarm Batch" recrod to unmatched_Licnese field of 
 *                          Police_Department if multiple License records found with same address
 * APS-393   2016-09-22     added mapping to License Type
 * APS-395   2016-10-04     Added logic to match FAB's Address with License's Location_Address_1_OASIS__c field also 
 *                          apart from Location_Address__c field of License. 
*/
public class FalseAlarmBatchTriggerHandler {
    public Boolean isBefore;
    public Boolean isAfter;
    public Boolean isInsert;
    public Boolean isUpdate;
    public Boolean isDelete;
    public Boolean isUndelete;
    public List<False_Alarm_Batch__c> listOldFAB;
    public List<False_Alarm_Batch__c> listNewFAB;
    public Map<Id, False_Alarm_Batch__c> mapOldFAB;
    public Map<Id, False_Alarm_Batch__c> mapNewFAB;
    
    public void process() {
        if (isBefore && isInsert) {
            List<Account> pd = [select id, Name from Account where RecordTypeId = :Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId()];
            map<string,id> pd_map = new map<string,id>();
            for (Account x : pd) {
                pd_map.put(x.name,x.id);
            }
            for (False_Alarm_Batch__c x : listNewFAB) {
                if (x.Police_Department_Name__c != null && pd_map.get(x.Police_Department_Name__c) != null) {
                    x.Police_Department__c = pd_map.get(x.Police_Department_Name__c);
                }
            }           
        } else if(isAfter) {
            if(isInsert) {
                // APS 358
                insertFalseAlarmRecords(listNewFAB);
            }
        }
    }
    
    /**
     * Insert False_Alarm records
     * @param listFAB: List of False_Alarm_Batch records for which False_Alarm records to insert
     */
    private void insertFalseAlarmRecords(List<False_Alarm_Batch__c> listFAB) {
        final Set<String> SET_APPLICABLE_LICNESE_STATUS = new Set<String> {'Permitted','Unpermitted'};
        Map<String, List<Id>> mapAddressToLicenseId = new Map<String, List<Id>>();
        Map<String, List<Id>> mapOASISAddressToLicenseId = new Map<String, List<Id>>();
        Map<Id, Id> mapAccountIdToUnmatchLicenseId = new Map<Id, Id>();
        List<False_Alarm__c> listFalseAlarmToInsert = new List<False_Alarm__c>();
        Set<String> setAddressOfFAB = new Set<String>();
        Set<Id> setPoliceDepartmentId = new Set<Id>();
        
        // Build set of Street_Address__c field of False_Alarm_Batch records
        for(False_Alarm_Batch__c fab : listFAB) {
            setAddressOfFAB.add(fab.Street_Address__c);
            setPoliceDepartmentId.add(fab.Police_Department__c);
        }
        // Remove null if any
        setAddressOfFAB.remove(null);
        setPoliceDepartmentId.remove(null);
        
        // Build set of License's Location_Address__c field value to License's record
        Map<Id, License__c> mapLicense = new Map<Id, License__c>();
        for(License__c license : [SELECT Id, Location_Address__c, Location_Address_1_OASIS__c, Police_Department__c 
                                  FROM License__c
                                  WHERE (Location_Address__c IN :setAddressOfFAB
                                  	   OR Location_Address_1_OASIS__c IN :setAddressOfFAB)
                                      AND License_Status__c IN :SET_APPLICABLE_LICNESE_STATUS]) {
			mapLicense.put(license.Id, license);
            String address;
			if(license.Location_Address__c != null) {
                address = license.Location_Address__c.toLowerCase();
                if(!mapAddressToLicenseId.containsKey(address)) {
                    mapAddressToLicenseId.put(address, new List<Id>());
                }
                mapAddressToLicenseId.get(address).add(license.Id);
            } 

			if(license.Location_Address_1_OASIS__c != null) {                                          
                address = license.Location_Address_1_OASIS__c.toLowerCase();
                if(!mapOASISAddressToLicenseId.containsKey(address)) {
                    mapOASISAddressToLicenseId.put(address, new List<Id>());
                }
                mapOASISAddressToLicenseId.get(address).add(license.Id);
            }
        }
        System.debug('\n mapAddressToLicenseId:' + JSON.serialize(mapAddressToLicenseId)
                     + '\n mapOASISAddressToLicenseId:' + JSON.serialize(mapOASISAddressToLicenseId));
        
        // Build map Account Id to its Unmatched_License__c field
        for(Account policeDepartment : [SELECT Id, Unmatched_License__c FROM Account
                                        WHERE Id IN :setPoliceDepartmentId
                                            AND Unmatched_License__c != null]) {
            mapAccountIdToUnmatchLicenseId.put(policeDepartment.Id, policeDepartment.Unmatched_License__c);
        }
        System.debug('\n mapAccountIdToUnmatchLicenseId:' + JSON.serialize(mapAccountIdToUnmatchLicenseId));
        
        // Create False_Alarm records
        for(False_Alarm_Batch__c fab : listFAB) {
            // If Street_Address__c is empty then skip that record
            if(fab.Street_Address__c == null) { continue; }
                                    
            Id licenseId;
            
            String address = fab.Street_Address__c.toLowerCase();
            if(mapAddressToLicenseId.containsKey(address)
                    && mapAddressToLicenseId.get(address).size() == 1
                    && mapLicense.get(mapAddressToLicenseId.get(address)[0]).Police_Department__c == fab.Police_Department__c) {
                licenseId = mapAddressToLicenseId.get(address)[0];
            } else if(mapOASISAddressToLicenseId.containsKey(address)
                    && mapOASISAddressToLicenseId.get(address).size() == 1
                    && mapLicense.get(mapOASISAddressToLicenseId.get(address)[0]).Police_Department__c == fab.Police_Department__c) {
                licenseId = mapOASISAddressToLicenseId.get(address)[0];               
            } else if(fab.Police_Department__c != null
                    && mapAccountIdToUnmatchLicenseId.containsKey(fab.Police_Department__c)) {
                licenseId = mapAccountIdToUnmatchLicenseId.get(fab.Police_Department__c);
            }
            
            if(licenseId != null) {
                listFalseAlarmToInsert.add(buildFalseAlarm(fab, licenseId));
            }
        }
        System.debug('\n listFalseAlarmToInsert:' + JSON.serialize(listFalseAlarmToInsert));
        
        if(!listFalseAlarmToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(listFalseAlarmToInsert, false);
        }
    }
    
    /**
     * Build False_Alarm record using provided False_Alarm_Batch record and Licnese recrod
     * @param fab: False_Alarm_Batch object's record
     * @param licenseId: License's record's Id for License__c field of new False_Alarm record
     * @return False_Alarm object's record
     */
    private False_Alarm__c buildFalseAlarm(False_Alarm_Batch__c fab, Id licenseId) {
        False_Alarm__c newFalseAlarm = new False_Alarm__c(License__c = licenseId);
        newFalseAlarm.False_Alarm_Batch__c = fab.id;
        newFalseAlarm.Event_Date_Time__c = fab.Event_Date_Time__c;        
        newFalseAlarm.Location__c = fab.Street_Address__c;
        newFalseAlarm.Dispo__c = fab.Disp__c;
        newFalseAlarm.Apt__c = fab.Apt__c;
        newFalseAlarm.Location_Business_Name__c = fab.Business_Name__c;     
        // APS-393 Amanda Howell 9.21.2016 added line for Location Type
        if (fab.location_type__c == 'R') {
        newFalseAlarm.Location_Type__c = 'Residential';           
        } else if (fab.location_type__c == 'C') {
        newFalseAlarm.Location_Type__c = 'Commercial'; 
        } else newFalseAlarm.Location_Type__c = null;
        return newFalseAlarm;
    }    
}
/**
 * @Business: FalseAlarm Trigger Handling
 * @Date: 2016-03-31
 * @Author: Cumulus Vision
 * @Request: APS-232
 * Modified  ModifiedDate   Description
 * APS-256   2016-04-12     When License__c field is updated, update all related FalseAlarm record's
 *                          False_Alarm_Count__c field
 * APS-236   2016-04-12     Removed date translation since structure moved to CulverCityFalseAlarmBatchTriggerHandler
 * APS-352   2016-08-18     Update Logic which updates False_Alarm_Count__c field of False_Alarm records
 *                          based on False_Alarm records related License__r.Police_Department__r.False_Alarm_Billing_Logic__c
 *                          field.
*/
public class FalseAlarmTriggerHandler {
    public FalseAlarmTriggerHandler() {
        
    }
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,False_Alarm__c> oldMap {get; set;}
    public List<False_Alarm__c> NewF { get; set; }
    public List<False_Alarm__c> OldF { get; set; }
    private static Boolean isFalseAlarmCountUpdated = false;

    public void process() {
        if(isAfter && isInsert) {
            if(!isFalseAlarmCountUpdated) {
                updateFalseAlarmCount(NewF, null);    
            }            
        }

        if(isAfter && isUpdate) {
            if(!isFalseAlarmCountUpdated) {
                updateFalseAlarmCount(NewF, oldMap);    
            }            
        }
    }
    
    private License__c getLicense(String name) {
        try {
            System.debug('\n License Name:' + name);
            List<License__c> listOldLicenses = [SELECT Id FROM License__c WHERE Name = :name LIMIT 1];
            return (listOldLicenses.isEmpty() ? null : listOldLicenses[0]);  
        } catch(Exception e) {
            System.debug('\n  Error:' + e.getMessage());
        }
        return null;
    }
    
    /**
     * This function is called after "False Alarm" trigger insert and udpate
     * @param listFalseAlarams: List of Trigge.new records
     * @param mapOldFalseAlarms: Trigger.oldMap if called for "After Update" event else
     *                           value for this variable is null
     */
    private void updateFalseAlarmCount(List<False_Alarm__c> listFalseAlarams, 
            Map<Id, False_Alarm__c> mapOldFalseAlarms) {                    
        // Variable to store Id of License records of updated "False Alarm" records
        Set<Id> setLicenseId = new Set<Id>();
                
        // Variable to store Id of "False Alarm" records which are related to old "License" record                
        Set<Id> setFalseAlarmIdsForOldLicense = new Set<Id>();

        License__c oldLicense = getLicense('00-000000');                

        for(False_Alarm__c newFA : listFalseAlarams) {
            False_Alarm__c oldFalseAlarm = mapOldFalseAlarms == null 
                                           ? null : mapOldFalseAlarms.get(newFA.Id);
            if(oldFalseAlarm != null && newFA.License__c == oldFalseAlarm.License__c) { 
                continue; 
            } else if(oldFalseAlarm != null) {
                setLicenseId.add(oldFalseAlarm.License__c); 
            }

            if(oldLicense != null && newFA.License__c == oldLicense.Id) {
                setFalseAlarmIdsForOldLicense.add(newFA.Id);
            }
            
            setLicenseId.add(newFA.License__c);            
        }            
        System.debug('\n setLicenseId:' + JSON.serialize(setLicenseId)
                     + '\n setFalseAlarmIdsForOldLicense:' + JSON.serialize(setFalseAlarmIdsForOldLicense));
        
        if(!setLicenseId.isEmpty()) {
            updateFalseAlarmCount(setLicenseId);       
        }
                
        if(!setFalseAlarmIdsForOldLicense.isEmpty()) {
            updateInvoiceStatuses(setFalseAlarmIdsForOldLicense);            
        }
        isFalseAlarmCountUpdated = true;
    }
    
    /**
     * Update All "False Alarm" record's False_Alarm_Count__c field which are related to 
     * Licenses of which Ids provided in parameter
     * @param setLicenseId: Set of Ids of License of which related "False Alarm" to update
     */
    public void updateFalseAlarmCount(Set<Id> setLicenseId) {
        try {
            // Variable to store Id of License of which related Account's 
            // False_Alarm_Billing_Logic__c field value  = 'Calendar Year'
            Set<Id> setLicenseIdForCY = new Set<Id>();
            for(License__c license : [SELECT Id, Police_Department__r.False_Alarm_Billing_Logic__c
                                      FROM License__c 
                                      WHERE Id IN :setLicenseId]) {
                if(license.Police_Department__r.False_Alarm_Billing_Logic__c == 'Calendar Year') {
                    setLicenseIdForCY.add(license.Id);
                    setLicenseId.remove(license.Id);
                }                                          
            }
            
            // Fetch False_Alarm with License which will be calucated using
            // Last 365 Days logic.
            List<License__c> listLicenseWithFAs = [SELECT Id, (SELECT Id, Event_Date_Time__c 
                                                               FROM False_Alarms__r 
                                                               WHERE In_Last_Year__c = true
                                                                   AND Event_Date_Time__c >= LAST_N_DAYS:365
                                                               ORDER BY Event_Date_Time__c)
                                                   FROM License__c
                                                   WHERE Id IN :setLicenseId];
            List<False_Alarm__c> listFalseAlarmsToUpdate = new List<False_Alarm__c>();
            listFalseAlarmsToUpdate.addAll(updateCountOfFalseAlarmsByLicense(listLicenseWithFAs));
            
            // Fetch False_Alarm with License which will be calucated using
            // "Current Calendar Year" logic
            listLicenseWithFAs = [SELECT Id, (SELECT Id, Event_Date_Time__c 
                                              FROM False_Alarms__r 
                                              WHERE Event_Date_Time__c = THIS_YEAR
                                              ORDER BY Event_Date_Time__c)
                                  FROM License__c
                                  WHERE Id IN :setLicenseIdForCY];
            listFalseAlarmsToUpdate.addAll(updateCountOfFalseAlarmsByLicense(listLicenseWithFAs));         
            
            if(!listFalseAlarmsToUpdate.isEmpty()) {
                update listFalseAlarmsToUpdate;
            }
        } catch(Exception ex) {
            System.debug('\n Error in re-calculating "FALSE ALARM COUNT" field'
                        +  '\n MSG:' + ex.getMessage() + '\n STACK TRACE:' + ex.getStackTraceString());
        }      
    }

    @future
    private static void updateInvoiceStatuses(Set<Id> setFalseAlarmIds) {
        try {
            List<Invoice__c> listInvoicesToUpdate;
            listInvoicesToUpdate = [SELECT Id FROM Invoice__c
                                    WHERE Status__c != 'Paid'
                                        AND Id IN (SELECT Invoice__c FROM Invoice_Line_Item__c 
                                                   WHERE False_Alarm__c IN :setFalseAlarmIds)];
            for(Invoice__c invoice : listInvoicesToUpdate) {
                invoice.Status__c = 'Waived';
                invoice.Note__c = 'False Alarm Moved';
            }
            
            if(!listInvoicesToUpdate.isEmpty()) {
                update listInvoicesToUpdate;
            }
        } catch (Exception ex) {
            System.debug('\n Error - updateInvoiceLineItemStatuses \n MSG:' + ex.getMessage());
        }
    }
    
    /**
     * Set value to False_Alarm_Count__c field of False_Alarm in incrementing
     * style for every License record
     * @param listLicenseWithFAs:
     * @return List of Updated False_Alarm_Count__c field of False_Alarm record
     */
    private List<False_Alarm__c> updateCountOfFalseAlarmsByLicense(List<License__c> listLicenseWithFAs) {
        List<False_Alarm__c> listFalseAlarmsToUpdate = new List<False_Alarm__c>();
        for(License__c license : listLicenseWithFAs) {
            Integer count = 1;
            for(False_Alarm__c fa : license.False_Alarms__r) {
                fa.False_Alarm_Count__c = String.valueOf(count++);
                listFalseAlarmsToUpdate.add(fa);
            }
        }
        return listFalseAlarmsToUpdate;
    }
}
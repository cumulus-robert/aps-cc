/**
 * @Business: CulverCityFalseAlarmBatch Trigger Handling
 * @Date: 4/8/2016
 * @Author: Cumulus Vision
 * @Request: APS-236
 * Modified  ModifiedDate   Description
*/
public class CulverCityFalseAlarmBatchTriggerHandler {
    public CulverCityFalseAlarmBatchTriggerHandler() {
        
    }
    public Boolean IsAfter { get; set; }
    public Boolean IsBefore { get; set; }
    public Boolean IsInsert { get; set; }
    public Boolean IsUpdate { get; set; }
    public Boolean IsDelete { get; set; }
    public Boolean IsUnDelete { get; set; }
    public map<id,CC_False_Alarm_Batch__c> oldMap {get; set;}
    public List<CC_False_Alarm_Batch__c> NewC { get; set; }
    public List<CC_False_Alarm_Batch__c> OldC { get; set; }

    public void process() {
        
        if (IsAfter && IsInsert) {
            generateFalseAlarm(NewC);
        }
    }
    
    /**
    * @description Method generate false alarm
    */
    
    //public static final String LICENSE_NUMBER = '00-000000';            // String of default license number
    public License__c defaultLicense { get; set; }                      // Default License
    
    public void generateFalseAlarm(List<CC_False_Alarm_Batch__c> listNew) {

        set<string> licenseStatusMatch = new set<string> {'Permitted','Unpermitted'};
        
        Map<String, CC_False_Alarm_Batch__c> mapAddress2FAB = new Map<String, CC_False_Alarm_Batch__c>();
        Map<String, List<License__c>> mapAddressLicense = new Map<String, List<License__c>>();
        Account alookup = [select id, Unmatched_License__c from Account where Name = 'CULVER CITY POLICE DEPARTMENT'];
        // Get default license
        defaultLicense = new License__c();
        defaultLicense = [SELECT Name, Location_Address__c, Id FROM License__c WHERE id =: alookup.Unmatched_License__c];
        
        // Mapping Address with CC False Alarm Batch record
        for (CC_False_Alarm_Batch__c f : listNew) {
            if (String.isNotBlank(f.Incident_Address__c)) mapAddress2FAB.put(f.Incident_Address__c, f);
        }
        
        // Mapping Address with License record
        for (License__c l : [SELECT Name, Location_Address__c, Id FROM License__c WHERE Location_Address__c IN :mapAddress2FAB.keySet() AND License_Status__c IN : licenseStatusMatch]) {
            
            if (mapAddressLicense.get(l.Location_Address__c) == NULL) mapAddressLicense.put(l.Location_Address__c, new List<License__c>());
            mapAddressLicense.get(l.Location_Address__c).add(l);
            
        }
        
        // Create false alarm
        List<False_Alarm__c> listFA = new List<False_Alarm__c>();
        List<False_Alarm__c> listFAHasLicense = new List<False_Alarm__c>();
                      
        for (CC_False_Alarm_Batch__c fab :listNew) {
            
            if (mapAddressLicense.get(fab.Incident_Address__c) != NULL && mapAddressLicense.get(fab.Incident_Address__c).size() == 1) { // Create false alarm for single match 
                              
                listFAHasLicense.add(bindFalseAlarm(fab, mapAddressLicense.get(fab.Incident_Address__c)[0]));
                
            } else { // Create false alarm for not match address or multiple found
                
            
                listFA.add(bindFalseAlarm(fab, defaultLicense));
                
            }           
            
        }
        
        listFA.addAll(listFAHasLicense);
        
        INSERT listFA;
    }    
    /**
    * @description Method bind false alarm
    * @param fab Object of  CC_False_Alarm_Batch__c
    * @param l Object of license
    * @return Object of false alarm
    */
    private False_Alarm__c bindFalseAlarm(CC_False_Alarm_Batch__c fab, License__c l) {
        
        False_Alarm__c fa = new False_Alarm__c();
        fa.Culver_City_False_Alarm_Batch__c = fab.Id;
        fa.License__c = l.Id;
        fa.Location__c = fab.Incident_Address__c;
        fa.Street__c = fab.Incident_Address_Street_Name__c;
        fa.Police_Department_Comments__c = fab.Document_Text__c;
        fa.Dispo__c = fab.Incident_CFS_Disposition__c;
        if (fab.Incident_Date_And_Time__c != null) {
            string [] thedatesplit = fab.Incident_Date_And_Time__c.split(' ');
            fa.Event_Date_Time__c = translateDate(thedatesplit[0],thedatesplit[1]);    
        }
        
        return fa;
        
    }

    private datetime translateDate (string theDate, string theTime) {
        integer year;
        integer month;
        integer day;

        if (theDate.contains('/')) {
            string[] thedatesplit = theDate.split('/');
            system.debug(thedatesplit);
            year = integer.valueOf(thedatesplit[2].trim().left(4));
            month = integer.valueOf(thedatesplit[0].trim());
            day = integer.valueOf(thedatesplit[1].trim());
        } else if (theDate.contains('-')) {
            string[] thedatesplit = theDate.split('-');
            system.debug(thedatesplit);
            year = integer.valueOf(theDateSplit[0].trim().left(4));
            month = integer.valueOf(thedatesplit[1].trim());
            day = integer.valueOf(theDateSplit[2].trim());
        }
        system.debug('Year: ' + year);
        system.debug('Month: ' + month);
        system.debug('Day: ' + day);
        
        string [] thetimesplit = theTime.split(':');
        system.debug(thetimesplit);
        integer theMinute = integer.valueOf(thetimesplit[1]);
        integer theHour = integer.valueOf(theTimesplit[0]);
        datetime theEventDate;
        if (string.valueOf(year).length() == 2) {
            theEventDate = datetime.newInstance(year+2000, month, day, theHour, theMinute, 0);    
        } else {
            theEventDate = datetime.newInstance(year, month, day, theHour, theMinute, 0);
        }
        system.debug(theEventDate);

        return theEventDate;
    }

}
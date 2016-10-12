/**
 * @Business: BatchSetFalseAlarmCounts Apex Batch
 * @Date: 2016-08-23
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
*/
public class BatchSetFalseAlarmCounts implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String strQuery;
        
        strQuery = 'SELECT Id FROM License__c WHERE Police_Department__r.Name <> \'CULVER CITY POLICE DEPARTMENT\'';
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<License__c> listLicenses) {
        Set<Id> setLicenseIds = new Set<Id>();
        for(License__c license : listLicenses) {
            setLicenseIds.add(license.Id);
        }
         
        FalseAlarmTriggerHandler handler = new FalseAlarmTriggerHandler();
        handler.updateFalseAlarmCount(setLicenseIds);        
    }

    public void finish(Database.BatchableContext BC) {
    
    }

}
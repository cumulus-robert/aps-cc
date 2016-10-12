/**
 * @Business: Batch job to reset license status where permit date is in past or is null
 * @Date: 2016-08-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-345   2016-08-19     Initial Deployment
 * APS-369   2016-09-02     Modifications to License query criteria
 * APS-377   2016-09-15     Added criteria to exclude Exempt and Suspended licenses    
*/
public class BatchExpiredPermitRenewalLicense implements Database.Batchable<SObject> {
    // Constructor
    public BatchExpiredPermitRenewalLicense() {
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM License__c'
                       + ' WHERE (Permit_Expiration_Date__c < TODAY OR Permit_Expiration_Date__c = null)'	
                       + ' AND License_Status__c NOT IN (\'Unpermitted\', \'Inactivated\',\'Exempt\',\'Suspended\')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<License__c> listRecords) {
        for(License__c license : listRecords) {
            license.License_Status__c = 'Unpermitted';
        }
        
        Database.SaveResult[] saveResults = Database.update(listRecords, false);
        List<String> listErrors = new List<String>();
        for(Integer index = 0; index < saveResults.size(); index++) {
            if(!saveResults[index].isSuccess()) {
                listErrors.add(listRecords[index].Id + '|' + saveResults[index].errors[0].message);
            }
        }
        
        // Log error
        if(!listErrors.isEmpty()) {
            System.debug('Error in updating "License Statuses" \n' + String.join(listErrors, '\n'));
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
}
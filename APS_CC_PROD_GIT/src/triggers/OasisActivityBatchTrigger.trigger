/**
 * @Business: OASIS_Activity_Batch__c Trigger Handling
 * @Date: 4/4/2016
 * @Author: Cumulus Vision
 * @Request: %requestId%
 * Modified  ModifiedDate   Description
*/
trigger OasisActivityBatchTrigger on OASIS_Activity_Batch__c (after insert) {

	OasisActivityBatchTriggerHandler OHandler = new OasisActivityBatchTriggerHandler();

    OHandler.NewO = (List<OASIS_Activity_Batch__c>) Trigger.new;
    OHandler.OldO = (List<OASIS_Activity_Batch__c>) Trigger.old;
    OHandler.oldMap = trigger.oldMap;
    OHandler.IsBefore = Trigger.IsBefore;
    OHandler.IsAfter = Trigger.IsAfter;
    OHandler.IsUpdate = Trigger.IsUpdate;
    OHandler.IsInsert = Trigger.IsInsert;
    OHandler.IsDelete = Trigger.IsDelete;
    OHandler.IsUnDelete = Trigger.isUnDelete;

    OHandler.process();

}
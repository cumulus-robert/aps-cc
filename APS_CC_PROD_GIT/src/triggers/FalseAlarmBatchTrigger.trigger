/**
 * @Business: FalseAlarmBatchTrigger Trigger
 * @Date: 2016-08-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-358   2016-08-19     Initial Deployment
 *           2016-08-22     Added before insert function to associate PD via PD text field
*/
trigger FalseAlarmBatchTrigger on False_Alarm_Batch__c(before insert, after insert) {
	FalseAlarmBatchTriggerHandler handler = new FalseAlarmBatchTriggerHandler();
    handler.isBefore = Trigger.isBefore;
    handler.isAfter = Trigger.isAfter;
    handler.isInsert = Trigger.isInsert;
    handler.isUpdate = Trigger.isUpdate;
    handler.isDelete = Trigger.isDelete;
    handler.isUndelete = Trigger.isUndelete;
    handler.listOldFAB = Trigger.old;
    handler.listNewFAB = Trigger.new;
    handler.mapOldFAB = Trigger.oldMap;
    handler.mapNewFAB = Trigger.newMap;
    
    handler.process();
}
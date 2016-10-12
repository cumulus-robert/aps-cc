/**
 * @Business: CC_False_Alarm_Batch__c Trigger Handling
 * @Date: 4/8/2016
 * @Author: Cumulus Vision
 * @Request: %requestId%
 * Modified  ModifiedDate   Description
*/
trigger CulverCityFalseAlarmBatchTrigger on CC_False_Alarm_Batch__c (after insert) {

	CulverCityFalseAlarmBatchTriggerHandler CHandler = new CulverCityFalseAlarmBatchTriggerHandler();

    CHandler.NewC = (List<CC_False_Alarm_Batch__c>) Trigger.new;
    CHandler.OldC = (List<CC_False_Alarm_Batch__c>) Trigger.old;
    CHandler.oldMap = trigger.oldMap;
    CHandler.IsBefore = Trigger.IsBefore;
    CHandler.IsAfter = Trigger.IsAfter;
    CHandler.IsUpdate = Trigger.IsUpdate;
    CHandler.IsInsert = Trigger.IsInsert;
    CHandler.IsDelete = Trigger.IsDelete;
    CHandler.IsUnDelete = Trigger.isUnDelete;

    CHandler.process();

}
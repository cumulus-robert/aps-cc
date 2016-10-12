/**
 * @Business: False_Alarm__c Trigger Handling
 * @Date: 3/31/2016
 * @Author: Cumulus Vision
 * @Request: APS-232
 * Modified  ModifiedDate   Description
 * APS-256    04/12/2016     Added "after update" & "after insert" event
*/
trigger FalseAlarmTrigger on False_Alarm__c (before insert, after insert, after update) {

	FalseAlarmTriggerHandler FHandler = new FalseAlarmTriggerHandler();

    FHandler.NewF = (List<False_Alarm__c>) Trigger.new;
    FHandler.OldF = (List<False_Alarm__c>) Trigger.old;
    FHandler.oldMap = trigger.oldMap;
    FHandler.IsBefore = Trigger.IsBefore;
    FHandler.IsAfter = Trigger.IsAfter;
    FHandler.IsUpdate = Trigger.IsUpdate;
    FHandler.IsInsert = Trigger.IsInsert;
    FHandler.IsDelete = Trigger.IsDelete;
    FHandler.IsUnDelete = Trigger.isUnDelete;

    FHandler.process();

}
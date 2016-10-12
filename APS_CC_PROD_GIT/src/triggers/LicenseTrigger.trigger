/**
 * @Business: License__c Trigger Handling
 * @Date: 4/15/2016
 * @Author: Cumulus Vision
 * @Request: APS-264
 * Modified  ModifiedDate   Description
 * APS-277    5/5/2016		Added before insert event
*/
trigger LicenseTrigger on License__c (before insert, after insert, after update) {

	LicenseTriggerHandler LHandler = new LicenseTriggerHandler();

    LHandler.NewL = (List<License__c>) Trigger.new;
    LHandler.OldL = (List<License__c>) Trigger.old;
    LHandler.oldMap = trigger.oldMap;
    LHandler.IsBefore = Trigger.IsBefore;
    LHandler.IsAfter = Trigger.IsAfter;
    LHandler.IsUpdate = Trigger.IsUpdate;
    LHandler.IsInsert = Trigger.IsInsert;
    LHandler.IsDelete = Trigger.IsDelete;
    LHandler.IsUnDelete = Trigger.isUnDelete;

    LHandler.process();

}
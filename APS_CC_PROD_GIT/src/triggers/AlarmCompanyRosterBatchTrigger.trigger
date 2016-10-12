/**
 * @Business: Trigger for Alarm_Company_Roster_Batch__c object
 * @Date: 2016-08-26
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-363   2016-08-26     Initial Phase
*/
trigger AlarmCompanyRosterBatchTrigger on Alarm_Company_Roster_Batch__c (after insert) {
	AlarmCompanyRosterBatchTrgHandler handler = new AlarmCompanyRosterBatchTrgHandler();
    handler.isBefore = Trigger.isBefore;
    handler.isAfter = Trigger.isAfter;
    handler.isInsert = Trigger.isInsert;
    handler.isUpdate = Trigger.isUpdate;
    handler.isDelete = Trigger.isDelete;
    handler.isUndelete = Trigger.isUndelete;
    handler.listOldACRB = Trigger.old;
    handler.listNewACRB = Trigger.new;
    handler.mapOldACRB = Trigger.oldMap;
    handler.mapNewACRB = Trigger.newMap;
    
    handler.process();
}
/**
 * @Business: Invoice__c Trigger Handling
 * @Date: 2016-09-21
 * @Author: Cumulus Vision
 * @Request: APS-390
 * Modified  ModifiedDate   Description
*/
trigger InvoiceTrigger on Invoice__c (after insert, after update) {

	InvoiceTriggerHandler IHandler = new InvoiceTriggerHandler();

    IHandler.NewI = (List<Invoice__c>) Trigger.new;
    IHandler.OldI = (List<Invoice__c>) Trigger.old;
    IHandler.oldMap = trigger.oldMap;
    IHandler.IsBefore = Trigger.IsBefore;
    IHandler.IsAfter = Trigger.IsAfter;
    IHandler.IsUpdate = Trigger.IsUpdate;
    IHandler.IsInsert = Trigger.IsInsert;
    IHandler.IsDelete = Trigger.IsDelete;
    IHandler.IsUnDelete = Trigger.isUnDelete;

    IHandler.process();

}
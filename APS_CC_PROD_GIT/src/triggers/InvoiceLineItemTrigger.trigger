/**
 * @Business: Invoice_Line_Item__c Trigger Handling
 * @Date: 2016-05-17
 * @Author: Cumulus Vision
 * @Request: APS-313
 * Modified  ModifiedDate   Description
 * APS-348   2016-08-10     added before insert process.
*/
trigger InvoiceLineItemTrigger on Invoice_Line_Item__c (before insert, after insert, after update) {

	InvoiceLineItemTriggerHandler IHandler = new InvoiceLineItemTriggerHandler();

    IHandler.NewI = (List<Invoice_Line_Item__c>) Trigger.new;
    IHandler.OldI = (List<Invoice_Line_Item__c>) Trigger.old;
    IHandler.oldMap = trigger.oldMap;
    IHandler.IsBefore = Trigger.IsBefore;
    IHandler.IsAfter = Trigger.IsAfter;
    IHandler.IsUpdate = Trigger.IsUpdate;
    IHandler.IsInsert = Trigger.IsInsert;
    IHandler.IsDelete = Trigger.IsDelete;
    IHandler.IsUnDelete = Trigger.isUnDelete;

    IHandler.process();

}
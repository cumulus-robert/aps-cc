/**
 * Trigger handler class for BillingActivityTrigger
 * @author Mahesh G.
 * @createdDate 2016-09-21
 * RequestId    ModifiedDate   Description
 *  APS-379      2016-09-21	    Initial Development
 */
trigger BillingActivityTrigger on Billing_Activity__c (after insert) {
	BillingActivityTriggerHandler handler = new BillingActivityTriggerHandler();
    handler.isBefore = Trigger.isBefore;
    handler.isAfter = Trigger.isAfter;
    handler.isInsert = Trigger.isInsert;
    handler.isUpdate = Trigger.isUpdate;
    handler.isUndelete = Trigger.isUndelete;
    handler.isDelete = Trigger.isDelete;
    handler.listNewBA = Trigger.new;
    handler.listOldBA = Trigger.old;
    handler.mapNewBA = Trigger.newMap;
    handler.mapOldBA = Trigger.oldMap;
    
    handler.process();
}
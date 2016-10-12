/**
 * Test class for InvoiceAdministrationController class
 * @author Mahesh G.
 * @createDate 2016-05-13
 * Modified   ModifiedDate   Description
 * APS-238    2016-05-13     
 */
@isTest
private class InvoiceAdministrationControllerTest {
    static testMethod void testBatchFalseAlarmInvoiceExecution() {
        Test.startTest();
        InvoiceAdministrationController controller = new InvoiceAdministrationController();
        
        String status = controller.getFalseAlarmBatchCompleteStatus();
        System.assertEquals(InvoiceAdministrationController.FA_BATCH_COMPLETE_STATUS, status);   
        
        controller.executeBatchFalseAlarmInvoice();
		System.assertEquals(true, controller.hasFAInvoiceBatchInProgress);
        
        controller.displayPageMessage(ApexPages.Severity.ERROR, 'some message');
        
		Test.stopTest();
        
        controller.checkFalseAlarmInvoiceBatchStatus();
		System.assertEquals(false, controller.hasFAInvoiceBatchInProgress);
    }
}
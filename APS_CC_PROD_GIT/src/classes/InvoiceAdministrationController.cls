/**
 * Execute batch Job
 * @author Mahesh G.
 * @createDate 2016-05-05
 * Modified   ModifiedDate   Description
 * APS-238    2016-05-05    
 */
public class InvoiceAdministrationController {
	
    public Boolean hasFAInvoiceBatchInProgress { get; private set; }
    public String faiJobStatus { get; private set; }
    public Id faiJobId;
    
    public static final String FA_BATCH_COMPLETE_STATUS = 'Invoice is ready for review';
        
    public String getFalseAlarmBatchCompleteStatus() {
		return FA_BATCH_COMPLETE_STATUS;        
    }
    
    /**
     * Execute BatchFalseAlarmInvoice class
     */	
    public void executeBatchFalseAlarmInvoice() {
        try {
            faiJobId = Database.executeBatch(new BatchFalseAlarmInvoice(true));
            hasFAInvoiceBatchInProgress = true;
            faiJobStatus = 'Processing Invoices';
        } catch(Exception ex) {
            displayPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
            System.debug('\n ERROR while executing BatchFalseAlarmInvoice class'
                         + '\n MSG:' + ex.getMessage() + '\n STACK TRACE:' + ex.getStackTraceString());
		}
    }
    
    public void checkFalseAlarmInvoiceBatchStatus() {
        AsyncApexJob batchJob = [SELECT Status FROM AsyncApexJob WHERE Id = :faiJobId];
        
        if(batchJob.Status == 'Completed'){
            faiJobStatus = String.isBlank(faiJobStatus) ? '' : FA_BATCH_COMPLETE_STATUS;
            hasFAInvoiceBatchInProgress = false;
        }            
    }
    
    @TestVisible
    private void displayPageMessage(ApexPages.Severity severity, String message){
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}
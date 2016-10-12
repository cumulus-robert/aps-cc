/**
 *  @author Amol K
 *  @CreatedOn 16 May 2016
 *  @description  Schedule LicenseRenewalBatch class 
 */
global class LicenseRenewalBatchScheduler implements Schedulable {
    /**
     *  @description License Renewal Batch Scheduler
     */
    global void execute(SchedulableContext ctx) {  
        
         // excute batch class that renews License 
         Database.executeBatch(new LicenseRenewalBatch());
    }
}
/**
 * @Business: Batch job to reset license status where permit date is in past or is null
 * @Date: 2016-08-19
 * @Author: Cumulus Vision
 * Modified  ModifiedDate   Description
 * APS-345   2016-08-19     Initial Deployment
*/
public class BatchExpiredPermitRnwlLicenseScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchExpiredPermitRenewalLicense());
	}
}
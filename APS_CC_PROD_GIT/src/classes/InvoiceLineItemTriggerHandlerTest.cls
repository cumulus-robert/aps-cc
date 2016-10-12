/*
 * @Business: see Invoice_Line_Item__c Trigger Handler
 * @Date: 2016-05-17
 * @Author: Cumulus Vision
 * @Request: APS-313
 * Modified  ModifiedDate   Description
*/
@isTest 
public class InvoiceLineItemTriggerHandlerTest {

	public static List<Account> accounttest {get; set;}
    public static Contact contacttest {get; set;}
    public static List<Invoice__c> lstInvoices {get; set;}
    public static List<Invoice_Line_Item__c> lstILI {get; set;}
    public static List<License__c> lstlicenses {get; set;}
    public static List<False_Alarm__c> lstfalsealarm {get; set;}


	static void CreateRecords_AlarmServiceCompany() {
            accounttest = new List<Account>();
            accounttest.add(new Account(RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Alarm Company').getRecordTypeId(), Name='testAcc54', BillingPostalCode='3256'));
            accounttest.add(new Account(RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Police Department').getRecordTypeId(), Name='testAcc54', BillingPostalCode='3256'));
            insert accounttest;

            lstlicenses = new List<License__c>();
            lstlicenses.add(new License__c(License_Status__c='Permitted', Police_Department__c=accounttest[1].id));
            lstlicenses.add(new License__c(License_Status__c='Unpermitted', Police_Department__c=accounttest[1].id));
            insert lstlicenses;

            lstfalsealarm = new List<False_Alarm__c>();
            lstfalsealarm.add(new False_Alarm__c(License__c=lstlicenses.get(0).Id)); //billable qualified
            lstfalsealarm.add(new False_Alarm__c(License__c=lstlicenses.get(0).Id)); //billable not qualified
            lstfalsealarm.add(new False_Alarm__c(License__c=lstlicenses.get(0).Id)); //add false alarm from previous year to test roll up
            lstfalsealarm.add(new False_Alarm__c(License__c=lstlicenses.get(1).Id)); //false alarm associated to 'unregistered license'

            insert lstfalsealarm;
    }

    static void CreateInvoices() {
        lstInvoices = new List<Invoice__c>();
        lstInvoices.add(new Invoice__c(License__c = lstlicenses[0].Id, Status__c = 'Payment Due')); // registered license, for testing late fee
        lstInvoices.add(new Invoice__c(License__c = lstlicenses[0].Id, Status__c = 'Past Due')); // registered license, past due, for admin fee and interest
        insert lstInvoices;
    }

    static void CreateILI() {
    	lstILI = new List<Invoice_Line_Item__c>();
        lstILI.add(new Invoice_Line_Item__c(Invoice__c = lstInvoices[0].Id, False_Alarm__c = lstfalsealarm[0].id, Item__c = 'False Alarm', Item_Type__c = 'False Alarm 1')); // registered license, for testing late fee
        insert lstILI;
    }

    private static User createAdmin() {

      Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
      User u = new User(Alias = 'Admin', Email='admin12354@testorg.com', 
                      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                      LocaleSidKey='en_US', ProfileId = p.Id,
                      TimeZoneSidKey='America/Los_Angeles', UserName='admin12354@testorg.com'); 

      return u;
    }

    static testMethod void shouldBeDeleteInvoices() {

         System.runAs(createAdmin()) {

            CreateRecords_AlarmServiceCompany();
            CreateInvoices();
            CreateILI();

            Invoice_Line_Item__c newIinvoiceLineItem = new Invoice_Line_Item__c(Invoice__c = lstInvoices[0].Id, False_Alarm__c = lstfalsealarm[0].id, 
                                                                                Item__c = 'False Alarm', Item_Type__c = 'False Alarm 1', 
                                                                                Fee_Amount__c = 235);

            INSERT newIinvoiceLineItem;

            License__c lic = [SELECT Unmatched__c, Id FROM License__c WHERE Id = :lstInvoices[0].License__c ];
            //System.assertEquals(true, lic.Unmatched__c, 'Should be update to true if fee amount on invoice line item equals 235');
            //System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE License__c = :lic.Id], 'Should be delete all invoice related to this license');
        }        
    }
}
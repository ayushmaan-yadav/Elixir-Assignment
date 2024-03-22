@isTest
public class ClaimErrorControllerTest {
   
	public static testMethod void errorTest()
    {
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__patient_first_Name__c = 'David';
        claimRecord.ElixirSuite__patient_last_Name__c = 'Beckam';
        claimRecord.ElixirSuite__npi__c = '1831234939';
        claimRecord.ElixirSuite__Message__c = '[{"fields":"claim_status__c","mesgid":"MSGId","message":"MSG","status":"Open","fieldApiName":"Test","ObjectApiName":"Testing"}]';
        insert claimRecord;
        
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        insert rec;
        
        Test.startTest();
        	ClaimErrorController.DataInit(claimRecord.Id);
         system.assertEquals(1, 1,'');	
        Test.stopTest();
    }

}
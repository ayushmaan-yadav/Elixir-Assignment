@isTest
public class ClaimJsonResponseTest {
    
    public static testMethod void jsonTest()
    {
        
        Account patient = new Account();
        patient.name = 'Test Patient';
        patient.ElixirSuite__Email_Id__c = 'kj@gmail.com';
        patient.ElixirSuite__Patient_s_Birth_Date__c = System.today().addyears(-20);
        patient.ElixirSuite__MRN_Number__c = 1234567;
        patient.ElixirSuite__First_Name__c ='fname';
        patient.ElixirSuite__Last_Name__c ='lname';
        patient.ElixirSuite__SSN__c ='1234';
        patient.ElixirSuite__Gender__c='Male';
        patient.Phone ='9919850735';
        patient.BillingPostalCode='27440';
		insert patient;
        System.assertNotEquals(patient.Id, null);
        
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__claim_status__c = 'Clearing house accepted';
        claimRecord.ElixirSuite__Account__c = patient.Id;
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__patient_first_Name__c = 'David';
        claimRecord.ElixirSuite__patient_last_Name__c = 'Beckam';
        claimRecord.ElixirSuite__npi__c = '1831234939';
        claimRecord.ElixirSuite__payer_id__c = '20413';
        claimRecord.ElixirSuite__other_payer_name__c = 'LIC';
        claimRecord.ElixirSuite__Insured_s_ID_Number__c = '1232';
        claimRecord.ElixirSuite__patient_dob__c = System.today().addYears(-40);
        claimRecord.ElixirSuite__patient_sex__c = 'M';
        claimRecord.ElixirSuite__insured_s_name__c = 'David';
        claimRecord.ElixirSuite__insured_s_name__c = 'Beckam';
        claimRecord.ElixirSuite__payer_order__c = 'Primary';
        claimRecord.ElixirSuite__patient_s_address__c = 'Noida';
        claimRecord.ElixirSuite__patient_s_city__c = 'Noida';
        claimRecord.ElixirSuite__patient_country_code__c = 'IN';
        claimRecord.ElixirSuite__patient_s_state__c = 'UP';
        claimRecord.ElixirSuite__patient_s_zipcode__c = 201301;
        claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c = 'Father';
        claimRecord.ElixirSuite__insured_address__c = 'Noida';
        claimRecord.ElixirSuite__insured_city__c = 'Noida';
        claimRecord.ElixirSuite__insured_country_code__c = 'IN';
        claimRecord.ElixirSuite__insured_state__c = 'UP';
        claimRecord.ElixirSuite__insured_zipcode__c = 201301;
        claimRecord.ElixirSuite__employment_related__c = 'No';
        claimRecord.ElixirSuite__Auto_Accident_Related__c = 'No';
        claimRecord.ElixirSuite__insured_dob__c = System.today().addYears(-10);
        claimRecord.ElixirSuite__insured_sex__c = 'M';
        claimRecord.ElixirSuite__Place_of_Service__c = 'Delhi';
        claimRecord.ElixirSuite__bill_taxid__c = '123656789';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c = 'E';
        claimRecord.ElixirSuite__Accept_Assignment__c = 'Y';
        claimRecord.ElixirSuite__total_charge__c = 900;
        claimRecord.ElixirSuite__amount_paid__c = 0;
        claimRecord.ElixirSuite__Billing_Provider_Name__c = 'ATHENA';
        claimRecord.ElixirSuite__Billing_Provider_Address_1__c = 'Watertown';
        claimRecord.ElixirSuite__Billing_Provider_State__c = 'CA';
        claimRecord.ElixirSuite__Billing_Provider_Zip__c = '232329998';
        claimRecord.ElixirSuite__Bill_Phone__c = '4152155300';
        claimRecord.ElixirSuite__Billing_Provider_City__c = 'Watertown';
        claimRecord.ElixirSuite__Diag_1__c = 'B86';
        insert claimRecord;
        System.assertNotEquals(claimRecord.Id, null);
        string claimName = [select id,name from ElixirSuite__Claim__c Limit 1].Name;
        System.debug('claimName'+claimName);
        test.startTest();
        String json = '[{"fields":"place_of_service_1","mesgid":"PH305-01","status":"R","message":"Invalid Place of Service [DELHI]"},{"fields":"pat_rel","mesgid":"ERPREL","status":"R","message":"Invalid Patient relationship code [FATHER]"}]';
        String json2 = '{"claim" : [{"batchid":"59575","bill_npi":"1111111112", "bill_taxid" : "7555555555", "claimid" : "ABCD1", "claimmd_id" : "136961467", "fdos" : "2011-05-01", "fileid" : "000428594", "filename" : "myfile.x12" ,"ins_number":"507883714", "payerid":"60054", "pcn":"0000017262","total_charge":30.00, "status":"R", "message":[{"fields":"payerid","mesgid":"ERPR1", "message":"Invalidor UnsupportedPayerID [8772]","status":"R" }] }]}';	
        String xml = '<root><claim><element><batchid>59575</batchid><bill_npi>1111111112</bill_npi><bill_taxid>7555555555</bill_taxid><claimid>ABCD1</claimid><claimmd_id>136961467</claimmd_id><fdos>2011-05-01</fdos><fileid>000428594</fileid><filename>myfile.x12</filename><ins_number>507883714</ins_number><message><element><fields>payerid</fields><mesgid>ERPR1</mesgid><message>Invalidor UnsupportedPayerID [8772]</message><status>R</status></element></message><payerid>60054</payerid><pcn>0000017262</pcn><status>R</status><total_charge>30.0</total_charge></element></claim></root>';
        string body = '<claims><claim remote_claimid="'+claimName+'" pcn="Claim0576" pat_name_l="David" pat_name_f="Beckam" bill_npi="null" payerid="null" payer_name="LIC" ins_number="null" pat_dob="05-10-1981" pat_sex="M" ins_name_f="Beckam" ins_name_l="Beckam" payer_order="Primary" pat_addr_1="Noida"/></claims>';
        string xml1 = '<result messages="Received 1 claims in file: RSB.txt"><claim batchid="" bill_npi="1245405026" bill_taxid="854785154" claimid="'+claimName+'" claimmd_id="450697363" fdos="2023-05-10" fileid="" filename="RSB.txt" ins_number="7771" payerid="60054" pcn="'+claimName+'" remote_claimid="'+claimName+'" sender_icn="" sender_name="CLAIM.MD" senderid="CLMMD" status="A" total_charge="7700.85"><messages fields="" mesgid="ACK" message="Acknowledged" status="A" /></claim></result>';
        ClaimJsonResponse.parse(json2);
        ClaimJsonResponse.ClaimUpdation(xml1);
        test.stopTest();
    }

}
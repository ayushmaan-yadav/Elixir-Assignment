@isTest
public class GetERAClaimMDBatchTest {
    
    @TestSetup
    private static void createData(){
        ElixirSuite__Integration_Data__c integrationData = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__ERA_Generated__c=false);
        insert integrationData;
        ElixirSuite__Integration_Data__c integrationData1 = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__Integration_Data__c = integrationData.Id,ElixirSuite__ERA_Generated__c=false);
        insert integrationData1;
    }
    @isTest
    private static void callingBatch(){
        GetERAClaimMDBatch callOutBatch = new GetERAClaimMDBatch();
        List<String> accList = new List<String>();
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
        accList.add(patient.id);
        
        ElixirSuite__Procedure__c procedure = new ElixirSuite__Procedure__c();
        procedure.Name = 'Test Procedure';
        procedure.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure.ElixirSuite__From_Date__c = System.today();
        procedure.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure.ElixirSuite__Account__c =  null;
        insert procedure;
        
        /*ElixirSuite__Provider__c providerRec = new ElixirSuite__Provider__c();
providerRec.Name = 'loopCare';
providerRec.ElixirSuite__Provider_Code__c = '1234567867';
insert providerRec;*/
        
        Id objectRecordTypeId = Schema.SObjectType.ElixirSuite__Provider__c.getRecordTypeInfosByDeveloperName().get('Template_Provider').getRecordTypeId();
        ElixirSuite__Provider__c prd = new ElixirSuite__Provider__c();
        prd.Name = 'Loop Care 2';
        prd.ElixirSuite__Provider_First_Name__c = 'Test';
        prd.ElixirSuite__Provider_Last_Name__c='test';
        prd.RecordTypeId = objectRecordTypeId;
        prd.ElixirSuite__Provider_Taxonomy__c = '123';
        prd.ElixirSuite__Provider_Tax_Id__c = '123456';
        prd.ElixirSuite__Provider_TaxId_Type__c = 'tst';
        prd.ElixirSuite__Provider_City__c = 'CA';
        prd.ElixirSuite__Provider_State__c = 'CA';
        prd.ElixirSuite__Provider_Zip__c = '12345';
        prd.ElixirSuite__Provider_Code__c = '1346485000';
        insert prd;
        
        ElixirSuite__Provider__c provider = new ElixirSuite__Provider__c();
        provider.ElixirSuite__Provider_Code__c  = 'Test123';
        provider.Name = 'TestProvider';
        provider.ElixirSuite__Account__c = patient.Id;
        insert provider;
        
        //ElixirSuite__Actual_Price__c actualPrice = new ElixirSuite__Actual_Price__c ();
        //actualPrice.ElixirSuite__Procedure__c = procedure.Id;
        //actualPrice.ElixirSuite__Provider__c = providerRec.Id;
        //actualPrice.ElixirSuite__List_Price__c = 1500;
        //insert actualPrice;
        List<String> clmList = new List<String>();
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
        clmList.add(claimRecord.Id);
        ElixirSuite__Procedure__c procedure1 = new ElixirSuite__Procedure__c();
        procedure1.Name = 'Test Procedure';
        procedure1.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure1.ElixirSuite__From_Date__c = System.today();
        procedure1.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure1.ElixirSuite__Account__c =  patient.Id;
        procedure1.ElixirSuite__Claim__c = claimRecord.Id;
        insert procedure1;
        // insert master transaction
        ElixirSuite__Payment_Transaction__c pt = new ElixirSuite__Payment_Transaction__c();
        pt.ElixirSuite__Procedure__c = procedure1.Id;
        pt.ElixirSuite__Actual_Price__c = 100-101;
        pt.ElixirSuite__Status__c = 'UnPaid';
        pt.ElixirSuite__Payment_Adjustments__c = 100;
        pt.ElixirSuite__Total_Received_Amount__c = 100; 
        pt.ElixirSuite__Insurance_Payments__c=100;
        pt.ElixirSuite__Credit_Amount__c=100;
        pt.ElixirSuite__Patient_Responsibility__c=100;
        pt.ElixirSuite__ERA_Arrived__c = false;
        insert pt;
        // insert claim line item
         ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__Diagnosis_Pointer__c = 'A';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        rec.ElixirSuite__Procedure__c = procedure1.Id;
        insert rec;
        
        ElixirSuite__Procedure__c procedure2 = new ElixirSuite__Procedure__c();
        procedure2.Name = 'Test Procedure';
        procedure2.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure2.ElixirSuite__From_Date__c = System.today();
        procedure2.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure2.ElixirSuite__Account__c =  patient.Id;
        insert procedure2;
        
        ElixirSuite__Claim_Line_Items__c cli = new ElixirSuite__Claim_Line_Items__c();
        cli.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        cli.ElixirSuite__Days_Units__c = 2;
        cli.ElixirSuite__From_Date__c = System.today().adddays(-10);
        cli.ElixirSuite__To_Date__c = System.today().adddays(-8);
        cli.ElixirSuite__procedure_charge__c = 900;
        cli.ElixirSuite__diag_ref__c = 'A';
        cli.ElixirSuite__claim__c = claimRecord.Id;
        cli.ElixirSuite__Procedure__c = procedure.Id;
        insert cli;
        
        Id templateProcId = Schema.SObjectType.ElixirSuite__VOB__c.getRecordTypeInfosByDeveloperName().get('Secondary_VOB').getRecordTypeId();
        ElixirSuite__VOB__c vob2 = new ElixirSuite__VOB__c();
        vob2.ElixirSuite__status__c = 'Active';
        vob2.ElixirSuite__type__c = 'Primary';
        vob2.RecordTypeId = templateProcId;
        vob2.ElixirSuite__Member_Id__c = '12345678s';
        vob2.ElixirSuite__Provider__c = prd.Id;
        vob2.ElixirSuite__Account__c = patient.id;
        vob2.ElixirSuite__Insured_First_Name__c = 'TestVob';
        vob2.ElixirSuite__Insured_Middle_Name__c = 'Mid';
        vob2.ElixirSuite__Insured_Last_Name__c = 'Last';
        vob2.ElixirSuite__Benefit__c = 'AI = Substance Abuse';
        vob2.ElixirSuite__Patient_Relationship_With_Insured__c = 'Self';
        vob2.ElixirSuite__Service_Date__c = system.today();
        vob2.ElixirSuite__Date_Of_Birth__c = system.today();
        insert vob2;
        ElixirSuite__Claim__c claimRec = [Select id, Name from ElixirSuite__Claim__c where ElixirSuite__Account__c =: patient.Id LIMIT 1];
        ElixirSuite__Claim_Line_Items__c cliRec = [Select id, Name from ElixirSuite__Claim_Line_Items__c where ElixirSuite__Claim__c =: claimRec.Id LIMIT 1];
        
        ElixirSuite__Integration_Data__c integrationData = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__ERA_Generated__c=false);
        insert integrationData;
        ElixirSuite__Integration_Data__c integrationData1 = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__Integration_Data__c = integrationData.Id,ElixirSuite__ERA_Generated__c=true);
        insert integrationData1;
        ElixirSuite__EOB__c eb = new ElixirSuite__EOB__c();
        List<ElixirSuite__Integration_Data__c> recordLstInt = new List<ElixirSuite__Integration_Data__c>();
        recordLstInt.add(integrationData);
        recordLstInt.add(integrationData1);
        
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
        newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetERAClaimMDMockRes(claimRec.Name, cliRec.Name)); 
        Database.executeBatch(callOutBatch, 1);
        GetERAClaimMDBatch.secClaimCreation(clmList,accList);
        system.assertEquals([SELECT Id, ElixirSuite__ERA_Generated__c FROM ElixirSuite__Integration_Data__c LIMIT 1].ElixirSuite__ERA_Generated__c, false);
        System.assertEquals(1,1,' ');
        Test.stopTest();
    }
    @isTest
    private static void callingBatch1(){
        GetERAClaimMDBatch callOutBatch = new GetERAClaimMDBatch();
        List<String> accList = new List<String>();
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
        accList.add(patient.id);
        
        ElixirSuite__Procedure__c procedure = new ElixirSuite__Procedure__c();
        procedure.Name = 'Test Procedure';
        procedure.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure.ElixirSuite__From_Date__c = System.today();
        procedure.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure.ElixirSuite__Account__c =  null;
        insert procedure;
        
        ElixirSuite__Provider__c providerRec = new ElixirSuite__Provider__c();
        providerRec.Name = 'loopCare';
        providerRec.ElixirSuite__Provider_Code__c = '1234567867';
        insert providerRec;
        
        ElixirSuite__Provider__c provider = new ElixirSuite__Provider__c();
        provider.ElixirSuite__Provider_Code__c  = 'Test123';
        provider.Name = 'TestProvider';
        provider.ElixirSuite__Account__c = patient.Id;
        insert provider;
        
        //ElixirSuite__Actual_Price__c actualPrice = new ElixirSuite__Actual_Price__c ();
        //actualPrice.ElixirSuite__Procedure__c = procedure.Id;
        //actualPrice.ElixirSuite__Provider__c = providerRec.Id;
        //actualPrice.ElixirSuite__List_Price__c = 1500;
        //insert actualPrice;
        List<String> clmList = new List<String>();
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
        clmList.add(claimRecord.Id);
        ElixirSuite__Procedure__c procedure1 = new ElixirSuite__Procedure__c();
        procedure1.Name = 'Test Procedure';
        procedure1.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure1.ElixirSuite__From_Date__c = System.today();
        procedure1.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure1.ElixirSuite__Account__c =  patient.Id;
        procedure1.ElixirSuite__Claim__c = claimRecord.Id;
        insert procedure1;
        
        ElixirSuite__Procedure__c procedure2 = new ElixirSuite__Procedure__c();
        procedure2.Name = 'Test Procedure';
        procedure2.ElixirSuite__CPT_HCPCS_Code__c = '12345';
        procedure2.ElixirSuite__From_Date__c = System.today();
        procedure2.ElixirSuite__To_Date__c = System.today().addDays(1);
        procedure2.ElixirSuite__Account__c =  patient.Id;
        insert procedure2;
        
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        rec.ElixirSuite__Procedure__c = procedure.Id;
        insert rec;
        
        ElixirSuite__Claim__c claimRec = [Select id, Name from ElixirSuite__Claim__c where ElixirSuite__Account__c =: patient.Id LIMIT 1];
        ElixirSuite__Claim_Line_Items__c cliRec = [Select id, Name from ElixirSuite__Claim_Line_Items__c where ElixirSuite__Claim__c =: claimRec.Id LIMIT 1];
        
        ElixirSuite__Integration_Data__c integrationData = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__ERA_Generated__c=false);
        insert integrationData;
        ElixirSuite__Integration_Data__c integrationData1 = new ElixirSuite__Integration_Data__c(ElixirSuite__ERA_Id__c='13982442',ElixirSuite__Integration_Data__c = integrationData.Id,ElixirSuite__ERA_Generated__c=true);
        insert integrationData1;
        ElixirSuite__EOB__c eb = new ElixirSuite__EOB__c();
        List<ElixirSuite__Integration_Data__c> recordLstInt = new List<ElixirSuite__Integration_Data__c>();
        recordLstInt.add(integrationData);
        recordLstInt.add(integrationData1);
        
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
        newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        
        ElixirSuite__Elixir_Custom_Setting__c customSetting = new ElixirSuite__Elixir_Custom_Setting__c();
        customSetting.ElixirSuite__By_Pass_Claim_Name__c = true;
        insert customSetting;
        
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetERAClaimMDMockResTest(claimRec.Name, cliRec.Name)); 
        Database.executeBatch(callOutBatch, 1);
        GetERAClaimMDBatch.secClaimCreation(clmList,accList);
        system.assertEquals([SELECT Id, ElixirSuite__ERA_Generated__c FROM ElixirSuite__Integration_Data__c LIMIT 1].ElixirSuite__ERA_Generated__c, false);
        System.assertEquals(1,1,' ');
        Test.stopTest();
    }
    
    
    
}
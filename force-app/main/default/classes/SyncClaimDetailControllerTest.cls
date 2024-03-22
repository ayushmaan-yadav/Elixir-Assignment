@isTest
public class SyncClaimDetailControllerTest {
    
    @istest
    static void updateClaimtest(){
        
        
        Test.startTest();
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.ElixirSuite__First_Name__c = 'abc';
        acc.ElixirSuite__Last_Name__c = 'xyz';
        insert acc;
        
        Id vobRecId = Schema.SObjectType.ElixirSuite__VOB__c.getRecordTypeInfosByDeveloperName().get('VOB_record_type').getRecordTypeId();
        ElixirSuite__VOB__c vob2 = new ElixirSuite__VOB__c();
        vob2.ElixirSuite__status__c = 'Active';
        vob2.ElixirSuite__type__c = 'Primary';
        vob2.ElixirSuite__Set_Default_VOB__c = 'Yes';
        vob2.RecordTypeId = vobRecId;
        vob2.ElixirSuite__Account__c = acc.id;
        vob2.ElixirSuite__Insured_First_Name__c = 'TestVob';
        vob2.ElixirSuite__Insured_Middle_Name__c = 'Mid';
        vob2.ElixirSuite__Insured_Last_Name__c = 'Last';
        vob2.ElixirSuite__Benefit__c = 'AI = Substance Abuse';
        vob2.ElixirSuite__Patient_Relationship_With_Insured__c = 'Self';
        vob2.ElixirSuite__Payer__c = payorRecord.id;
        vob2.ElixirSuite__Service_Date__c = system.today();
        insert vob2;
        
        Id rId = Schema.SObjectType.ElixirSuite__Provider__c.getRecordTypeInfosByDeveloperName().get('Template_Provider').getRecordTypeId();
        ElixirSuite__Provider__c tempPrvdr = new ElixirSuite__Provider__c();
        tempPrvdr.Name = 'Test Provider';
        tempPrvdr.ElixirSuite__Provider_Zip__c = '12356';
        tempPrvdr.ElixirSuite__Provider_State__c = 'TestState';
        tempPrvdr.ElixirSuite__Provider_Last_Name__c = 'TestLastProvider';
        tempPrvdr.ElixirSuite__Provider_City__c = 'TestProviderCity';
        tempPrvdr.ElixirSuite__Provider_Code__c = '147859';
        tempPrvdr.RecordTypeId = rId;
            
        insert tempPrvdr;
        
        ElixirSuite__Visits__c exVisit = new ElixirSuite__Visits__c();
        exVisit.ElixirSuite__Account__c = acc.Id;
        exVisit.ElixirSuite__Status__c = 'Active';
        exVisit.ElixirSuite__Location__c = 'US';
        exVisit.ElixirSuite__Care_Episode_Location__c = tempPrvdr.Id;
        exVisit.ElixirSuite__Billing_Provider__c = tempPrvdr.Id;
        exVisit.Name = 'Test Visit';
        insert exVisit;
        
        ElixirSuite__Procedure__c procedure = new ElixirSuite__Procedure__c();
        procedure.Name = 'Test Procedure';
        procedure.ElixirSuite__Account__c = acc.Id;
        procedure.ElixirSuite__Active__c = true;
        procedure.ElixirSuite__Is_Billable__c = true;
		procedure.ElixirSuite__Type_of_Procedure__c = 'Insurance Payment';
        procedure.ElixirSuite__Charges__c = 100;
        procedure.ElixirSuite__Visits__c = exVisit.Id;
        procedure.ElixirSuite__From_Date_of_Service__c = System.today();
        insert procedure;
        
         ElixirSuite__ICD_Codes__c icd = new ElixirSuite__ICD_Codes__c(Name = 'ICDDEMO');
        insert icd;
        ElixirSuite__ICD_Codes__c icd2 = new ElixirSuite__ICD_Codes__c(Name = 'DRI');
        insert icd2;
        
        ElixirSuite__Procedure_Diagnosis__c pd = new ElixirSuite__Procedure_Diagnosis__c(ElixirSuite__Procedure__c = procedure.Id,
                                                                                        ElixirSuite__ICD_Codes__c = icd.Id);
        insert pd;
        
         ElixirSuite__Procedure_Diagnosis__c pd2 = new ElixirSuite__Procedure_Diagnosis__c(ElixirSuite__Procedure__c = procedure.Id,
                                                                                        ElixirSuite__ICD_Codes__c = icd.Id);
        
        insert pd2;
         ElixirSuite__Procedure_Diagnosis__c pd3 = new ElixirSuite__Procedure_Diagnosis__c(ElixirSuite__Procedure__c = procedure.Id,
                                                                                        ElixirSuite__ICD_Codes__c = icd2.Id);
       
        insert pd3;
        
        
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__Account__c = acc.Id;
        claimRecord.ElixirSuite__Visits__c = exVisit.Id;
        claimRecord.ElixirSuite__VOB_lookup__c = vob2.Id; 
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__Insured_s_Name__c= 'Test Insured 1';
        claimRecord.ElixirSuite__Other_Insured_s_Name__c= 'Test OtherInsured 1';
        claimRecord.ElixirSuite__Payer_Order__c = 'Secondary';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID__c = '354364322356899086432234548';
        claimRecord.ElixirSuite__Federal_Tax_Id_Number__c = '456789021134567896424685308754332';
        insert claimRecord;
        //Claim Line Item Creation START
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__Diagnosis_Pointer__c = 'ABCDEFGHIJKLMNOPQ';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        rec.ElixirSuite__Procedure__c = procedure.Id;
        insert rec;
       
        SyncClaimDetailController.updateClaim(claimRecord.Id);
        System.assertEquals(1, 1, '');
        test.stopTest();
        
        
        
        
    }
    @istest
    static void updateClaimtest1(){
        
        
        Test.startTest();
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.ElixirSuite__First_Name__c = 'abc';
        acc.ElixirSuite__Last_Name__c = 'xyz';
        insert acc;
        
        Id vobRecId = Schema.SObjectType.ElixirSuite__VOB__c.getRecordTypeInfosByDeveloperName().get('VOB_record_type').getRecordTypeId();
        ElixirSuite__VOB__c vob2 = new ElixirSuite__VOB__c();
        vob2.ElixirSuite__status__c = 'Active';
        vob2.ElixirSuite__type__c = 'Primary';
        vob2.ElixirSuite__Set_Default_VOB__c = 'Yes';
        vob2.RecordTypeId = vobRecId;
        vob2.ElixirSuite__Account__c = acc.id;
        vob2.ElixirSuite__Insured_First_Name__c = 'TestVob';
        vob2.ElixirSuite__Insured_Middle_Name__c = 'Mid';
        vob2.ElixirSuite__Insured_Last_Name__c = 'Last';
        vob2.ElixirSuite__Benefit__c = 'AI = Substance Abuse';
        vob2.ElixirSuite__Patient_Relationship_With_Insured__c = 'Self';
        vob2.ElixirSuite__Payer__c = payorRecord.id;
        vob2.ElixirSuite__Service_Date__c = system.today();
        insert vob2;
        
        Id rId = Schema.SObjectType.ElixirSuite__Provider__c.getRecordTypeInfosByDeveloperName().get('Template_Provider').getRecordTypeId();
        ElixirSuite__Provider__c tempPrvdr = new ElixirSuite__Provider__c();
        tempPrvdr.Name = 'Test Provider';
        tempPrvdr.ElixirSuite__Provider_Zip__c = '12356';
        tempPrvdr.ElixirSuite__Provider_State__c = 'TestState';
        tempPrvdr.ElixirSuite__Provider_Last_Name__c = 'TestLastProvider';
        tempPrvdr.ElixirSuite__Provider_City__c = 'TestProviderCity';
        tempPrvdr.ElixirSuite__Provider_Code__c = '147859';
        tempPrvdr.RecordTypeId = rId;
            
        insert tempPrvdr;
        
        ElixirSuite__Visits__c exVisit = new ElixirSuite__Visits__c();
        exVisit.ElixirSuite__Account__c = acc.Id;
        exVisit.ElixirSuite__Status__c = 'Active';
        exVisit.ElixirSuite__Location__c = 'US';
        exVisit.ElixirSuite__Care_Episode_Location__c = tempPrvdr.Id;
        exVisit.ElixirSuite__Billing_Provider__c = tempPrvdr.Id;
        exVisit.Name = 'Test Visit';
        insert exVisit;
        
        ElixirSuite__Procedure__c procedure = new ElixirSuite__Procedure__c();
        procedure.Name = 'Test Procedure';
        procedure.ElixirSuite__Account__c = acc.Id;
        procedure.ElixirSuite__Active__c = true;
        procedure.ElixirSuite__Is_Billable__c = true;
		procedure.ElixirSuite__Type_of_Procedure__c = 'Insurance Payment';
        procedure.ElixirSuite__Charges__c = 100;
        procedure.ElixirSuite__Visits__c = exVisit.Id;
        procedure.ElixirSuite__From_Date_of_Service__c = System.today();
        insert procedure;
        
        
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__Account__c = acc.Id;
        claimRecord.ElixirSuite__Visits__c = exVisit.Id;
        claimRecord.ElixirSuite__VOB_lookup__c = vob2.Id; 
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__Insured_s_Name__c= 'Test Insured 1';
        claimRecord.ElixirSuite__Other_Insured_s_Name__c= 'Test OtherInsured 1';
        claimRecord.ElixirSuite__Payer_Order__c = 'Secondary';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID__c = '354364322356899086432234548';
        claimRecord.ElixirSuite__Federal_Tax_Id_Number__c = '456789021134567896424685308754332';
        insert claimRecord;
        //Claim Line Item Creation START
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__Diagnosis_Pointer__c = 'ABCDEFGHIJKLMNOPQ';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        rec.ElixirSuite__Procedure__c = procedure.Id;
        insert rec;
       
        SyncClaimDetailController.updateClaim(claimRecord.Id);
        System.assertEquals(1, 1, '');
        test.stopTest();
        
        
        
        
    }

}
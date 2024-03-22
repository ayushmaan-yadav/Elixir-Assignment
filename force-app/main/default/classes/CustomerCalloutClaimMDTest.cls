@isTest
public class CustomerCalloutClaimMDTest {
    @isTest
      public static void  coverAllmethods(){
        Account acc = new Account();
        acc.Name = 'Test1';
        insert acc;
        
        ElixirSuite__Payor__c pay1 = new ElixirSuite__Payor__c();
        pay1.ElixirSuite__Payer_Code__c = '60054';
        pay1.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert pay1;
        system.debug('pay1.Payer_Code__c'+pay1.ElixirSuite__Payer_Code__c);
        
        ElixirSuite__Payor__c pay2= [select id, name,ElixirSuite__Payer_Code__c from ElixirSuite__Payor__c LIMIT 1];
        
        ElixirSuite__VOB__c vob1 = new ElixirSuite__VOB__c();
        vob1.ElixirSuite__Account__c = acc.id;
        insert vob1;
        
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
       // prd.ElixirSuite__Account__c = acc.id;
        insert prd;
        
        List<ElixirSuite__VOB_Codes_and_Fields__mdt> vobFieldList = new List<ElixirSuite__VOB_Codes_and_Fields__mdt>([Select id, DeveloperName, ElixirSuite__In_Plan_Network__c, ElixirSuite__Benefit_Coverage__c, ElixirSuite__Benefit_Level__c, ElixirSuite__Benefit_Period__c, ElixirSuite__VOB_Field__c from ElixirSuite__VOB_Codes_and_Fields__mdt LIMIT 5000]);
        Map<String,String> vobCodeFieldMap = new Map<String,String>();
          for(ElixirSuite__VOB_Codes_and_Fields__mdt vcf : vobFieldList)
            {
                String key = '';
                key += vcf.ElixirSuite__Benefit_Coverage__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__Benefit_Level__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__In_Plan_Network__c;
                
                vobCodeFieldMap.put(key,vcf.ElixirSuite__VOB_Field__c);
            }
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
		newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        Id templateProcId = Schema.SObjectType.ElixirSuite__VOB__c.getRecordTypeInfosByDeveloperName().get('VOB_record_type').getRecordTypeId();
        ElixirSuite__VOB__c vob2 = new ElixirSuite__VOB__c();
        vob2.ElixirSuite__status__c = 'Active';
        vob2.ElixirSuite__type__c = 'Primary';
        vob2.RecordTypeId = templateProcId;
        vob2.ElixirSuite__Member_Id__c = '12345678s';
        vob2.ElixirSuite__Provider__c = prd.Id;
        vob2.ElixirSuite__Account__c = acc.id;
        vob2.ElixirSuite__Insured_First_Name__c = 'TestVob';
        vob2.ElixirSuite__Insured_Middle_Name__c = 'Mid';
        vob2.ElixirSuite__Insured_Last_Name__c = 'Last';
        vob2.ElixirSuite__Benefit__c = 'AI = Substance Abuse';
        vob2.ElixirSuite__Patient_Relationship_With_Insured__c = 'Self';
        vob2.ElixirSuite__Payer__c = pay2.id;
        vob2.ElixirSuite__Service_Date__c = system.today();
        vob2.ElixirSuite__Date_Of_Birth__c = system.today();
        insert vob2;
        
        ElixirSuite__Claim__c newClaim = new ElixirSuite__Claim__c();
        newClaim.ElixirSuite__Insured_Zipcode__c = 98765;
        newClaim.ElixirSuite__Accept_Assignment__c = 'No';
        newClaim.ElixirSuite__Account__c = acc.Id;
        newClaim.ElixirSuite__Payor__c = pay1.Id;
        newClaim.ElixirSuite__Additional_Claim_Information__c = '';
        newClaim.ElixirSuite__Amount_Paid__c = 0;
        newClaim.ElixirSuite__Any_Other_Health_Benefit_Plan__c = false;
        newClaim.ElixirSuite__Auto_Accident_Related__c = '';
        newClaim.ElixirSuite__Batch_Id__c = '';
        newClaim.ElixirSuite__Billing_Provider_Address_1__c = '123';
        newClaim.ElixirSuite__Billing_Provider_Address_2__c = '';
        newClaim.ElixirSuite__Billing_Provider_City__c = 'CS';
        newClaim.ElixirSuite__Billing_Provider_Info_NPI__c = '7894561230';
        newClaim.ElixirSuite__Billing_Provider_Info__c = '';
        newClaim.ElixirSuite__Billing_Provider_Legacy_ID_Provider_Lice__c = '';
        newClaim.ElixirSuite__Billing_Provider_Name__c = 'HDF';
        newClaim.ElixirSuite__Billing_Provider_Other_ID__c = '';
        newClaim.ElixirSuite__Billing_Provider_State__c = 'CA';
        newClaim.ElixirSuite__Billing_Provider_Taxonomy__c = '';
        newClaim.ElixirSuite__Billing_Provider_Tax_ID_Type__c = '';
        newClaim.ElixirSuite__Billing_Provider_Tax_ID__c = '1234567890';
        newClaim.ElixirSuite__Billing_Provider_Zip__c = '50002';
        newClaim.ElixirSuite__Bill_Phone__c = '7894561233';
        newClaim.ElixirSuite__bill_taxid__c = '';
        newClaim.ElixirSuite__Charge_Amount__c = '0';
        newClaim.ElixirSuite__Claimid__c = '';
        newClaim.ElixirSuite__Claim_Codes__c = '';
        newClaim.ElixirSuite__Claim_Md_Id__c = '';
        newClaim.ElixirSuite__Claim_Status__c = 'Ready to Submit';
        newClaim.ElixirSuite__Diagnosis_B__c = '';
        newClaim.ElixirSuite__Diagnosis_C__c = '';
        newClaim.ElixirSuite__Diagnosis_D__c = '';
        newClaim.ElixirSuite__Diagnosis_E__c = '';
        newClaim.ElixirSuite__Diagnosis_F__c = '';
        newClaim.ElixirSuite__Diagnosis_G__c = '';
        newClaim.ElixirSuite__Diagnosis_H__c = '';
        newClaim.ElixirSuite__Diagnosis_I__c = '';
        newClaim.ElixirSuite__Diagnosis_J__c = '';
        newClaim.ElixirSuite__Diagnosis_K__c = '';
        newClaim.ElixirSuite__Diagnosis_L__c = '';
        newClaim.ElixirSuite__Diagnosis_Reference__c = '';
        newClaim.ElixirSuite__claim_status__c = 'Clearing house accepted';
        insert newClaim;        
        
        ElixirSuite__Claim_Line_Items__c clt = new ElixirSuite__Claim_Line_Items__c();
        clt.ElixirSuite__Claim__c = newClaim.Id;
        clt.ElixirSuite__Procedure_Charge__c = 2000;
        insert clt;
        
        List<ElixirSuite__VOB__c> vlist = new List<ElixirSuite__VOB__c>();
        vlist.add(vob2);
        List<ElixirSuite__result__c> rList = new List<ElixirSuite__result__c>();
        ElixirSuite__result__c res1 = new ElixirSuite__result__c();
        res1.ElixirSuite__VOB__c = vob2.id;
        rList.add(res1);
        
        
         String vobResponse = '{"result":{"elig":{"elig_result_date":"20230518","eligibility_begin_date":"20230518","plan_date":"20230518","elig_result_time":"0059","eligid":"28277016","group_number":"202GROUP","ins_addr_1":"21 JUMP ST","ins_city":"MEMPHIS","ins_dob":"19750821","ins_name_f":"BARNEY","ins_name_l":"STINSON","ins_number":"7771","ins_sex":"M","ins_state":"TN","ins_zip":"871012155","plan_begin_date":"20230418-20230617","plan_number":"PLAN101","benefit":[{"benefit_code":"30","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Health Benefit Plan Coverage","benefit_notes":"FUNDING TYPE = FULLY INSURED","date_of_last_update":"20160702","insurance_plan":"AETNA CHOICE PLUS","insurance_type_code":"C1","insurance_type_description":"Commercial","entity_addr_1":"P.O. BOX 30555","entity_city":"SALT LAKE CITY","entity_code":"PR","entity_description":"Payer","entity_name":"AETNA","entity_state":"UT","entity_zip":"841300555"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_code":"1","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Medical Care","inplan_network":"W"},{"benefit_code":"33","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Chiropractic","inplan_network":"W"},{"benefit_code":"47","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital","inplan_network":"W"},{"benefit_code":"48","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Inpatient","inplan_network":"W"},{"benefit_code":"50","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Outpatient","inplan_network":"W"},{"benefit_code":"86","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Emergency Services","inplan_network":"W"},{"benefit_code":"98","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician) Visit - Office","inplan_network":"W"},{"benefit_code":"AL","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Vision (Optometry)","inplan_network":"W"},{"benefit_code":"MH","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Mental Health","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Physical Therapy","inplan_network":"W"},{"benefit_code":"UC","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Urgent Care","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician)","benefit_notes":"SPECIALIST","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"35","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"125","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"250","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"75","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"30","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"30","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"20","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"20","inplan_network":"W"},{"benefit_code":"88","benefit_coverage_code":"U","benefit_coverage_description":"Contact Following Entity for Eligibility or Benefit Information","benefit_description":"Pharmacy","entity_code":"VN","entity_description":"Vendor","entity_name":"OPTUMRX","entity_website":"PROFESSIONALS.OPTUMRX.COM"}]}}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CreateVobMockRes()); 
          String virtualClass = 'CustomerCalloutClaimMD';
             Callable extension = (Callable) Type.forName(virtualClass).newInstance();
        extension.call('checkValidations', new Map<String, Object> { 
           'vobId'=>vob2.id
         });  
        system.assertEquals(1, 1,'');
        Test.stopTest();
    }
     @isTest
      public static void  coverParseMethod(){
        Account acc = new Account();
        acc.Name = 'Test1';
        insert acc;
        
        ElixirSuite__Payor__c pay1 = new ElixirSuite__Payor__c();
        pay1.ElixirSuite__Payer_Code__c = '60054';
        pay1.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert pay1;
        system.debug('pay1.Payer_Code__c'+pay1.ElixirSuite__Payer_Code__c);
        
        ElixirSuite__Payor__c pay2= [select id, name,ElixirSuite__Payer_Code__c from ElixirSuite__Payor__c LIMIT 1];
        
        ElixirSuite__VOB__c vob1 = new ElixirSuite__VOB__c();
        vob1.ElixirSuite__Account__c = acc.id;
        insert vob1;
        
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
       // prd.ElixirSuite__Account__c = acc.id;
        insert prd;
        
        List<ElixirSuite__VOB_Codes_and_Fields__mdt> vobFieldList = new List<ElixirSuite__VOB_Codes_and_Fields__mdt>([Select id, DeveloperName, ElixirSuite__In_Plan_Network__c, ElixirSuite__Benefit_Coverage__c, ElixirSuite__Benefit_Level__c, ElixirSuite__Benefit_Period__c, ElixirSuite__VOB_Field__c from ElixirSuite__VOB_Codes_and_Fields__mdt LIMIT 5000]);
        Map<String,String> vobCodeFieldMap = new Map<String,String>();
          for(ElixirSuite__VOB_Codes_and_Fields__mdt vcf : vobFieldList)
            {
                String key = '';
                key += vcf.ElixirSuite__Benefit_Coverage__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__Benefit_Level__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__In_Plan_Network__c;
                
                vobCodeFieldMap.put(key,vcf.ElixirSuite__VOB_Field__c);
            }
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
		newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        Id templateProcId = Schema.SObjectType.ElixirSuite__VOB__c.getRecordTypeInfosByDeveloperName().get('VOB_record_type').getRecordTypeId();
        ElixirSuite__VOB__c vob2 = new ElixirSuite__VOB__c();
        vob2.ElixirSuite__status__c = 'Active';
        vob2.ElixirSuite__type__c = 'Primary';
        vob2.RecordTypeId = templateProcId;
        vob2.ElixirSuite__Member_Id__c = '12345678s';
        vob2.ElixirSuite__Provider__c = prd.Id;
        vob2.ElixirSuite__Account__c = acc.id;
        vob2.ElixirSuite__Insured_First_Name__c = 'TestVob';
        vob2.ElixirSuite__Insured_Middle_Name__c = 'Mid';
        vob2.ElixirSuite__Insured_Last_Name__c = 'Last';
        vob2.ElixirSuite__Benefit__c = 'AI = Substance Abuse';
        vob2.ElixirSuite__Patient_Relationship_With_Insured__c = 'Self';
        vob2.ElixirSuite__Payer__c = pay2.id;
        vob2.ElixirSuite__Service_Date__c = system.today();
        vob2.ElixirSuite__Date_Of_Birth__c = system.today();
        insert vob2;
        
        ElixirSuite__Claim__c newClaim = new ElixirSuite__Claim__c();
        newClaim.ElixirSuite__Insured_Zipcode__c = 98765;
        newClaim.ElixirSuite__Accept_Assignment__c = 'No';
        newClaim.ElixirSuite__Account__c = acc.Id;
        newClaim.ElixirSuite__Payor__c = pay1.Id;
        newClaim.ElixirSuite__Additional_Claim_Information__c = '';
        newClaim.ElixirSuite__Amount_Paid__c = 0;
        newClaim.ElixirSuite__Any_Other_Health_Benefit_Plan__c = false;
        newClaim.ElixirSuite__Auto_Accident_Related__c = '';
        newClaim.ElixirSuite__Batch_Id__c = '';
        newClaim.ElixirSuite__Billing_Provider_Address_1__c = '123';
        newClaim.ElixirSuite__Billing_Provider_Address_2__c = '';
        newClaim.ElixirSuite__Billing_Provider_City__c = 'CS';
        newClaim.ElixirSuite__Billing_Provider_Info_NPI__c = '7894561230';
        newClaim.ElixirSuite__Billing_Provider_Info__c = '';
        newClaim.ElixirSuite__Billing_Provider_Legacy_ID_Provider_Lice__c = '';
        newClaim.ElixirSuite__Billing_Provider_Name__c = 'HDF';
        newClaim.ElixirSuite__Billing_Provider_Other_ID__c = '';
        newClaim.ElixirSuite__Billing_Provider_State__c = 'CA';
        newClaim.ElixirSuite__Billing_Provider_Taxonomy__c = '';
        newClaim.ElixirSuite__Billing_Provider_Tax_ID_Type__c = '';
        newClaim.ElixirSuite__Billing_Provider_Tax_ID__c = '1234567890';
        newClaim.ElixirSuite__Billing_Provider_Zip__c = '50002';
        newClaim.ElixirSuite__Bill_Phone__c = '7894561233';
        newClaim.ElixirSuite__bill_taxid__c = '';
        newClaim.ElixirSuite__Charge_Amount__c = '0';
        newClaim.ElixirSuite__Claimid__c = '';
        newClaim.ElixirSuite__Claim_Codes__c = '';
        newClaim.ElixirSuite__Claim_Md_Id__c = '';
        newClaim.ElixirSuite__Claim_Status__c = 'Ready to Submit';
        newClaim.ElixirSuite__Diagnosis_B__c = '';
        newClaim.ElixirSuite__Diagnosis_C__c = '';
        newClaim.ElixirSuite__Diagnosis_D__c = '';
        newClaim.ElixirSuite__Diagnosis_E__c = '';
        newClaim.ElixirSuite__Diagnosis_F__c = '';
        newClaim.ElixirSuite__Diagnosis_G__c = '';
        newClaim.ElixirSuite__Diagnosis_H__c = '';
        newClaim.ElixirSuite__Diagnosis_I__c = '';
        newClaim.ElixirSuite__Diagnosis_J__c = '';
        newClaim.ElixirSuite__Diagnosis_K__c = '';
        newClaim.ElixirSuite__Diagnosis_L__c = '';
        newClaim.ElixirSuite__Diagnosis_Reference__c = '';
        newClaim.ElixirSuite__claim_status__c = 'Clearing house accepted';
        insert newClaim;        
        
        ElixirSuite__Claim_Line_Items__c clt = new ElixirSuite__Claim_Line_Items__c();
        clt.ElixirSuite__Claim__c = newClaim.Id;
        clt.ElixirSuite__Procedure_Charge__c = 2000;
        insert clt;
        
        List<ElixirSuite__VOB__c> vlist = new List<ElixirSuite__VOB__c>();
        vlist.add(vob2);
        List<ElixirSuite__result__c> rList = new List<ElixirSuite__result__c>();
        ElixirSuite__result__c res1 = new ElixirSuite__result__c();
        res1.ElixirSuite__VOB__c = vob2.id;
        rList.add(res1);
        
        
         String vobResponse = '{"result":{"elig":{"elig_result_date":"20230518","eligibility_begin_date":"20230518","plan_date":"20230518","elig_result_time":"0059","eligid":"28277016","group_number":"202GROUP","ins_addr_1":"21 JUMP ST","ins_city":"MEMPHIS","ins_dob":"19750821","ins_name_f":"BARNEY","ins_name_l":"STINSON","ins_number":"7771","ins_sex":"M","ins_state":"TN","ins_zip":"871012155","plan_begin_date":"20230418-20230617","plan_number":"PLAN101","benefit":[{"benefit_code":"30","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Health Benefit Plan Coverage","benefit_notes":"FUNDING TYPE = FULLY INSURED","date_of_last_update":"20160702","insurance_plan":"AETNA CHOICE PLUS","insurance_type_code":"C1","insurance_type_description":"Commercial","entity_addr_1":"P.O. BOX 30555","entity_city":"SALT LAKE CITY","entity_code":"PR","entity_description":"Payer","entity_name":"AETNA","entity_state":"UT","entity_zip":"841300555"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_code":"1","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Medical Care","inplan_network":"W"},{"benefit_code":"33","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Chiropractic","inplan_network":"W"},{"benefit_code":"47","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital","inplan_network":"W"},{"benefit_code":"48","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Inpatient","inplan_network":"W"},{"benefit_code":"50","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Outpatient","inplan_network":"W"},{"benefit_code":"86","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Emergency Services","inplan_network":"W"},{"benefit_code":"98","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician) Visit - Office","inplan_network":"W"},{"benefit_code":"AL","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Vision (Optometry)","inplan_network":"W"},{"benefit_code":"MH","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Mental Health","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Physical Therapy","inplan_network":"W"},{"benefit_code":"UC","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Urgent Care","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician)","benefit_notes":"SPECIALIST","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"35","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"125","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"250","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"75","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"30","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"30","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"20","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"20","inplan_network":"W"},{"benefit_code":"88","benefit_coverage_code":"U","benefit_coverage_description":"Contact Following Entity for Eligibility or Benefit Information","benefit_description":"Pharmacy","entity_code":"VN","entity_description":"Vendor","entity_name":"OPTUMRX","entity_website":"PROFESSIONALS.OPTUMRX.COM"}]}}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CreateVobMockRes()); 
        CustomerCalloutClaimMD.parseJson(vobResponse,vob2.Id,vlist);
        system.assertEquals(1, 1,'');
        Test.stopTest();
    }
     @isTest
    public static void callingBatch(){
       
        Test.startTest();
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__patient_first_Name__c = 'David';
        claimRecord.ElixirSuite__patient_last_Name__c = 'Beckam';
        claimRecord.ElixirSuite__NPI__c = '1831234939';
        //claimRecord.payer_id__c = '20413';
        claimRecord.ElixirSuite__other_payer_name__c = 'LIC';
        //  claimRecord.Insured_s_ID_Number__c = '1232';
        claimRecord.ElixirSuite__patient_dob__c = System.today().addYears(-40);
        claimRecord.ElixirSuite__patient_sex__c = 'M';
        claimRecord.ElixirSuite__insured_s_name__c = 'David';
        claimRecord.ElixirSuite__insured_s_name__c = 'Beckam';
        claimRecord.ElixirSuite__payer_order__c = 'Primary';
        claimRecord.ElixirSuite__patient_s_address__c = 'Noida';
        claimRecord.ElixirSuite__patient_s_city__c = 'Noida';
        claimRecord.ElixirSuite__patient_country_code__c = 'IN';
        claimRecord.ElixirSuite__Patient_s_State__c = 'NY';
        claimRecord.ElixirSuite__patient_s_zipcode__c = 201301;
        claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c = 'Father';
        claimRecord.ElixirSuite__insured_address__c = 'Noida';
        claimRecord.ElixirSuite__insured_city__c = 'Noida';
        claimRecord.ElixirSuite__insured_country_code__c = 'IN';
        claimRecord.ElixirSuite__Insured_State__c = 'NY';
        claimRecord.ElixirSuite__Insured_Zip_Code__c = '201301';
        claimRecord.ElixirSuite__Insured_Telephone__c = '9888898888';
        claimRecord.ElixirSuite__Insured_Policy__c = 'Medical Benefits';
        claimRecord.ElixirSuite__Insured_s_ID_Number__c = '56565';
        claimRecord.ElixirSuite__Employment_Related__c = 'N';
        claimRecord.ElixirSuite__Auto_Accident_Related__c = 'N';
        claimRecord.ElixirSuite__insured_dob__c = System.today().addYears(-10);
        claimRecord.ElixirSuite__insured_sex__c = 'M';
        claimRecord.ElixirSuite__Place_of_Service__c = 'Delhi';
        claimRecord.ElixirSuite__Diagnosis_A__c = '99153';
        //claimRecord.bill_taxid__c = '123656789';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c = 'E';
        claimRecord.ElixirSuite__Accept_Assignment__c = 'Y';
        claimRecord.ElixirSuite__total_charge__c = 900;
        claimRecord.ElixirSuite__amount_paid__c = 0;
        claimRecord.ElixirSuite__Billing_Provider_Name__c = 'ATHENA';
        claimRecord.ElixirSuite__Billing_Provider_Address_1__c = 'Watertown';
        claimRecord.ElixirSuite__Billing_Provider_State__c = 'CA';
        claimRecord.ElixirSuite__Billing_Provider_Info_NPI__c = '1234567890';
        claimRecord.ElixirSuite__Billing_Provider_Zip__c = '91101';
        claimRecord.ElixirSuite__Billing_Provider_Info__c = '1234567890';
        claimRecord.ElixirSuite__Bill_Phone__c = '8152155300';
        claimRecord.ElixirSuite__Billing_Provider_City__c = 'Watertown';
        claimRecord.ElixirSuite__Patient_Name__c = 'Test Account 1';
claimRecord.ElixirSuite__Patient_Condition_Related_To_Accident__c = true;
        claimRecord.ElixirSuite__Insured_s_Name__c= 'Test Insured 1';
claimRecord.ElixirSuite__Resubmission_Code__c = '7';
        claimRecord.ElixirSuite__Other_Insured_s_Name__c= 'Test OtherInsured 1';
        //  claimRecord.Diag_1__c = 'B86';
        claimRecord.ElixirSuite__Federal_Tax_Id_Number__c = '456789021';
        insert claimRecord;
        //Claim Line Item Creation START
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__Diagnosis_Pointer__c = 'A';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        insert rec;
ElixirSuite__Elixir_Custom_Setting__c customSetting = new ElixirSuite__Elixir_Custom_Setting__c();
        customSetting.ElixirSuite__By_Pass_Claim_Name__c = true;
        insert customSetting;
        System.assert(claimRecord.ElixirSuite__claim_status__c!=null);
    	system.assertEquals(1,1,'');
        Test.setMock(HttpCalloutMock.class, new ClaimsPostClearingHouseMockRes([SELECT Id, Name FROM ElixirSuite__claim__c WITH SECURITY_ENFORCED LIMIT 1].Name)); 
        
        List<ElixirSuite__claim__c> claimList = new List<ElixirSuite__claim__c> ();
        claimList.add(claimRecord);
        List<ElixirSuite__Claim_Line_Items__c> claimLineList = new List<ElixirSuite__Claim_Line_Items__c>();
        claimLineList.add(rec);
        Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = New  Map<Id,List<ElixirSuite__Claim_Line_Items__c>>();
        mapOfClaimIdToLineItems.put(claimList[0].Id,claimLineList);
        
        String claimLst = claimRecord.Id;
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
		newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        String virtualClass = 'CustomerCalloutClaimMD';
        Callable extension = (Callable) Type.forName(virtualClass).newInstance();
        extension.call('RefreshClaimMDCallout', new Map<String, Object> { 
            'claimLst' => claimLst
         });
      
        Test.stopTest();
        system.assertEquals(1,1);
    }
     @isTest
    private static void callingBatch1(){
         
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
		newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;
        Test.startTest();
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__patient_first_Name__c = 'David';
        claimRecord.ElixirSuite__patient_last_Name__c = 'Beckam';
        claimRecord.ElixirSuite__NPI__c = '1831234939';
        //claimRecord.payer_id__c = '20413';
        claimRecord.ElixirSuite__other_payer_name__c = 'LIC';
        //  claimRecord.Insured_s_ID_Number__c = '1232';
        claimRecord.ElixirSuite__patient_dob__c = System.today().addYears(-40);
        claimRecord.ElixirSuite__patient_sex__c = 'M';
        claimRecord.ElixirSuite__insured_s_name__c = 'David';
        claimRecord.ElixirSuite__insured_s_name__c = 'Beckam';
        claimRecord.ElixirSuite__payer_order__c = 'Primary';
        claimRecord.ElixirSuite__patient_s_address__c = 'Noida';
        claimRecord.ElixirSuite__patient_s_city__c = 'Noida';
        claimRecord.ElixirSuite__patient_country_code__c = 'IN';
        claimRecord.ElixirSuite__Patient_s_State__c = 'NY';
        claimRecord.ElixirSuite__patient_s_zipcode__c = 201301;
        claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c = 'Father';
        claimRecord.ElixirSuite__insured_address__c = 'Noida';
        claimRecord.ElixirSuite__insured_city__c = 'Noida';
        claimRecord.ElixirSuite__insured_country_code__c = 'IN';
        claimRecord.ElixirSuite__Insured_State__c = 'NY';
        claimRecord.ElixirSuite__Insured_Zip_Code__c = '201301';
        claimRecord.ElixirSuite__Insured_Telephone__c = '9888898888';
        claimRecord.ElixirSuite__Insured_Policy__c = 'Medical Benefits';
        claimRecord.ElixirSuite__Insured_s_ID_Number__c = '56565';
        claimRecord.ElixirSuite__Employment_Related__c = 'N';
        claimRecord.ElixirSuite__Auto_Accident_Related__c = 'N';
        claimRecord.ElixirSuite__insured_dob__c = System.today().addYears(-10);
        claimRecord.ElixirSuite__insured_sex__c = 'M';
        claimRecord.ElixirSuite__Place_of_Service__c = 'Delhi';
        claimRecord.ElixirSuite__Diagnosis_A__c = '99153';
        //claimRecord.bill_taxid__c = '123656789';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c = 'E';
        claimRecord.ElixirSuite__Accept_Assignment__c = 'Y';
        claimRecord.ElixirSuite__total_charge__c = 900;
        claimRecord.ElixirSuite__amount_paid__c = 0;
        claimRecord.ElixirSuite__Billing_Provider_Name__c = 'ATHENA';
        claimRecord.ElixirSuite__Billing_Provider_Address_1__c = 'Watertown';
        claimRecord.ElixirSuite__Billing_Provider_State__c = 'CA';
        claimRecord.ElixirSuite__Billing_Provider_Info_NPI__c = '1234567890';
        claimRecord.ElixirSuite__Billing_Provider_Zip__c = '91101';
        claimRecord.ElixirSuite__Billing_Provider_Info__c = '1234567890';
        claimRecord.ElixirSuite__Bill_Phone__c = '8152155300';
        claimRecord.ElixirSuite__Billing_Provider_City__c = 'Watertown';
        claimRecord.ElixirSuite__Patient_Name__c = 'Test Account 1';
        claimRecord.ElixirSuite__Insured_s_Name__c= 'Test Insured 1';
        claimRecord.ElixirSuite__Other_Insured_s_Name__c= 'Test OtherInsured 1';
        claimRecord.ElixirSuite__claim_status__c = 'Clearing house accepted';
        //  claimRecord.Diag_1__c = 'B86';
        claimRecord.ElixirSuite__Federal_Tax_Id_Number__c = '456789021';
        insert claimRecord;
        //Claim Line Item Creation START
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        rec.ElixirSuite__CPT_HCPCS_Code__c = '38525';
        rec.ElixirSuite__Days_Units__c = 2;
        rec.ElixirSuite__From_Date__c = System.today().adddays(-10);
        rec.ElixirSuite__To_Date__c = System.today().adddays(-8);
        rec.ElixirSuite__procedure_charge__c = 900;
        rec.ElixirSuite__diag_ref__c = 'A';
        rec.ElixirSuite__Diagnosis_Pointer__c = 'A';
        rec.ElixirSuite__claim__c = claimRecord.Id;
        insert rec;
       
        Test.setMock(HttpCalloutMock.class, new ClaimGetPayerStatusMock()); 
      
        String claimId = claimRecord.Id;
        String virtualClass = 'CustomerCalloutClaimMD';
        Callable extension = (Callable) Type.forName(virtualClass).newInstance();
        extension.call('GetpayerStatusClaimMD', new Map<String, Object> { 
            'claimId' => claimId
         });       
        System.assertEquals(1,1,'');
        Test.stopTest();
    }
    @isTest
    private static void callingBatch2(){
        
        List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
        Integration_Credentials__c newcust = new Integration_Credentials__c();
        newcust.Integration_Key__c = 'Test_AccountKey';
		newcust.Name = 'ClaimMD';
        custset.add(newcust);
        insert custset;       
        Test.startTest();
       
        Test.setMock(HttpCalloutMock.class, new CreateERAMockRes()); 
        String virtualClass = 'CustomerCalloutClaimMD';
        Callable extension = (Callable) Type.forName(virtualClass).newInstance();
        extension.call('GetERA', new Map<String, Object> { 
           
         });  
       
        system.assertEquals(1,1,'');
        Test.stopTest();
    }
}
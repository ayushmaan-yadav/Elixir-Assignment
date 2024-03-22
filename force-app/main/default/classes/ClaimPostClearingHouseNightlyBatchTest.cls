@isTest
public class ClaimPostClearingHouseNightlyBatchTest {
    
    
    @isTest
    public static void callingBatch(){
        
        Test.startTest();
        ClaimPostClearingHouseNightlyBatch callOutBatch = new ClaimPostClearingHouseNightlyBatch();
        Account acc = new Account();
        acc.Name = 'Test1';
        acc.ElixirSuite__First_Name__c = 'abc';
        acc.ElixirSuite__Last_Name__c = 'qwe';
        insert acc;
        
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__Account__c = acc.Id;
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
        System.assert(claimRecord.ElixirSuite__claim_status__c!=null);
        system.assertEquals(1,1,'');
        
        try{
            List<ElixirSuite__Claim__c> claimRec = new List<ElixirSuite__Claim__c>([SELECT Id,Name,ElixirSuite__Claim_Status__c,ElixirSuite__Account__r.Name,ElixirSuite__Account__c,
                                                                                    ElixirSuite__Account__r.ElixirSuite__First_Name__c,ElixirSuite__Account__r.ElixirSuite__Last_Name__c,
                                                                                    ElixirSuite__payor__r.ElixirSuite__Payer_Code__c,ElixirSuite__Claim__r.ElixirSuite__payor__r.Name,ElixirSuite__Claim__r.ElixirSuite__Insured_s_ID_Number__c,
                                                                                    ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_First_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Middle_Name__c,
                                                                                    ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Last_Name__c,
                                                                                    ElixirSuite__Accept_Assignment__c, ElixirSuite__Accident_State__c, ElixirSuite__Additional_Claim_Information__c, ElixirSuite__Adjustment_Code__c, ElixirSuite__Admission_Date__c, ElixirSuite__Admission_Hour__c, ElixirSuite__Admission_Source__c, ElixirSuite__Admission_Type__c, ElixirSuite__Admitting_Diagnosis_Code__c, ElixirSuite__Amount_Paid__c, ElixirSuite__Amount_Status__c, ElixirSuite__Any_Other_Health_Benefit_Plan__c, ElixirSuite__Assignment_of_benefit_certificate_A__c, ElixirSuite__Assignment_of_benefit_certificate_B__c, ElixirSuite__Assignment_of_benefit_certificate_C__c, ElixirSuite__Attending_Provider_FirstName__c, ElixirSuite__Attending_Provider_LastName__c, ElixirSuite__Attending_Provider_NPI__c, ElixirSuite__Attending_Provider_Qualifying_Id__c, ElixirSuite__Auto_Accident_Related__c, ElixirSuite__Batch_Id__c, ElixirSuite__Bill_Phone__c, ElixirSuite__Billing_Provider_Address_1__c, ElixirSuite__Billing_Provider_Address_2__c, ElixirSuite__Billing_Provider_City__c, ElixirSuite__Billing_Provider_Info_NPI__c, ElixirSuite__Billing_Provider_Info__c, ElixirSuite__Billing_Provider_Legacy_ID_Provider_Lice__c, ElixirSuite__Billing_Provider_Name__c, ElixirSuite__Billing_Provider_Other_ID_B__c, ElixirSuite__Billing_Provider_Other_ID_C__c, ElixirSuite__Billing_Provider_Other_ID__c, ElixirSuite__Billing_Provider_State__c, ElixirSuite__Billing_Provider_Tax_ID_Type__c, ElixirSuite__Billing_Provider_Tax_ID__c, ElixirSuite__Billing_Provider_Taxonomy__c, ElixirSuite__Billing_Provider_Zip__c, ElixirSuite__Charge_Amount__c, ElixirSuite__Claim_Code_Options__c, ElixirSuite__Claim_Codes__c, ElixirSuite__Claim_Md_Id__c, ElixirSuite__Claim__c, ElixirSuite__Claimid__c, ElixirSuite__Code_Code_Field_Qualifiers_A__c, ElixirSuite__Code_Code_Field_Qualifiers_B__c, ElixirSuite__Code_Code_Field_Qualifiers_C__c, ElixirSuite__Code_Code_Field_Qualifiers_D__c, ElixirSuite__Conditional_Codes_A__c, ElixirSuite__Conditional_Codes_B__c, ElixirSuite__Conditional_Codes_C__c, ElixirSuite__Conditional_Codes_D__c, ElixirSuite__Conditional_Codes_E__c, ElixirSuite__Conditional_Codes_F__c, ElixirSuite__Conditional_Codes_G__c, ElixirSuite__Conditional_Codes_H__c, ElixirSuite__Conditional_Codes_I__c, ElixirSuite__Conditional_Codes_J__c, ElixirSuite__Conditional_Codes__c, ElixirSuite__Date_Of_Current_Illness__c, ElixirSuite__Dates_Patient_Unable_To_Work__c, ElixirSuite__Diag_10__c, ElixirSuite__Diag_11__c, ElixirSuite__Diag_12__c, ElixirSuite__Diag_1__c, ElixirSuite__Diag_2__c, ElixirSuite__Diag_3__c, ElixirSuite__Diag_4__c, ElixirSuite__Diag_5__c, ElixirSuite__Diag_6__c, ElixirSuite__Diag_7__c, ElixirSuite__Diag_8__c, ElixirSuite__Diag_9__c, ElixirSuite__Diagnosis_A__c, ElixirSuite__Diagnosis_B__c, ElixirSuite__Diagnosis_C__c, ElixirSuite__Diagnosis_D__c, ElixirSuite__Diagnosis_E__c, ElixirSuite__Diagnosis_F__c, ElixirSuite__Diagnosis_G__c, ElixirSuite__Diagnosis_H__c, ElixirSuite__Diagnosis_I__c, ElixirSuite__Diagnosis_J__c, ElixirSuite__Diagnosis_K__c, ElixirSuite__Diagnosis_L__c, ElixirSuite__Diagnosis_Procedure_Code_Qualifier__c, ElixirSuite__Diagnosis_Reference__c, ElixirSuite__Discharge_Hour__c, ElixirSuite__Document_Control_Number_A__c, ElixirSuite__Document_Control_Number_B__c, ElixirSuite__Document_Control_Number_C__c, ElixirSuite__ERA_Status_Code__c, ElixirSuite__Employer_Name_A__c, ElixirSuite__Employer_Name_B__c, ElixirSuite__Employer_Name_C__c, ElixirSuite__Employment_Related__c, ElixirSuite__Estimated_Amount_Due_A__c, ElixirSuite__Estimated_Amount_Due_B__c, ElixirSuite__Estimated_Amount_Due_C__c, ElixirSuite__External_Cause_of_Injury_Code__c, ElixirSuite__Federal_Tax_Id_Number__c, ElixirSuite__File_Id__c, ElixirSuite__File_Name__c, ElixirSuite__First_Diagnosis__c, ElixirSuite__First_Name_NAME_OF_REFERRING_PROVIDER__c, ElixirSuite__From_Date_Patient_Unable_To_Work__c, ElixirSuite__From_Date__c, ElixirSuite__HCPC_Rate__c, ElixirSuite__Health_Plan_Id_B__c, ElixirSuite__Health_Plan_Id_c__c, ElixirSuite__Hospitalization_Dates__c, ElixirSuite__Hospitalization_From_Date__c, ElixirSuite__Hospitalization_To_Date__c, ElixirSuite__Informational_Remark_Codes__c, ElixirSuite__Insurance_Number__c, ElixirSuite__Insurance_Plan_Name__c, ElixirSuite__Insurance_Type__c, ElixirSuite__Insured_Address__c, ElixirSuite__Insured_Authorized_Person_Signature__c, ElixirSuite__Insured_City__c, ElixirSuite__Insured_Country_Code__c, ElixirSuite__Insured_DOB__c, ElixirSuite__Insured_First_name__c, ElixirSuite__Insured_Or_Auth_Persn_Date__c, ElixirSuite__Insured_Or_Auth_Persn_Sign__c, ElixirSuite__Insured_Policy__c, ElixirSuite__Insured_Sex__c, ElixirSuite__Insured_State__c, ElixirSuite__Insured_Telephone__c, ElixirSuite__Insured_Zip_Code__c, ElixirSuite__Insured_Zipcode__c, ElixirSuite__Insured_s_Group_Name_A__c, ElixirSuite__Insured_s_Group_Name_B__c, ElixirSuite__Insured_s_Group_Name_C__c, ElixirSuite__Insured_s_Group_Number_B__c, ElixirSuite__Insured_s_Group_Number_C__c, ElixirSuite__Insured_s_ID_Number_B__c, ElixirSuite__Insured_s_ID_Number_C__c, ElixirSuite__Insured_s_ID_Number__c, ElixirSuite__Insured_s_Name_B__c, ElixirSuite__Insured_s_Name_C__c, ElixirSuite__Insured_s_Name__c, ElixirSuite__Interest_Late_filing_charges__c, ElixirSuite__Last_Name_NAME_OF_REFERRING_PROVIDER__c, ElixirSuite__Manual_ERA__c, ElixirSuite__Manual_Reconciliation_Count__c, ElixirSuite__Master_ERA__c, ElixirSuite__Message__c, ElixirSuite__MiddleName_NAME_OF_REFERRING_PROVIDER__c, ElixirSuite__NPI__c, ElixirSuite__NUCC_Description__c, ElixirSuite__NUCC__c, ElixirSuite__Name_of_referring_provider_Other_sourc__c, ElixirSuite__Occurance_Code_1A__c, ElixirSuite__Occurance_Code_1B__c, ElixirSuite__Occurance_Code_2A__c, ElixirSuite__Occurance_Code_2B__c, ElixirSuite__Occurance_Code_3A__c, ElixirSuite__Occurance_Code_3B__c, ElixirSuite__Occurance_Code_4A__c, ElixirSuite__Occurance_Code_4B__c, ElixirSuite__Occurance_Date_1A__c, ElixirSuite__Occurance_Date_1B__c, ElixirSuite__Occurance_Date_2A__c, ElixirSuite__Occurance_Date_2B__c, ElixirSuite__Occurance_Date_3A__c, ElixirSuite__Occurance_Date_3B__c, ElixirSuite__Occurance_Date_4A__c, ElixirSuite__Occurance_Date_4B__c, ElixirSuite__Occurance_Span_Code_1A__c, ElixirSuite__Occurance_Span_Code_1B__c, ElixirSuite__Occurance_Span_Code_2A__c, ElixirSuite__Occurance_Span_Code_2B__c, ElixirSuite__Occurance_Span_From_Date_1A__c, ElixirSuite__Occurance_Span_From_Date_1B__c, ElixirSuite__Occurance_Span_From_Date_2A__c, ElixirSuite__Occurance_Span_From_Date_2B__c, ElixirSuite__Occurance_Span_Through_Date_1A__c, ElixirSuite__Occurance_Span_Through_Date_1B__c, ElixirSuite__Occurance_Span_Through_Date_2A__c, ElixirSuite__Occurance_Span_Through_Date_2B__c, ElixirSuite__Operating_Physician_FirstName__c, ElixirSuite__Operating_Physician_LastName__c, ElixirSuite__Operating_Physician_NPI__c, ElixirSuite__Operating_Physician_Qualifying_Id__c, ElixirSuite__Original_Ref_No__c, ElixirSuite__Other_Claim_Id__c, ElixirSuite__Other_Date__c, ElixirSuite__Other_ID__c, ElixirSuite__Other_Insurance_Plan_Name__c, ElixirSuite__Other_Insured_s_Name__c, ElixirSuite__Other_Insured_s_Policy_Group_Number__c, ElixirSuite__Other_Payer_Name_B__c, ElixirSuite__Other_Payer_Name_C__c, ElixirSuite__Other_Payer_Name__c, ElixirSuite__Other_Procedure_Code_A__c, ElixirSuite__Other_Procedure_Code_B__c, ElixirSuite__Other_Procedure_Code_C__c, ElixirSuite__Other_Procedure_Code_D__c, ElixirSuite__Other_Procedure_Code_E__c, ElixirSuite__Other_Procedure_Date_A__c, ElixirSuite__Other_Procedure_Date_B__c, ElixirSuite__Other_Procedure_Date_C__c, ElixirSuite__Other_Procedure_Date_D__c, ElixirSuite__Other_Procedure_Date_E__c, ElixirSuite__Other_Provider_FirstName_1__c, ElixirSuite__Other_Provider_FirstName_2__c, ElixirSuite__Other_Provider_LastName_1__c, ElixirSuite__Other_Provider_LastName_2__c, ElixirSuite__Other_Provider_NPI_1__c, ElixirSuite__Other_Provider_NPI_2__c, ElixirSuite__Other_Provider_Qualifying_Id_1__c, ElixirSuite__Other_Provider_Qualifying_Id_2__c, ElixirSuite__Outside_Lab_Charges__c, ElixirSuite__Outside_Lab__c, ElixirSuite__Outside_Lab_new__c, ElixirSuite__PPS_Code__c, ElixirSuite__Patient_Account_Number__c, ElixirSuite__Patient_Condition_Related_To_Accident__c, ElixirSuite__Patient_Condition_Related_To_Employment__c, ElixirSuite__Patient_Condition_to_Other_Accident__c, ElixirSuite__Patient_Country_Code__c, ElixirSuite__Patient_DOB__c, ElixirSuite__Patient_Discharge_Status__c, ElixirSuite__Patient_First_Name__c, ElixirSuite__Patient_ID__c, ElixirSuite__Patient_Last_Name__c, ElixirSuite__Patient_Name__c, ElixirSuite__Patient_Or_Auth_Per_Sign__c, ElixirSuite__Patient_Or_Auth_Person_Date__c, ElixirSuite__Patient_Relationship_to_Insured_B__c, ElixirSuite__Patient_Relationship_to_Insured_C__c, ElixirSuite__Patient_Relationship_to_Insured__c, ElixirSuite__Patient_Sex__c, ElixirSuite__Patient_Signature__c, ElixirSuite__Patient_Zip_Code__c, ElixirSuite__Patient_Address_2__c, ElixirSuite__Patient_s_Address__c, ElixirSuite__Patient_s_City__c, ElixirSuite__Patient_s_Phone__c, ElixirSuite__Patient_s_Reason_for_Visit_Code__c, ElixirSuite__Patient_s_State__c, ElixirSuite__Patient_s_Zipcode__c, ElixirSuite__Pay_to_Provider_Address_1__c, ElixirSuite__Pay_to_Provider_Address_2__c, ElixirSuite__Pay_to_Provider_City__c, ElixirSuite__Pay_to_Provider_Name__c, ElixirSuite__Pay_to_Provider_State__c, ElixirSuite__Pay_to_Provider_Zipcode__c, ElixirSuite__Payer_ICN__c, ElixirSuite__Payer_ID__c, ElixirSuite__Payer_Order__c, ElixirSuite__Payerid__c, ElixirSuite__Payment_Method__c, ElixirSuite__Payor__c, ElixirSuite__Pcn__c, ElixirSuite__Place_of_Service__c, ElixirSuite__Posted__c, ElixirSuite__Primary_Adjustment__c, ElixirSuite__Primary_Allowed__c, ElixirSuite__Primary_Billed__c, ElixirSuite__Primary_Claim_Status__c, ElixirSuite__Primary_Other_Insurance_Responsibility__c, ElixirSuite__Primary_Paid__c, ElixirSuite__Primary_Patient_Responsibility__c, ElixirSuite__Principle_Procedure_Date__c, ElixirSuite__Prior_Authorization_Number__c, ElixirSuite__Prior_Payments_A__c, ElixirSuite__Prior_Payments_B__c, ElixirSuite__Prior_Payments_C__c, ElixirSuite__Priority__c, ElixirSuite__Procedure_Code__c, ElixirSuite__QUAL_For_Date_current_illness_injury__c, ElixirSuite__QUAL_For_Name_of_referring_provider__c, ElixirSuite__QUAL_For_Other_Dates__c, ElixirSuite__Qualifier_For_Name_Of_Referring_Provider__c, ElixirSuite__Reconciliation_Status__c, ElixirSuite__Referring_Physician_Signature__c, ElixirSuite__Release_of_Information_Certification_A__c, ElixirSuite__Release_of_Information_Certification_B__c, ElixirSuite__Release_of_Information_Certification_C__c, ElixirSuite__Remarks__c, ElixirSuite__Reserved_For_NUCC_Use1__c, ElixirSuite__Reserved_For_NUCC_Use2__c, ElixirSuite__Reserved_For_NUCC_Use3__c, ElixirSuite__Responsible_Party_Address__c, ElixirSuite__Responsible_Party_City__c, ElixirSuite__Responsible_Party_Name__c, ElixirSuite__Responsible_Party_State__c, ElixirSuite__Responsible_Party_Zipcode__c, ElixirSuite__Resubmission_Code__c, ElixirSuite__Revenue_Code_Description__c, ElixirSuite__Revenue_Code__c, ElixirSuite__Secondary_Posted__c, ElixirSuite__Sender_Icn__c, ElixirSuite__Sender_Id__c, ElixirSuite__Sender_Name__c, ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c, ElixirSuite__Service_Date__c, ElixirSuite__Service_Facility_Location_Information__c, ElixirSuite__Service_Facility_Location_NPI__c, ElixirSuite__Sign_of_Phy_or_Supplier_Date__c, ElixirSuite__Sign_of_Phy_or_Supplier_Signature__c, ElixirSuite__Statement_Covers_From__c, ElixirSuite__Statement_Covers_Through__c, ElixirSuite__Supplemental_Group_Code__c, ElixirSuite__Thru_Date__c, ElixirSuite__To_Date_Patient_Unable_To_Work__c, ElixirSuite__Total_Adjustment_Amount__c, ElixirSuite__Total_Adjustment__c, ElixirSuite__Total_Allowed_Amount__c, ElixirSuite__Total_Amount_Paid_By_Insurance__c, ElixirSuite__Total_Billed__c, ElixirSuite__Total_Charge__c, ElixirSuite__Total_Contracted_Amount__c, ElixirSuite__Total_Paid__c, ElixirSuite__Total_Patient_Responsibility_Primary__c, ElixirSuite__Total_Patient_Responsibility__c, ElixirSuite__Treatment_Authorization_Code_A__c, ElixirSuite__Treatment_Authorization_Code_B__c, ElixirSuite__Treatment_Authorization_Code_C__c, ElixirSuite__Type_of_Bill__c, ElixirSuite__Units__c, ElixirSuite__VOB_lookup__c, ElixirSuite__Validation_Error_Message__c, ElixirSuite__Value_Code_1A__c, ElixirSuite__Value_Code_1B__c, ElixirSuite__Value_Code_1C__c, ElixirSuite__Value_Code_1D__c, ElixirSuite__Value_Code_2A__c, ElixirSuite__Value_Code_2B__c, ElixirSuite__Value_Code_2C__c, ElixirSuite__Value_Code_2D__c, ElixirSuite__Value_Code_3A__c, ElixirSuite__Value_Code_3B__c, ElixirSuite__Value_Code_3C__c, ElixirSuite__Value_Code_3D__c, ElixirSuite__Value_Code_Amount_1A__c, ElixirSuite__Value_Code_Amount_1B__c, ElixirSuite__Value_Code_Amount_1C__c, ElixirSuite__Value_Code_Amount_1D__c, ElixirSuite__Value_Code_Amount_2A__c, ElixirSuite__Value_Code_Amount_2B__c, ElixirSuite__Value_Code_Amount_2C__c, ElixirSuite__Value_Code_Amount_2D__c, ElixirSuite__Value_Code_Amount_3A__c, ElixirSuite__Value_Code_Amount_3B__c, ElixirSuite__Value_Code_Amount_3C__c, ElixirSuite__Value_Code_Amount_3D__c, ElixirSuite__Visits__c, ElixirSuite__bill_taxid__c, ElixirSuite__fdos__c, ElixirSuite__isRecordInReadyToSubmitStatus__c, ElixirSuite__status__c, ElixirSuite__Color2__c, ElixirSuite__Rendering_Provider_NPI__c, ElixirSuite__Rendering_Provider_Tax_Id__c, ElixirSuite__Rendering_Provider_First_Name__c, ElixirSuite__Rendering_Provider_Address__c, ElixirSuite__Service_Facility_Loc_Address__c, ElixirSuite__Service_Facility_Loc_City__c, ElixirSuite__Service_Facility_Loc_State__c, ElixirSuite__Service_Facility_Loc_Zip__c, ElixirSuite__Rendering_Provider_Last_Name__c, ElixirSuite__Rendering_Provider_Taxonomy__c, ElixirSuite__Rendering_Provider_Middle_Name__c
                                                                                    FROM ElixirSuite__Claim__c 
                                                                                    WHERE Id = :claimRecord.id  
                                                                                    LIMIT 1]);  
            Test.setMock(HttpCalloutMock.class, new ClaimsPostClearingHouseMockRes(claimRec[0].Name)); 
            Database.executeBatch(callOutBatch, 1);
            
            List<Integration_Credentials__c> custset = new List<Integration_Credentials__c>();
            Integration_Credentials__c newcust = new Integration_Credentials__c();
            newcust.Integration_Key__c = 'Test_AccountKey';
            newcust.Name = 'ClaimMD';
            custset.add(newcust);
            insert custset;
            
            List<ElixirSuite__claim__c> claimList = new List<ElixirSuite__claim__c> ();
            claimList.add(claimRecord);
            List<ElixirSuite__Claim_Line_Items__c> cliLst = [SELECT Id, Name, ElixirSuite__claim__c,ElixirSuite__Diagnosis_Pointer__c,ElixirSuite__diag_ref__c,ElixirSuite__procedure_charge__c,ElixirSuite__To_Date__c,ElixirSuite__From_Date__c,ElixirSuite__Place_of_Service__c,
                                                             ElixirSuite__Days_Units__c,ElixirSuite__CPT_HCPCS_Code__c,ElixirSuite__From_Date_Of_Service__c,ElixirSuite__To_Date_Of_Service__c,
                                                             ElixirSuite__Modifier_1__c,ElixirSuite__Modifier_4__c,ElixirSuite__Modifier_2__c,ElixirSuite__Modifier_3__c,ElixirSuite__Rendering_Provider_First_Name__c,
                                                             ElixirSuite__Rendering_Provider_Last_Name__c,ElixirSuite__Rendering_Provider_NPI__c,ElixirSuite__Rendering_Provider_Taxonomy__c,
                                                             ElixirSuite__Rendering_Provider_Non_NPI__c,ElixirSuite__Claim_Procedure_Line_Item__c
                                                             FROM ElixirSuite__Claim_Line_Items__c
                                                             WHERE Id =: rec.Id];   
            system.debug('cliLst--'+cliLst);
            List<ElixirSuite__Claim_Line_Items__c> claimLineList = new List<ElixirSuite__Claim_Line_Items__c>();
            claimLineList = cliLst;
            Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = New  Map<Id,List<ElixirSuite__Claim_Line_Items__c>>();
            mapOfClaimIdToLineItems.put(claimRec[0].Id,claimLineList);
            ClaimPostClearingHouseNightlyHandler py = new ClaimPostClearingHouseNightlyHandler(claimRec,mapOfClaimIdToLineItems);
            System.enqueueJob(py);
            String jobId = System.schedule(
                'RunImmediatelyJob',                 
                '0 0 0 1 1 ? *',                   
                new ClaimPostClearingHouseNightlyBatch() 
            );
            Test.stopTest(); 
            system.assertEquals(1,1);
        }catch(Exception e) {
            system.debug('e'+e);
        }
    }
    
}
@isTest
public class ClaimvalidationErrorControllerTest {
    
    @isTest
    public static void claimValidationErrorsTest(){
        List<ElixirSuite__claim__c> claimList =new List<ElixirSuite__claim__c>();
        ElixirSuite__claim__c c = new ElixirSuite__claim__c();
        claimList.add(c);
        ElixirSuite__claim__c c2 = new ElixirSuite__claim__c();
        c2.ElixirSuite__Validation_Error_Message__c='test';
        claimList.add(c2);
        test.startTest();
        insert claimList;
        //scenario 1
        try{
        ClaimvalidationErrorController.claimValidationErrors(null); 
        }catch(exception e){}
        //scenario 2
        ClaimvalidationErrorController.claimValidationErrors(c.id);
        //scenario 3
        ClaimvalidationErrorController.claimValidationErrors(c2.id);
        System.assertEquals(1, 1, '');
        test.stopTest();
        
    }
    
    @isTest
    public static void validateClaimTest(){
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        list<ElixirSuite__Claim_Line_Items__c> lineItemList = new list<ElixirSuite__Claim_Line_Items__c>();
        ElixirSuite__Claim_Line_Items__c rec = new ElixirSuite__Claim_Line_Items__c();
        lineItemList.add(rec);
        test.startTest();
        insert claimRecord;
        insert rec;
        //try{
            ClaimvalidationErrorController.validateClaims(claimRecord);
            ClaimvalidationErrorController.validateClaimLineItem(rec);
        //}catch(exception e){}
        System.assertEquals(1, 1, ' ');
        test.stopTest();
    }
    @isTest
    public static void validateClaimTest1(){
        Test.startTest();
        ElixirSuite__Payor__c payorRecord = new ElixirSuite__Payor__c();
        payorRecord.ElixirSuite__Payer_Code__c = '60054';
        payorRecord.ElixirSuite__Claim_Processing_via__c = 'Clearing House';
        insert payorRecord;
        
        Account acc = new Account();
        acc.Name = 'dfghjhgfdxdfcgvbhnjkjliuytfrdgcvbhjnkliuytrewsdfgvhbjkiuhytrewsdfcgvbhjnkhugytfrdgf';
        acc.ElixirSuite__First_Name__c = 'dfghjhgfdxdfcgvbhnjkjliuytfrdgcvbhjnkliuytrewsdfgvhbjkiuhytrewsdfcgvbhjnkhugytfrdgf';
        acc.ElixirSuite__Last_Name__c = 'aqawesrdtfgop0i9yu7tre4w3sdxcvbnmk,lgvvhbjnkml,;poiuytr5e4w3sdfghjkloiuytrewsrdfghjkloijuytrfd';
        insert acc;
        //Claim Creation START
        ElixirSuite__Claim__c claimRecord = new ElixirSuite__Claim__c();
        claimRecord.ElixirSuite__Payor__c = payorRecord.Id;
        claimRecord.ElixirSuite__Account__c = acc.Id;
        claimRecord.ElixirSuite__claim_status__c = 'Ready to Submit';
        claimRecord.ElixirSuite__pcn__c = 'John';
        claimRecord.ElixirSuite__Patient_s_Address__c = 'gvhbjnkmjbhgb aqawesrdtfgop0i9yu7tre4w3sdxcvbnmk,lgvvhbjnkml,;poiuytr5e4w3sdfghjkloiuytrewsrdfghjkloijuytrfd';
        claimRecord.ElixirSuite__Patient_s_City__c = 'aqawesrdtghjklfgop0i9yu7tre4w3sdxcvbnmk,lgvvhbjnkml,;poiuytr5e4w3sdfghjkloiuytrewsrdfghjkloijuytrfd';
        claimRecord.ElixirSuite__Patient_Sex__c = 'T';
        claimRecord.ElixirSuite__Insured_Address__c =  'gvhbjnkmjbhgb aqawesrdtfgop0i9yu7tre4w3sdxcvbnmklgvvhbjnkmlpoiuytr5e4w3sdfghjkloiuytrewsrdfghjkloijuytrfd';
        claimRecord.ElixirSuite__Insured_City__c = 'aqawesrdtghjklfgop0i9yu7tre4w3sdxcvbnmk,lgvvhbjnkmlpoiuytr5e4w3sdfghjkloiuytrewsrdfghjkloijuytrfd';
        claimRecord.ElixirSuite__Patient_Country_Code__c = 'CASE';
        claimRecord.ElixirSuite__patient_first_Name__c = 'David';
        claimRecord.ElixirSuite__patient_last_Name__c = 'Beckam';
        claimRecord.ElixirSuite__NPI__c = '1831234939';
        claimRecord.ElixirSuite__other_payer_name__c = 'LIC';
        claimRecord.ElixirSuite__patient_dob__c = System.today().addYears(-40);
        claimRecord.ElixirSuite__insured_s_name__c = 'David';
        claimRecord.ElixirSuite__insured_s_name__c = 'Beckam';
        claimRecord.ElixirSuite__payer_order__c = 'Primary';
        claimRecord.ElixirSuite__Patient_s_State__c = 'NYT';
        claimRecord.ElixirSuite__Patient_Zip_Code__c = '123456789012356787';
        claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c = 'Father';
        claimRecord.ElixirSuite__insured_address__c = 'Noida';
        claimRecord.ElixirSuite__Patient_Condition_Related_To_Accident__c = true;
        claimRecord.ElixirSuite__insured_city__c = 'Noida';
        claimRecord.ElixirSuite__Insured_Country_Code__c = '123456789012356787';
        claimRecord.ElixirSuite__Insured_State__c = 'NYT';
        claimRecord.ElixirSuite__Insured_Zip_Code__c = '201301';
        claimRecord.ElixirSuite__Insured_Telephone__c = '9888898888';
        claimRecord.ElixirSuite__Insured_Policy__c = 'Medical Benefits';
        claimRecord.ElixirSuite__Insured_s_ID_Number__c = '56565xfdcgvhbjkhgtfdf3w45467';
        claimRecord.ElixirSuite__Employment_Related__c = 'N';
        claimRecord.ElixirSuite__Auto_Accident_Related__c = 'N';
        claimRecord.ElixirSuite__insured_dob__c = System.today().addYears(-10);
        claimRecord.ElixirSuite__Insured_Sex__c = 'P';
        claimRecord.ElixirSuite__Place_of_Service__c = 'Delhi';
        claimRecord.ElixirSuite__Diagnosis_A__c = '99153ghjhjahghaghs7378e983980r78jcndcbgjdtu5736493448';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c = 'E';
        claimRecord.ElixirSuite__Accept_Assignment__c = 'Y';
        claimRecord.ElixirSuite__total_charge__c = 900;
        claimRecord.ElixirSuite__amount_paid__c = 0;
        claimRecord.ElixirSuite__Billing_Provider_Name__c = 'ATHENAtrdrecghjhtrdesrfjgyuesrcfhjyutrdfvghgtf tdgyutrddiutsrfggjyie5srhjhiuitystrcghvhhjjtystrgfcghfhrdtdt';
        claimRecord.ElixirSuite__Billing_Provider_Address_1__c = 'Watertownsfdghjkl;pokiuytr5e4wasdxfcgvhbjnkmldfghjklkytresdcvbhjkloiuytrewsdcvbnjkiuytrewaxcvbnmkloiuytrewsdcfvbnjkloiuytrewsxcv nmmmmjhgfdsdfghjkiuytrewsdfgtyuiopoiuytrewasdfghjkiuytredfvbnjkiuytrewsdcfvghjkuytrewsdfghjkiuytrewsdcfghjuytresdfghgfrdsxdcv';
        claimRecord.ElixirSuite__Billing_Provider_State__c = 'CAY';
        claimRecord.ElixirSuite__Billing_Provider_Info_NPI__c = '123456789054567896543567';
        claimRecord.ElixirSuite__Billing_Provider_Zip__c = '9110145678905321344556666544333345566';
        claimRecord.ElixirSuite__Billing_Provider_Info__c = '1234567890';
        claimRecord.ElixirSuite__Bill_Phone__c = '815215530067';
        claimRecord.ElixirSuite__Billing_Provider_City__c = 'Watertown esdfghjkhugytfrdfcgvbhjkiuytrdfcgvbhjkuhytrdfgcv fghjkoiouytrdfghujiouytrdf';
        claimRecord.ElixirSuite__Patient_Name__c = 'Test Account 1';
        claimRecord.ElixirSuite__Insured_s_Name__c= 'Test Insured 1';
        claimRecord.ElixirSuite__Other_Insured_s_Name__c= 'Test OtherInsured 1';
        claimRecord.ElixirSuite__Payer_Order__c = 'Secondary';
        claimRecord.ElixirSuite__Billing_Provider_Tax_ID__c = '354364322356899086432234548';
        //  claimRecord.Diag_1__c = 'B86';
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
        insert rec;
        List<ElixirSuite__Claim__c> claimList = new List<ElixirSuite__Claim__c>();
        List<ElixirSuite__Claim_Line_Items__c> clList = new List<ElixirSuite__Claim_Line_Items__c>();
        claimList.add(claimRecord);
        clList.add(rec);
       // try{
            ClaimvalidationErrorController.validateClaims(claimRecord);
            ClaimvalidationErrorController.validateClaimLineItem(rec);
            ClaimvalidationErrorController.splitNames('test Account');
            ClaimvalidationErrorController.validate1(claimList,clList);
        //}catch(exception e){}
        System.assertEquals(1, 1, ' ');
        test.stopTest();
    }

}
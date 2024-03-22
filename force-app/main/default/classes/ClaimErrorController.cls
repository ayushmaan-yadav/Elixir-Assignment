public with sharing class ClaimErrorController {
    
    final static Map<string, string> claimsMap = new Map<string, string>{
        'pcn'=>'ElixirSuite__Pcn__c',
        'payerid'=>'ElixirSuite__Payer_ID__c',
        'ins_number'=>'ElixirSuite__Insured_s_ID_Number__c',
        'pat_dob'=>'ElixirSuite__Patient_DOB__c',
        'pat_sex'=>'ElixirSuite__Patient_Sex__c',
        'payer_order'=>'ElixirSuite__Payer_Order__c',
        'pat_name_f' => 'ElixirSuite__Patient_Name__c',
        'pat_name_l' => 'ElixirSuite__Patient_Name__c',
        'pat_addr_1'=>'ElixirSuite__Patient_s_Address__c',
        'pat_addr_2'=>'ElixirSuite__Patient_Address_2__c',
        'ins_addr_2'=>'ElixirSuite__Insured_Address_2__c',
        'pat_city'=>'ElixirSuite__Patient_s_City__c',
        'pat_country'=>'ElixirSuite__Patient_Country_Code__c',
        'pat_state'=>'ElixirSuite__Patient_s_State__c',
        'pat_zip'=>'ElixirSuite__Patient_Zip_Code__c',
        'pat_rel'=>'ElixirSuite__Patient_Relationship_to_Insured__c',
        'ins_addr_1'=>'ElixirSuite__Insured_Address__c',
        'ins_city'=>'ElixirSuite__Insured_City__c',
        'ins_country'=>'ElixirSuite__Insured_Country_Code__c',
        'ins_state'=>'ElixirSuite__Insured_State__c',
        'ins_zip'=>'ElixirSuite__Insured_Zip_Code__c',
        'employment_related'=>'ElixirSuite__Employment_Related__c',
        'auto_accident'=>'ElixirSuite__Auto_Accident_Related__c',
        'ins_dob'=>'ElixirSuite__Insured_Dob__c',
        'ins_sex'=>'ElixirSuite__Insured_Sex__c',
        'place_of_service'=>'ElixirSuite__Place_of_Service_Code_s__c',
        'accept_assign'=>'ElixirSuite__Accept_Assignment__c',
        'total_charge'=>'ElixirSuite__Total_Charge__c',
        'amount_paid'=>'ElixirSuite__Amount_Paid__c',
        'ins_group'=>'ElixirSuite__Insured_Policy__c',
        'ins_phone'=>'ElixirSuite__Insured_Telephone__c',
        'ins_plan'=>'ElixirSuite__Insurance_Plan_Name__c',
        'prior_auth'=>'ElixirSuite__Prior_Authorization_Number__c',
        'ref_name_f'=>'ElixirSuite__First_Name_NAME_OF_REFERRING_PROVIDER__c',
        'ref_name_l'=>'ElixirSuite__Last_Name_NAME_OF_REFERRING_PROVIDER__c',
        'ref_name_m'=>'ElixirSuite__MiddleName_NAME_OF_REFERRING_PROVIDER__c',
        'ref_npi'=>'ElixirSuite__NPI__c',
        'other_ins_group'=>'ElixirSuite__Other_Insured_s_Policy_Group_Number__c',
        'other_ins_plan'=>'ElixirSuite__Other_Insurance_Plan_Name__c',
        'icn_dcn_1'=>'ElixirSuite__Sender_Icn__c',
        'ins_name_f'=>'ElixirSuite__Insured_s_Name__c',
        'ins_name_l'=> 'ElixirSuite__Insured_s_Name__c',
        'bill_name'=>'ElixirSuite__Billing_Provider_Name__c',
        'bill_addr_1'=>'ElixirSuite__Billing_Provider_Address_1__c',
        'bill_addr_2'=>'ElixirSuite__Billing_Provider_Address_2__c',
        'bill_state'=>'ElixirSuite__Billing_Provider_State__c',
        'bill_zip'=>'ElixirSuite__Billing_Provider_Zip__c',
        'bill_phone'=>'ElixirSuite__Bill_Phone__c',
        'bill_city'=>'ElixirSuite__Billing_Provider_City__c',
        'bill_taxonomy'=>'ElixirSuite__Billing_Provider_Taxonomy__c',
        'bill_taxid'=>'ElixirSuite__Federal_Tax_Id_Number__c',
        'bill_taxid_type'=>'ElixirSuite__Billing_Provider_Tax_ID_Type__c',
        'bill_npi'=>'ElixirSuite__Billing_Provider_Info_NPI__c',
        'bill_id'=>'ElixirSuite__Billing_Provider_Other_ID__c',
        'facility_name' => 'ElixirSuite__Service_Facility_Location_Information__c',
        'facility_npi' => 'ElixirSuite__Service_Facility_Location_NPI__c',
        'facility_id' =>'ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c',
        'facility_addr_1' =>'ElixirSuite__Service_Facility_Loc_Address__c',
        'facility_addr_2' =>'ElixirSuite__Service_Facility_Address_2__c',
        'facility_city' => 'ElixirSuite__Service_Facility_Loc_City__c',
        'facility_state' => 'ElixirSuite__Service_Facility_Loc_State__c',
        'facility_zip' => 'ElixirSuite__Service_Facility_Loc_Zip__c',
        'prov_name_f' => 'ElixirSuite__Rendering_Provider_First_Name__c',
        'prov_name_l' => 'ElixirSuite__Rendering_Provider_Last_Name__c',
        'prov_npi' =>'ElixirSuite__Rendering_Provider_NPI__c',
        'prov_taxonomy' =>'ElixirSuite__Rendering_Provider_Taxonomy__c',
        'prov_id' => 'ElixirSuite__Rendering_Provider_Tax_Id__c',
        'other_ins_plan' => 'ElixirSuite__Other_Insurance_Plan_Name__c',
        'other_ins_group' => 'ElixirSuite__Other_Insured_s_Policy_Group_Number__c',
        'hosp_from_date' => 'ElixirSuite__Hospitalization_From_Date__c',
        'hosp_thru_date' => 'ElixirSuite__Hospitalization_To_Date__c',
         'accident_date' => 'ElixirSuite__Date_Of_Current_Illness__c',
         'auto_accident_state' => 'ElixirSuite__Auto_Accident_Related__c',
         'other_claimfilingcode' => 'ElixirSuite__Insurance_Type__c',
         'other_ins_medicare_code'=>'ElixirSuite__Medicare_Type_Code__c'
        };
    final static Map<String, String> lineItemsMap = new Map<String, String>();

    @AuraEnabled
    public static claimWrapper DataInit(String claimId){
        for(Integer i=1;i<12;i++){
            claimsMap.put('diag_'+i, 'ElixirSuite__Diag_'+i+'__c');            
        }    
        Map<Integer,String> diagnosis = new Map<Integer,String>{
            1=>'A',
            2=>'B',
            3=>'C',
            4=>'D',
            5=>'E',
            6=>'F',
            7=>'G',
            8=>'H',
            9=>'I',
            10=>'J',
            11=>'K',
            12=>'L'
        };
        for(Integer i=1;i<12;i++){
            claimsMap.put('diag_'+i, 'ElixirSuite__Diagnosis_'+diagnosis.get(i)+'__c');            
        }       
        ElixirSuite__Claim__c ClaimData = new ElixirSuite__Claim__c();
        claimData = [SELECT Id,ElixirSuite__Patient_Relationship_to_Insured__c,ElixirSuite__Message__c,ElixirSuite__patient_last_Name__c,ElixirSuite__Claim_Status__c,
                            ElixirSuite__Payerid__c,ElixirSuite__Billing_Provider_Tax_ID_Type__c,ElixirSuite__Accept_Assignment__c  
                            FROM ElixirSuite__Claim__c WHERE Id= :claimId WITH SECURITY_ENFORCED];
        List<ElixirSuite__Claim_Line_Items__c> ClaimLiData = new List<ElixirSuite__Claim_Line_Items__c>();
        claimLiData = [SELECT Id, ElixirSuite__Amount_Paid_by_Insurance__c,ElixirSuite__Claim__c,ElixirSuite__Contracted_Amount__c,ElixirSuite__CPT_HCPCS_Code__c,CreatedById,ElixirSuite__Integration_Order__c,
                        CreatedDate,ElixirSuite__Days_Units__c,ElixirSuite__Diag_Ref__c,ElixirSuite__EMG__c,ElixirSuite__EPSTD__c,ElixirSuite__ERA_Received__c,ElixirSuite__From_Date__c,ElixirSuite__ID_Qual__c,IsDeleted,
                        LastModifiedById,LastModifiedDate,ElixirSuite__Modifier_1__c,ElixirSuite__Modifier_2__c,
                        ElixirSuite__Modifier_3__c,ElixirSuite__Modifier_4__c,Name,OwnerId,ElixirSuite__Patient_Responsibility__c,ElixirSuite__Place_of_Service_Code__c,ElixirSuite__Place_of_Service__c,
                        ElixirSuite__Procedure_Charge__c,ElixirSuite__Procedure__c,ElixirSuite__Proc_code__c,ElixirSuite__Total_Adjustment__c,ElixirSuite__Total_Allowed_Amount__c,ElixirSuite__To_Date__c
                        FROM ElixirSuite__Claim_Line_Items__c WHERE ElixirSuite__Claim__c= :claimId WITH SECURITY_ENFORCED
                        ORDER BY ElixirSuite__Integration_Order__c];

        //Line Item - START
        for(Integer lineOrder=1; lineOrder<=claimLiData.size(); lineOrder++){
            lineItemsMap.put('proc_code_'+lineOrder,'ElixirSuite__CPT_HCPCS_Code__c');
            lineItemsMap.put('units_'+lineOrder,'ElixirSuite__Days_Units__c');
            lineItemsMap.put('from_date_'+lineOrder,'ElixirSuite__From_Date_Of_Service__c');
            lineItemsMap.put('thru_date_'+lineOrder,'ElixirSuite__To_Date_Of_Service__c');
            lineItemsMap.put('charge_'+lineOrder,'ElixirSuite__Procedure_Charge__c');
            lineItemsMap.put('diag_ref_'+lineOrder,'ElixirSuite__Diagnosis_Pointer__c');
            lineItemsMap.put('place_of_service_'+lineOrder,'ElixirSuite__Place_of_Service_Code_s__c');
            lineItemsMap.put('mod1'+lineOrder,'ElixirSuite__Modifier_1__c');
            lineItemsMap.put('mod2'+lineOrder,'ElixirSuite__Modifier_2__c');
            lineItemsMap.put('mod3'+lineOrder,'ElixirSuite__Modifier_3__c');
            lineItemsMap.put('mod4'+lineOrder,'ElixirSuite__Modifier_4__c');
            lineItemsMap.put('chg_prov_npi_'+lineOrder,'ElixirSuite__Rendering_Provider_NPI__c');
            lineItemsMap.put('chg_prov_taxonomy_'+lineOrder,'ElixirSuite__Rendering_Provider_Taxonomy__c');
            lineItemsMap.put('chg_prov_id_'+lineOrder,'ElixirSuite__Rendering_Provider_Non_NPI__c');
            lineItemsMap.put('chg_prov_name_f_'+lineOrder,'ElixirSuite__Rendering_Provider_First_Name__c');
            lineItemsMap.put('chg_prov_name_l_'+lineOrder,'ElixirSuite__Rendering_Provider_Last_Name__c');
                    }
        //Line Item - END
        Map<Integer, ElixirSuite__Claim_Line_Items__c> orderWiseLineItems = new  Map<Integer, ElixirSuite__Claim_Line_Items__c>();
        if(claimLiData!=null && claimLiData.size()>0){
            for(ElixirSuite__Claim_Line_Items__c lineItems :claimLiData){
                orderWiseLineItems.put((Integer)lineItems.ElixirSuite__Integration_Order__c, lineItems);
            }
        }
        if(String.isNotBlank(ClaimData.ElixirSuite__Message__c)){
            String newString = '{ "Key" :'+ ClaimData.ElixirSuite__Message__c + '}';
            Map<String, Object> mainJsonForMessage =(Map<String, Object>) JSON.deserializeUntyped(newString);
            system.debug('mainJsonForInsurance'+mainJsonForMessage);                      
            List<Object> receivedMessages = (List<Object>) mainJsonForMessage.get('Key');
            Map<String,List<ClaimErrors>> allErrors = new Map<String,List<ClaimErrors>>();
            Set<String> oneTimeShownFields = new Set<String>();
            for(Object messages :receivedMessages){
                Map<String, Object> message = (Map<String,Object>) messages;
                String status = (String) message.get('status');
                if(status == 'R'){
                    String msg = (String) message.get('message');
                    String fields = (String) message.get('fields');
                    for(String fieldName :fields.split(',')){
                        if(oneTimeShownFields.contains(fieldName)){
                            continue;
                        }
                        oneTimeShownFields.add(fieldName);
                        if(claimsMap.containsKey(fieldName)){
                            String errorField = claimsMap.get(fieldName);
                            ClaimErrors error = new ClaimErrors(errorField, msg);
                            if(allErrors.containsKey('CLAIM')){
                                allErrors.get('CLAIM').add(error);
                            }else{
                                allErrors.put('CLAIM', new List<ClaimErrors>{error});  
                            }
                        }else if(lineItemsMap.containsKey(fieldName)){
                            String orderNumber = fieldName.right(1);
                            String errorField = lineItemsMap.get(fieldName);
                            system.debug(errorField);
                            ClaimErrors error = new ClaimErrors(errorField, msg);
                            if(allErrors.containsKey(orderNumber)){
                                allErrors.get(orderNumber).add(error);
                            }else{
                                allErrors.put(orderNumber, new List<ClaimErrors>{error});
                            }
                        }
                    }
                }
            }
            ClaimWrapper claim = new ClaimWrapper();
            if(allErrors.size()>0){
                claim.claim = claimData;
                claim.allErrors = allErrors;
                claim.lineItems = orderWiseLineItems;
            }
            return claim;
        }
        return null;
    }
    public class ClaimWrapper{
        @AuraEnabled public ElixirSuite__Claim__c claim;
        @AuraEnabled public Map<String,List<ClaimErrors>> allErrors;
        @AuraEnabled public Map<Integer,ElixirSuite__Claim_Line_Items__c> lineItems;
    }
    public class ClaimErrors{
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String errorField;
        public ClaimErrors(String errorField, String errorMessage){
            this.errorField = errorField;
            this.errorMessage = errorMessage;
        }
    }
    

}
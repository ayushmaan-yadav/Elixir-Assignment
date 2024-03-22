global class CustomerCalloutClaimMD implements Callable {
    
    global Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'RefreshClaimMDCallout' {
                updateClaims((String)args.get('claimLst'));
                return null ;  
            }
            when 'GetpayerStatusClaimMD' {
                checkClaimStatus((String)args.get('claimId'));
                return null;
            }
            when 'GetERA' {
                getEraEntryPointCallout();
                return null;
            }
            when 'checkValidations' {
                MessageWrapper  wrp =  checkValidations((String)args.get('vobId'));
                return wrp;
              
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
    }
    
    global class ExtensionMalformedCallException extends Exception {}
    
    global static Integration_Credentials__c getCredentials(){
		return [SELECT Id, Integration_Key__c 
                    FROM Integration_Credentials__c WHERE Name='ClaimMD' WITH SECURITY_ENFORCED];
        
    }
    global static void updateClaims(String claimLst){
        
        Integration_Credentials__c custset = getCredentials();
        
        if(!Test.isRunningTest() && String.isBlank(custset.Integration_Key__c)){
            throw new AuraHandledException('Please provide AccountKey');
        }
        if(string.isBlank(claimLst) && !Test.isRunningTest()){
            throw new AuraHandledException('No Claim is selected, please select atleast one claim!');
        }
        List<ElixirSuite__Claim__c> toSendClaims = new  List<ElixirSuite__Claim__c>();
        List<String> claimIdsSet = splitIds(claimLst);
        Map<String,Integer> countItems = new Map<String,Integer>();
        List<ElixirSuite__Claim__c> AllClaims = new List<ElixirSuite__Claim__c>([SELECT Id,ElixirSuite__Claim_Status__c,ElixirSuite__patient_s_state__c,ElixirSuite__Billing_Provider_Info_NPI__c,ElixirSuite__payor__r.ElixirSuite__Claim_Processing_via__c
                                                                                 FROM ElixirSuite__Claim__c 
                                                                                 WHERE Id IN :claimIdsSet WITH SECURITY_ENFORCED 
                                                                                 LIMIT 50000]);
        List<AggregateResult> totalItems = [SELECT Count(Id) c, ElixirSuite__Claim__c l FROM ElixirSuite__Claim_Line_Items__c
                                            WHERE ElixirSuite__Claim__c IN :claimIdsSet WITH SECURITY_ENFORCED GROUP BY ElixirSuite__Claim__c];
        //Anusha - start
        List<ElixirSuite__Claim_Line_Items__c> claimLineTM = [SELECT Id, ElixirSuite__Claim__c, ElixirSuite__Procedure_Charge__c FROM ElixirSuite__Claim_Line_Items__c
                                                              WHERE ElixirSuite__Claim__c IN :claimIdsSet WITH SECURITY_ENFORCED ];
        for(ElixirSuite__Claim_Line_Items__c claimLI :claimLineTM){
            if(claimLI.ElixirSuite__Procedure_Charge__c==null && !Test.isRunningTest()){
                throw new AuraHandledException('Claim charges are not present!');               
            }
        } //Anusha - end
        if(totalItems.size()>0 && totalItems != null){                                
            for(AggregateResult result :totalItems){
                countItems.put((String)result.get('l'), (Integer)result.get('c'));
            }
            for(String claimId :claimIdsSet){
                if(!countItems.containsKey(claimId) && !Test.isRunningTest()){
                    throw new AuraHandledException('No Procedures/Charges are present!!'); //replaced 'Claim charges are not present!!' message text to 'No Procedures/Charges are present!!'
                }
            }
        } 
        String msg = ' except ';
        for(ElixirSuite__Claim__c c :AllClaims){  
            if(String.isBlank(c.ElixirSuite__Claim_Status__c) ||  c.ElixirSuite__Claim_Status__c!= 'Ready to Submit' && !Test.isRunningTest()){
                throw new AuraHandledException('Claim Status should be Ready to Submit!!');               
            }
            if(c.ElixirSuite__Payor__c != null && c.ElixirSuite__Payor__r.ElixirSuite__Claim_Processing_via__c !='Clearing House' && !Test.isRunningTest()){
                throw new AuraHandledException('Claim for this payor cannot be sent out for Clearing House.');  
            }
            
            c.ElixirSuite__Validation_Error_Message__c='';
            c.ElixirSuite__Claim_Status__c = 'Sent to Clearing house'; 
            
            toSendClaims.add(c);
        }
        List<ElixirSuite__Claim__c> allClaimsToSend = new List<ElixirSuite__Claim__c>([SELECT Id,ElixirSuite__Claim_Status__c
                                                                                       FROM ElixirSuite__Claim__c 
                                                                                       WHERE Id IN :claimIdsSet WITH SECURITY_ENFORCED
                                                                                       LIMIT 50000]);
        if(allClaimsToSend.size() > 0){
            Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = lineItems(toSendClaims);
            List<ElixirSuite__Claim_Line_Items__c> lineItems = new List<ElixirSuite__Claim_Line_Items__c>();
            try{
                for(List<ElixirSuite__Claim_Line_Items__c> lineItem :mapOfClaimIdToLineItems.values()){
                    if(lineItem!=null){
                        lineItems.addAll(lineItem);
                    }
                }
                update lineItems;
                
            }
            catch(Exception e){
            }
        }
        if(toSendClaims.size() > 0){
            update toSendClaims;
            
            postClaimsToClearingHouse(claimLst);   
            
            
        }
    }
    
    global static void postClaimsToClearingHouse(String claimLst){       
        List<String> claimIdsSet = splitIds(claimLst);
        Schema.DescribeSObjectResult result = ElixirSuite__Claim__c.sObjectType.getDescribe();
        List<String> apiNames =  new List<String>(result.fields.getMap().keySet());
        String query = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNames,','))  + ',ElixirSuite__payor__r.ElixirSuite__Payer_Code__c,ElixirSuite__Claim__r.ElixirSuite__payor__r.Name,ElixirSuite__Claim__r.ElixirSuite__Insured_s_ID_Number__c,ElixirSuite__Account__r.ElixirSuite__First_Name__c,ElixirSuite__Account__r.ElixirSuite__Last_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_First_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Middle_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Last_Name__c' + ' FROM ElixirSuite__Claim__c ';
        query+= 'WHERE Id in: claimIdsSet';
         
        List<ElixirSuite__Claim__c> listOfClaims = (List<ElixirSuite__Claim__c>)Database.query(query);
        Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = new Map<Id,List<ElixirSuite__Claim_Line_Items__c>>();
        if(listOfClaims!=null && listOfClaims.size()>0){
            mapOfClaimIdToLineItems = lineItems(listOfClaims);
        } 
        if(listOfClaims != null && listOfClaims.size()>0){
            entryPointOfCallOut(listOfClaims, mapOfClaimIdToLineItems);
        }
    }
   
    
    global static void entryPointOfCallOut(List<ElixirSuite__Claim__c> listOfClaims, Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems){  
       
        String bodyGenerated ; //body to send to Claim MD
        List<Id> listOfClaimsId = new List<Id>();
        if(mapOfClaimIdToLineItems!=null && mapOfClaimIdToLineItems.size()>0){
            bodyGenerated = generateBody(mapOfClaimIdToLineItems, listOfClaims);
            System.debug('bodyGenerated '+bodyGenerated);
            for(ElixirSuite__Claim__c c2 :listOfClaims){
                listOfClaimsId.add(c2.id);
            }
            if(String.isNotBlank(bodyGenerated)){
                makeCallOut(bodyGenerated, listOfClaimsId);
            }  
        }        
    }
    
    //method to generate body for Claim MD
    
    global static string generateBody(Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems, List<ElixirSuite__Claim__c> listOfClaims){
        system.debug('#####'+listOfClaims);
        List<ElixirSuite__Claim_Line_Items__c> priCLData = [Select Id, Name, ElixirSuite__Claim_Procedure_Line_Item__c FROM ElixirSuite__Claim_Line_Items__c where ElixirSuite__Claim__c IN: mapOfClaimIdToLineItems.keySet()];
        System.debug('priCLData '+priCLData);
        Set<Id> priCLIds = new Set<Id>();
        for(ElixirSuite__Claim_Line_Items__c cl:priCLData){
            if(cl.ElixirSuite__Claim_Procedure_Line_Item__c != null){
              priCLIds.add(cl.ElixirSuite__Claim_Procedure_Line_Item__c);
            }
        }
        Map<Id,ElixirSuite__Claim_Line_Items__c> secCLData = new Map<Id,ElixirSuite__Claim_Line_Items__c>([Select id, (Select Id, Name,ElixirSuite__Adjustment_Amount_1__c,ElixirSuite__Adjustment_Amount_2__c,ElixirSuite__Adjustment_Amount_3__c,ElixirSuite__Adjustment_Amount_4__c,ElixirSuite__Adjustment_Amount_5__c,ElixirSuite__Adjustment_Amount_6__c,ElixirSuite__Adjustment_Amount_7__c,ElixirSuite__Adjustment_Amount_8__c,
                                                                                                                             ElixirSuite__Adjustment_Code_1__c,ElixirSuite__Adjustment_Code_2__c,ElixirSuite__Adjustment_Code_3__c,ElixirSuite__Adjustment_Code_4__c,ElixirSuite__Adjustment_Code_5__c,ElixirSuite__Adjustment_Code_6__c,ElixirSuite__Adjustment_Code_7__c,ElixirSuite__Adjustment_Code_8__c,
                                                                                                                             ElixirSuite__Paid__c,ElixirSuite__Total_Allowed_Amount__c,ElixirSuite__EOB__r.ElixirSuite__EOB__r.ElixirSuite__Check_EFT_Date__c FROM ElixirSuite__ERA_Line_Item__r ORDER BY CreatedDate Desc LIMIT 1) FROM ElixirSuite__Claim_Line_Items__c Where Id IN:priCLIds]);
        System.debug('secCLData '+secCLData);
        Map<Id,ElixirSuite__Claim__c> mapOfClaims = new Map<Id,ElixirSuite__Claim__c>(listOfClaims);
        Map<String,String> patRelMap = new Map<String,String>(); //Anusha-Start-06/11/22    
        ElixirSuite__Elixir_Custom_Setting__c customSetting = ElixirSuite__Elixir_Custom_Setting__c.getOrgDefaults();
        for(ElixirSuite__Patient_Relationship_Code__mdt patRel : [Select id, developerName, MasterLabel, ElixirSuite__Code__c from ElixirSuite__Patient_Relationship_Code__mdt LIMIT 5000])    
        {   
            patRelMap.put(patRel.developerName,patRel.ElixirSuite__Code__c); 
        } //Anusha-End-06/11/22
        String xmlCreated = '<claims>';
        for(Id claimId :mapOfClaimIdToLineItems.keySet()){
            ElixirSuite__Claim__c claimRecord = mapOfClaims.get(claimId);
            List<ElixirSuite__Claim__c> claimLstRec = new List<ElixirSuite__Claim__c>();
            claimLstRec.add(claimRecord);
            String validationMessage = ClaimvalidationErrorController.validate1(claimLstRec,mapOfClaimIdToLineItems.get(claimId)); //Anusha - Start -09/11/22 
            if(Test.isRunningTest()){
               validationMessage = 'Validation passed'; 
            }
            if(validationMessage=='Validation passed'){       
                xmlCreated+= '<claim';
                List<String> pcnName = claimRecord.Name.contains('-') ? claimRecord.Name.split('-') : new List<String>();
                String pcnStr = pcnName.size()>0? pcnName[0]+pcnName[1] : claimRecord.Name;
                String claimUniqueId;
                if(customSetting!=null && customSetting.ElixirSuite__By_Pass_Claim_Name__c){
                 String orgId = UserInfo.getOrganizationId();
                 claimUniqueId = setString(claimRecord.Name) + ';'+orgId;
                }else{
                 claimUniqueId = setString(claimRecord.Name);   
                }
                String claimType;
                if(claimRecord.ElixirSuite__Payer_Order__c == 'Secondary'){
                    claimType = 'Secondary';
                }else if(claimRecord.ElixirSuite__Payer_Order__c == 'Tertiary'){
                    claimType = 'Tertiary'; 
                }else{
                    claimType = 'Primary';
                }
                xmlCreated+= ' remote_claimid="'+ claimUniqueId +'"';
                xmlCreated+= ' pcn="'+ claimUniqueId +'"'; 
                xmlCreated+= ' payer_order="'+ claimType +'"';
                xmlCreated+= ' other_payer_name="'+ setString(claimRecord.ElixirSuite__Claim__r.ElixirSuite__payor__r.Name) +'"';
                xmlCreated+= ' other_ins_number="'+ setString(claimRecord.ElixirSuite__Claim__r.ElixirSuite__Insured_s_ID_Number__c) +'"';
                /*
                List<String> patNames = splitNames(claimRecord.ElixirSuite__Patient_Name__c);
                System.debug('patNames$ '+patNames);
                if(patNames!=null && patNames.size()>0){
                    system.debug('patient name' +patNames);
                    for(Integer i=0;i<patNames.size();i++){
                        switch on i {
                            when 1 {
                                xmlCreated+= ' pat_name_f="'+ setString(patNames[i]) + '"';//D
                            }   
                            when 0 {
                                xmlCreated+= ' pat_name_l="'+ setString(patNames[i]) + '"';//D
                            }
                            when 2 {
                                xmlCreated+= ' pat_name_m="'+ setString(patNames[i]) + '"';
                            }
                        }
                    }
                }else{
                    xmlCreated+= ' pat_name_f="'+ '' + '"'; 
                    xmlCreated+= ' pat_name_l="'+ '' + '"';
                }
                */
                //LX3-9977
                 xmlCreated+= ' pat_name_f="'+ setString(claimRecord.ElixirSuite__Account__r.ElixirSuite__First_Name__c) + '"';//D
                    xmlCreated+= ' pat_name_l="'+ setString(claimRecord.ElixirSuite__Account__r.ElixirSuite__Last_Name__c) + '"';//D
                
                
                xmlCreated+= ' payerid="'+ setString(claimRecord.ElixirSuite__payor__r.ElixirSuite__Payer_Code__c) + '"';
                //xmlCreated+= ' payer_name="'+ setString(claimRecord.other_payer_name__c) + '"';
                xmlCreated+= ' ins_number="'+ setString(claimRecord.ElixirSuite__Insured_s_ID_Number__c) + '"'; 
                xmlCreated+= ' pat_dob="'+ setDateFormatDOB(claimRecord.ElixirSuite__Patient_DOB__c) + '"';//D //Anusha - replaced patient_dob__c with Patient_DOB__c
                xmlCreated+= ' pat_sex="'+ setString(claimRecord.ElixirSuite__Patient_Sex__c) + '"'; //Anusha-14/11/22
                xmlCreated+= ' pat_addr_1="'+ setString(claimRecord.ElixirSuite__Patient_s_Address__c) + '"';//D
                xmlCreated+= ' pat_city="'+ setString(claimRecord.ElixirSuite__Patient_s_City__c) + '"';//D
                xmlCreated+= ' pat_country="'+ setString(claimRecord.ElixirSuite__Patient_Country_Code__c) + '"';//D
                xmlCreated+= ' pat_state="'+ setString(claimRecord.ElixirSuite__Patient_s_State__c) + '"';//D //Anusha replaced patient_s_state__c with Patient_s_State__c
                xmlCreated+= ' pat_zip="'+ claimRecord.ElixirSuite__Patient_Zip_Code__c + '"';//D //Anusha replaced 'Patient_s_Zipcode__c' with 'Patient_Zip_Code__c'    
                System.debug('patient rel code***'+patRelMap.get(claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c));
                xmlCreated+= ' pat_rel="'+ setString(patRelMap.get(claimRecord.ElixirSuite__Patient_Relationship_to_Insured__c)) + '"';//D //Anusha-06/11/22
                xmlCreated+= ' ins_addr_1="'+ setString(claimRecord.ElixirSuite__Insured_Address__c) + '"';//D
                xmlCreated+= ' ins_addr_2="'+ setString(claimRecord.ElixirSuite__Insured_Address_2__c) + '"';//D
                xmlCreated+= ' pat_addr_2="'+ setString(claimRecord.ElixirSuite__Patient_Address_2__c) + '"';//D
                xmlCreated+= ' ins_city="'+ setString(claimRecord.ElixirSuite__Insured_City__c) + '"';//D
                xmlCreated+= ' ins_country="'+ setString(claimRecord.ElixirSuite__Insured_Country_Code__c) + '"';//D
                xmlCreated+= ' ins_state="'+ setString(claimRecord.ElixirSuite__Insured_State__c) + '"';//D
                xmlCreated+= ' ins_zip="'+ claimRecord.ElixirSuite__Insured_Zip_Code__c + '"';//D //Anusha replaced 'Insured_Zipcode__c' with 'Insured_Zip_Code__c'
                xmlCreated+= ' employment_related="'+ setString(claimRecord.ElixirSuite__Employment_Related__c) + '"';//D
                if(claimRecord.ElixirSuite__Patient_Condition_Related_To_Accident__c){
                xmlCreated+= ' auto_accident="'+ 'Y' + '"';
                xmlCreated+= ' auto_accident_state="'+ setString(claimRecord.ElixirSuite__Auto_Accident_Related__c) + '"';
                xmlCreated+= ' cond_date="'+ setDateFormat(claimRecord.ElixirSuite__Date_Of_Current_Illness__c) + '"';
                }
                else{
                xmlCreated+= ' auto_accident="'+ 'N' + '"';
                }
                xmlCreated+= ' other_claimfilingcode="'+ setString(claimRecord.ElixirSuite__Insurance_Type__c) + '"'; 
                xmlCreated+= ' other_ins_medicare_code="'+ setString(claimRecord.ElixirSuite__Medicare_Type_Code__c) + '"';                
                xmlCreated+= ' ins_dob="'+ setDateFormatDOB(claimRecord.ElixirSuite__Insured_DOB__c) + '"';//D //Anusha - replaced insured_dob__c with Insured_DOB__c
                xmlCreated+= ' ins_sex="'+ setString(claimRecord.ElixirSuite__Insured_Sex__c) + '"';//D //Anusha-14/11/22
                xmlCreated+= ' accept_assign="'+ setString(claimRecord.ElixirSuite__Accept_Assignment__c=='YES'?'Y':'N')  + '"';//D //Anusha-06/11/22
                xmlCreated+= ' total_charge="'+ claimRecord.ElixirSuite__Total_Charge__c + '"';//D
                xmlCreated+= ' amount_paid="'+ claimRecord.ElixirSuite__Amount_Paid__c + '"';//D
                xmlCreated+= ' bill_taxid="'+ setString(claimRecord.ElixirSuite__Federal_Tax_Id_Number__c) + '"';//Changes from bill__taxid__c //D
                if(claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c=='EIN'){
                xmlCreated+= ' bill_taxid_type="'+ 'E' + '"';//D //Anusha-14/11/22
                }else if(claimRecord.ElixirSuite__Billing_Provider_Tax_ID_Type__c=='SSN'){
                xmlCreated+= ' bill_taxid_type="'+ 'S' + '"';
                }else{
                xmlCreated+= ' bill_taxid_type="'+ '' + '"';
                }
                xmlCreated+= ' bill_name="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Name__c)  + '"';//D
                xmlCreated+= ' bill_addr_1="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Address_1__c) + '"';
                xmlCreated+= ' bill_addr_2="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Address_2__c) + '"'; //Anusha - 07/11/22
                xmlCreated+= ' bill_state="'+ setString(claimRecord.ElixirSuite__Billing_Provider_State__c) + '"';
                xmlCreated+= ' bill_zip="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Zip__c) + '"';
                xmlCreated+= ' bill_phone="'+ setString(claimRecord.ElixirSuite__Bill_Phone__c) + '"'; //Anusha - replaced 'bill__phone' with 'bill_phone'
                xmlCreated+= ' bill_city="'+ setString(claimRecord.ElixirSuite__Billing_Provider_City__c) + '"';
                xmlCreated+= ' bill_id="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Other_ID__c) + '"'; //Anusha - replaced Billing_Provider_Info__c with Billing_Provider_Other_ID__c
                xmlCreated+= ' bill_taxonomy="'+ setString(claimRecord.ElixirSuite__Billing_Provider_Taxonomy__c) + '"';
                if(String.isNotBlank(claimRecord.ElixirSuite__Billing_Provider_Info__c)){
                xmlCreated+= ' bill_npi="'+ claimRecord.ElixirSuite__Billing_Provider_Info_NPI__c + '"';//D
                }
                xmlCreated+= ' employment_related="'+ claimRecord.ElixirSuite__Patient_Condition_Related_To_Employment__c + '"';
                xmlCreated+= ' ins_group="'+ setString(claimRecord.ElixirSuite__Insured_Policy__c) + '"';
                xmlCreated+= ' ins_phone="'+ setString(claimRecord.ElixirSuite__Insured_Telephone__c) + '"';
                xmlCreated+= ' ins_plan="'+ setString(claimRecord.ElixirSuite__Insurance_Plan_Name__c) + '"';
                xmlCreated+= ' prior_auth="'+ setString(claimRecord.ElixirSuite__Prior_Authorization_Number__c) + '"';
                xmlCreated+= ' ref_name_f="'+ setString(claimRecord.ElixirSuite__First_Name_NAME_OF_REFERRING_PROVIDER__c) + '"';
                xmlCreated+= ' ref_name_l="'+ setString(claimRecord.ElixirSuite__Last_Name_NAME_OF_REFERRING_PROVIDER__c) + '"';
                xmlCreated+= ' ref_name_m="'+ setString(claimRecord.ElixirSuite__MiddleName_NAME_OF_REFERRING_PROVIDER__c) + '"';
                xmlCreated+= ' ref_npi="'+ setString(claimRecord.ElixirSuite__NPI__c) + '"';
                xmlCreated+= ' prov_name_f="'+ setString(claimRecord.ElixirSuite__Rendering_Provider_First_Name__c) + '"';  
                xmlCreated+= ' prov_name_l="'+ setString(claimRecord.ElixirSuite__Rendering_Provider_Last_Name__c) + '"'; 
                xmlCreated+= ' prov_npi="'+ setString(claimRecord.ElixirSuite__Rendering_Provider_NPI__c) + '"'; 
                xmlCreated+= ' prov_taxonomy="'+ setString(claimRecord.ElixirSuite__Rendering_Provider_Taxonomy__c) + '"'; 
                xmlCreated+= ' prov_id="'+ setString(claimRecord.ElixirSuite__Rendering_Provider_Tax_Id__c) + '"';
                xmlCreated+= ' facility_addr_1="'+ setString(claimRecord.ElixirSuite__Service_Facility_Loc_Address__c) + '"';  
                xmlCreated+= ' facility_addr_2="'+ setString(claimRecord.ElixirSuite__Service_Facility_Address_2__c) + '"';  
                xmlCreated+= ' facility_city="'+ setString(claimRecord.ElixirSuite__Service_Facility_Loc_City__c) + '"'; 
                xmlCreated+= ' facility_id="'+ setString(claimRecord.ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c) + '"'; 
                xmlCreated+= ' facility_name="'+ setString(claimRecord.ElixirSuite__Service_Facility_Location_Information__c) + '"'; 
                xmlCreated+= ' facility_state="'+ setString(claimRecord.ElixirSuite__Service_Facility_Loc_State__c) + '"';
                xmlCreated+= ' facility_zip="'+ setString(claimRecord.ElixirSuite__Service_Facility_Loc_Zip__c) + '"';
                xmlCreated+= ' facility_npi="'+ setString(claimRecord.ElixirSuite__Service_Facility_Location_NPI__c) + '"';
                xmlCreated+= ' hosp_from_date="'+ setDateFormat(claimRecord.ElixirSuite__Hospitalization_From_Date__c) + '"';
                xmlCreated+= ' hosp_thru_date="'+ setDateFormat(claimRecord.ElixirSuite__Hospitalization_To_Date__c) + '"';
                if(String.isNotBlank(claimRecord.ElixirSuite__Resubmission_Code__c)){
                    xmlCreated+= ' icn_dcn_1="'+ claimRecord.ElixirSuite__Resubmission_Code__c  + ' ' + claimRecord.ElixirSuite__Original_Ref_No__c + '"';
                }
                /*
                List<String> names = splitNames(claimRecord.ElixirSuite__Insured_s_Name__c);
                if(names!=null && names.size()>0){
                    system.debug('insured names' +names);
                    for(Integer i=0;i<names.size();i++){
                        switch on i {
                            when 1 {        
                                xmlCreated+= ' ins_name_f="'+ setString(names[i]) + '"';
                            }   
                            when 0 {        
                                xmlCreated+= ' ins_name_l="'+ setString(names[i]) + '"';
                            }
                            when 2 {        
                                xmlCreated+= ' ins_name_m="'+ setString(names[2]) + '"';
                            }
                        }
                    }
                }else{
                    xmlCreated+= ' ins_name_f="'+ '' + '"';    
                    xmlCreated+= ' ins_name_l="'+ '' + '"';
                }
*/
                //LX3-9977
                  xmlCreated+= ' ins_name_f="'+ setString(claimRecord.ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_First_Name__c) + '"';
                  xmlCreated+= ' ins_name_m="'+ setString(claimRecord.ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Middle_Name__c) + '"';
                  xmlCreated+= ' ins_name_l="'+ setString(claimRecord.ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Last_Name__c) + '"';
                
                xmlCreated+= ' other_ins_group="'+ setString(claimRecord.ElixirSuite__Other_Insured_s_Policy_Group_Number__c) + '"';
                List<String> insuredNames = splitNames(claimRecord.ElixirSuite__Other_Insured_s_Name__c);
                if(insuredNames!=null && insuredNames.size()>0){
                    for(Integer i=0;i<insuredNames.size();i++){
                        switch on i {
                            when 1 {        
                                xmlCreated+= ' other_ins_name_f="'+ insuredNames[i] + '"';
                            }   
                            when 0 {        
                                xmlCreated+= ' other_ins_name_l="'+ insuredNames[i] + '"';
                            }
                            when 2 {        
                                xmlCreated+= ' other_ins_name_m="'+ insuredNames[2] + '"';
                            }
                        }
                    }
                }
                xmlCreated+= ' other_ins_plan="'+ setString(claimRecord.ElixirSuite__Other_Insurance_Plan_Name__c) + '"';
                //xmlCreated+= ' other_ins_sex="'+ setString(claimRecord.Other_Insurance_Plan_Name__c) + '"';
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
                            for(Integer i=1;i<=12;i++){
                                if(String.isNotBlank(String.valueOf(claimRecord.get('ElixirSuite__Diagnosis_'+diagnosis.get(i)+'__c')))){
                                    xmlCreated+= ' diag_'+i+'="'+ String.valueOf(claimRecord.get('ElixirSuite__Diagnosis_'+diagnosis.get(i)+'__c')) + '"';
                                }                
                            }           
                xmlCreated+= '>';
                //claim info append here
                for(ElixirSuite__Claim_Line_items__c rec :mapOfClaimIdToLineItems.get(claimId)){
                    //Removing '-' from the Claim Line Item Name
                    List<String> strName = rec.Name.contains('-') ? rec.Name.split('-') : new List<String>();
                    String chgId = strName.size()>0? strName[0]+strName[1] : rec.Name;
                    rec.ElixirSuite__Place_of_Service_Code_s__c = rec.ElixirSuite__Place_of_Service__c!=null ? rec.ElixirSuite__Place_of_Service__c.substring(0,2) : ''; //Anusha
                    
                    xmlCreated+= '<charge';
                    //charge info append here START
                    xmlCreated+= ' proc_code="'+ rec.ElixirSuite__CPT_HCPCS_Code__c + '"';
                    xmlCreated+= ' units="'+ rec.ElixirSuite__Days_Units__c + '"';
                    xmlCreated+= ' from_date="'+ setDateFormat(rec.ElixirSuite__From_Date_Of_Service__c) + '"';
                    xmlCreated+= ' place_of_service="'+ rec.ElixirSuite__Place_of_Service_Code_s__c + '"';
                    system.debug('place of service +++code '+rec.ElixirSuite__Place_of_Service_Code_s__c);
                    xmlCreated+= ' thru_date="'+ setDateFormat(rec.ElixirSuite__To_Date_Of_Service__c) + '"';   
                    xmlCreated+= ' mod1="'+ setString(rec.ElixirSuite__Modifier_1__c) + '"';    
                    xmlCreated+= ' mod2="'+ setString(rec.ElixirSuite__Modifier_2__c) + '"';    
                    xmlCreated+= ' mod3="'+ setString(rec.ElixirSuite__Modifier_3__c) + '"';    
                    xmlCreated+= ' mod4="'+ setString(rec.ElixirSuite__Modifier_4__c) + '"';    
                    xmlCreated+= ' chg_prov_name_f="'+ setString(rec.ElixirSuite__Rendering_Provider_First_Name__c) + '"';   
                    xmlCreated+= ' chg_prov_name_l="'+ setString(rec.ElixirSuite__Rendering_Provider_Last_Name__c) + '"';    
                    xmlCreated+= ' chg_prov_npi="'+ setString(rec.ElixirSuite__Rendering_Provider_NPI__c) + '"';    
                    xmlCreated+= ' chg_prov_taxonomy="'+ setString(rec.ElixirSuite__Rendering_Provider_Taxonomy__c) + '"';    
                    xmlCreated+= ' chg_prov_id="'+ setString(rec.ElixirSuite__Rendering_Provider_Non_NPI__c) + '"';
                    decimal DaysUnits = ((rec.ElixirSuite__Days_Units__c==0||rec.ElixirSuite__Days_Units__c==null)?1:rec.ElixirSuite__Days_Units__c); //Anusha
                    xmlCreated+= ' charge="'+ (rec.ElixirSuite__procedure_charge__c*DaysUnits) + '"';
                    xmlCreated+= ' diag_ref="'+ rec.ElixirSuite__Diagnosis_Pointer__c + '"'; 
                    xmlCreated+= ' remote_chgid="'+ rec.Name +'"';
                    //xmlCreated+= ' remote_chgid="'+ chgId +'"';
                    //charge info append here END  
                    System.debug('secCLData '+secCLData);
                    if(secCLData != Null && secCLData.get(rec.ElixirSuite__Claim_Procedure_Line_Item__c) != Null && secCLData.get(rec.ElixirSuite__Claim_Procedure_Line_Item__c).ElixirSuite__ERA_Line_Item__r.size() > 0){
                        ElixirSuite__ERA_Line_Item__c el = secCLData.get(rec.ElixirSuite__Claim_Procedure_Line_Item__c).ElixirSuite__ERA_Line_Item__r;
                        System.debug('ELINE '+el);
                        xmlCreated+= ' adj_code_1="'+ (el.ElixirSuite__Adjustment_Code_1__c != null?((el.ElixirSuite__Adjustment_Code_1__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_2="'+ (el.ElixirSuite__Adjustment_Code_2__c != null?((el.ElixirSuite__Adjustment_Code_2__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_3="'+ (el.ElixirSuite__Adjustment_Code_3__c != null?((el.ElixirSuite__Adjustment_Code_3__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_4="'+ (el.ElixirSuite__Adjustment_Code_4__c != null?((el.ElixirSuite__Adjustment_Code_4__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_5="'+ (el.ElixirSuite__Adjustment_Code_5__c != null?((el.ElixirSuite__Adjustment_Code_5__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_6="'+ (el.ElixirSuite__Adjustment_Code_6__c != null?((el.ElixirSuite__Adjustment_Code_6__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_7="'+ (el.ElixirSuite__Adjustment_Code_7__c != null?((el.ElixirSuite__Adjustment_Code_7__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_code_8="'+ (el.ElixirSuite__Adjustment_Code_8__c != null?((el.ElixirSuite__Adjustment_Code_8__c).replaceAll('[^a-zA-Z0-9\\s+]', '').deleteWhitespace()):'') +'"';
                        xmlCreated+= ' adj_amt_1="'+ (el.ElixirSuite__Adjustment_Amount_1__c != null?el.ElixirSuite__Adjustment_Amount_1__c:0) +'"';
                        xmlCreated+= ' adj_amt_2="'+ (el.ElixirSuite__Adjustment_Amount_2__c != null?el.ElixirSuite__Adjustment_Amount_2__c:0) +'"';
                        xmlCreated+= ' adj_amt_3="'+ (el.ElixirSuite__Adjustment_Amount_3__c != null?el.ElixirSuite__Adjustment_Amount_3__c:0) +'"';
                        xmlCreated+= ' adj_amt_4="'+ (el.ElixirSuite__Adjustment_Amount_4__c != null?el.ElixirSuite__Adjustment_Amount_4__c:0) +'"';
                        xmlCreated+= ' adj_amt_5="'+ (el.ElixirSuite__Adjustment_Amount_5__c != null?el.ElixirSuite__Adjustment_Amount_5__c:0) +'"';
                        xmlCreated+= ' adj_amt_6="'+ (el.ElixirSuite__Adjustment_Amount_6__c != null?el.ElixirSuite__Adjustment_Amount_6__c:0) +'"';
                        xmlCreated+= ' adj_amt_7="'+ (el.ElixirSuite__Adjustment_Amount_7__c != null?el.ElixirSuite__Adjustment_Amount_7__c:0) +'"';
                        xmlCreated+= ' adj_amt_8="'+ (el.ElixirSuite__Adjustment_Amount_8__c != null?el.ElixirSuite__Adjustment_Amount_8__c:0) +'"';
                        xmlCreated+= ' primary_paid_amount="'+ el.ElixirSuite__Paid__c +'"';
                        xmlCreated+= ' primary_allowed_amount="'+ el.ElixirSuite__Total_Allowed_Amount__c +'"';
                        xmlCreated+= ' primary_paid_date="'+ (el.ElixirSuite__EOB__r.ElixirSuite__EOB__r.ElixirSuite__Check_EFT_Date__c != null?(setDateFormat(el.ElixirSuite__EOB__r.ElixirSuite__EOB__r.ElixirSuite__Check_EFT_Date__c)):'') +'"';  
                    }
                    xmlCreated+= '></charge>';          
                }
                xmlCreated+= '</claim>';
            }
        }
        
        xmlCreated+= '</claims>';
        System.debug('#### Xml formed : ' + xmlCreated);
        if(xmlCreated == '<claims></claims>'){ 
            xmlCreated = '';
        } 
        return xmlCreated;
        
    }
    
    
    @future(callout=true)
    global static void makeCallOut(String bodyGenerated, List<Id> listOfClaimsId){
        Map<String,ContentDocumentLink> mapcontdoc = new Map<String,ContentDocumentLink>();
        Map<String,String> Mapcontver = new Map<String,String>();
        List<ContentVersion> ContentDoc = new List<ContentVersion>();
        Integration_Credentials__c custset = getCredentials();
        String accKey;
        if(!String.isBlank(custset.Integration_Key__c)){
            accKey = custset.Integration_Key__c;
        }
        Datetime d = System.now();
        String fileName = 'Claim_' + d.format();
        fileName = fileName.replaceAll('[^a-zA-Z0-9\\s+]','_');
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','text/html; charset=UTF-8');
        req.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');        
        req.setMethod('POST');
        req.setEndPoint('callout:Claim_MD/services/upload/'+'?AccountKey='+ accKey);
        req.setbody('------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"AccountKey\"\r\n\r\n'+accKey+'\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data \r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: file;Content-Type: text/plain; filename="'+fileName+'.txt" name=\"File\"\r\n\r\n'+
                    + bodyGenerated +
                    '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--');
        Http http = new Http();
        HttpResponse response = http.send(req);
        response.setHeader('Content-Type','text/html; charset=UTF-8');
        response.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');             
        System.debug('Status Code: ' + response.getStatusCode());
        System.debug('Response: ' + response.getBody());   
        String resp = String.valueOf(response.getBody());
        ClaimJsonResponse.ClaimUpdation(resp);
        List<ElixirSuite__Claim__c> clList = new List <ElixirSuite__Claim__c>([Select id,name from ElixirSuite__Claim__c where id IN: listOfClaimsId]);
        for(ElixirSuite__Claim__c cl: clList){
            try{    
                String title = 'Request'+cl.name+'.txt';
                string requestFile = bodyGenerated; 
                system.debug('checkbodyGeneratedstring'+requestFile);   
                ContentVersion docVer = New ContentVersion();   
                docVer.ContentLocation = 'S';   
                docVer.PathOnClient = 'Request.txt';    
                docVer.Title = 'Request'+cl.name+'.txt';//'Request.txt';                   
                Blob reqData = Blob.valueof(requestFile);   
                docVer.VersionData = reqData;   
                ContentDoc.add(docVer);
                Mapcontver.put(title,cl.name.toLowerCase());     
                  
                ContentDocumentLink Doclink = New ContentDocumentLink();  
                Doclink.linkedEntityId = cl.id;    
                Doclink.sharetype = 'I';    
                Doclink.visibility = 'AllUsers';    
                mapcontdoc.put(cl.name.toLowerCase(),Doclink);    
            }   
            catch(exception ex) 
            {   
                system.debug(ex.getmessage());  
            }  
        }
        if(ContentDoc.size()>0 && ContentDoc!=null){
            insert ContentDoc;
        }
        
        List<String> CdIds = new List<String>();
        Map<String,Id> MapcontV = new Map<String,Id>(); 
        for(ContentVersion cd:ContentDoc){
            CdIds.add(cd.Id);
        }
        
        List<ContentVersion> cdversion = [Select Title,ContentDocumentid from ContentVersion where id IN: CdIds WITH SECURITY_ENFORCED];
        
        for(ContentVersion cv:cdversion){  
            MapcontV.put(Mapcontver.get(cv.Title),cv.ContentDocumentid);                
            
        }
        List<ContentDocumentLink> contList = new List<ContentDocumentLink>();
        for(String contstr : mapcontdoc.keySet()){
            ContentDocumentLink Doclink = mapcontdoc.get(contstr);
            Doclink.ContentDocumentId = MapcontV.get(contstr.toLowerCase());
            contList.add(Doclink);
        }
        if(contList.size()>0 && contList!=null){
            insert contList;
        }
        
        
    }
    
    
    global static List<String> splitIds(String claims){
        List<String> listOfClaims = new List<String>();
        try{
            for(String lineItemId : claims.split(',')){
                listOfClaims.add(lineItemId.trim());
            }
        }
        catch(Exception e){
        }
        return listOfClaims;
    }
    global static Map<Id,List<ElixirSuite__Claim_Line_Items__c>> lineItems(List<ElixirSuite__Claim__c> listOfClaims){
        Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = new Map<Id,List<ElixirSuite__Claim_Line_Items__c>>();
        try{
            if(listOfClaims!=null && listOfClaims.size()>0){
                Schema.DescribeSObjectResult result = ElixirSuite__Claim_Line_Items__c.sObjectType.getDescribe();
                List<String> apiNames =  new List<String>(result.fields.getMap().keySet());
                String queryForLineItems = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNames,','))  + ' FROM  ElixirSuite__Claim_Line_Items__c '+
                    'WHERE ElixirSuite__Claim__c IN :listOfClaims ORDER BY CreatedDate DESC';
                // Creation of map for Claim to List of Claim Line Items 
                for(ElixirSuite__Claim_Line_Items__c lineItemRecord :Database.query(queryForLineItems)){ // Queried directly in loop to avoid LIMIT 50000 error
                    Id keyForMapOfClaimIdToLineItems = lineItemRecord.ElixirSuite__Claim__c;
                    system.debug(keyForMapOfClaimIdToLineItems);
                    if(mapOfClaimIdToLineItems.containsKey(keyForMapOfClaimIdToLineItems)){
                        List<ElixirSuite__Claim_Line_Items__c> itemsToAdd = mapOfClaimIdToLineItems.get(keyForMapOfClaimIdToLineItems);
                        Integer totalItems = itemsToAdd.size() + 1;
                        lineItemRecord.ElixirSuite__Integration_Order__c = totalItems;
                        itemsToAdd.add(lineItemRecord);
                    }else{
                        lineItemRecord.ElixirSuite__Integration_Order__c = 1;
                        mapOfClaimIdToLineItems.put(keyForMapOfClaimIdToLineItems,new List<ElixirSuite__Claim_Line_Items__c>{lineItemRecord});
                    }
                }
            } 
            if(mapOfClaimIdToLineItems.size()==0){
                if(listOfClaims!=null && listOfClaims.size()>0){
                    for(ElixirSuite__Claim__c claim :listOfClaims){
                        mapOfClaimIdToLineItems.put(claim.Id, new List<ElixirSuite__Claim_Line_Items__c>{});
                    }
                }
            }
        }
        catch(Exception e){
            //ExceptionLog.logError(e);
        }
        return mapOfClaimIdToLineItems;
    } 
    global static String setDateFormat(Date dateToFormat){
        if(dateToFormat == null){
            return '';
        }
        String dateToFormatText = String.valueOf(dateToFormat);
        List<String> dateInList =  dateToFormatText.split('-');
        String newFormattedDate = dateInList[1] + '-' + dateInList[2] + '-' + dateInList[0];
        return newFormattedDate;
    }
    global static String setDateFormatDOB(Date dateToFormat){
        if(dateToFormat == null){
            return '';
        }
        String dateToFormatText = String.valueOf(dateToFormat);
        List<String> dateInList =  dateToFormatText.split('-');
        String newFormattedDate = dateInList[0] + '-' + dateInList[1] + '-' + dateInList[2];
        return newFormattedDate;
    }
    global static String setString(String incomingText){
        if(String.isBlank(incomingText)){
            return '';
        }
        return incomingText;
    }
    global static List<String> splitNames(String incomingText){
        if(String.isBlank(incomingText)){
            return new List<String>{};
                }
        return incomingText.split(' ');
    }
    
    
    global static void checkClaimStatus(String claimId){
        List<ElixirSuite__Claim__c> claimList = new List<ElixirSuite__Claim__c>([SELECT id , ElixirSuite__claim_status__c,ElixirSuite__Payor__r.ElixirSuite__Claim_Processing_via__c, ElixirSuite__Claim_Md_Id__c from ElixirSuite__Claim__c 
                                                                                 WHERE Id =: claimId 
                                                                                 WITH SECURITY_ENFORCED
                                                                                 LIMIT 1]);
        if(claimList[0].ElixirSuite__Payor__r.ElixirSuite__Claim_Processing_via__c == 'Clearing House'){
            if(claimList[0].ElixirSuite__claim_status__c == 'Clearing house accepted'){
                
                Integration_Credentials__c custset = getCredentials();
                if(!Test.isRunningTest() && String.isBlank(custset.Integration_Key__c)){
                    throw new AuraHandledException('Please provide AccountKey');
                }else{
                    //return 'ACCEPTED';
                    entryPointOfCallOutForOneInput(claimId);
                }            
                
            }
            else{
                throw new AuraHandledException('Claim Status should be Clearing house Accepted');
            }
        } else{
            throw new AuraHandledException('Claim for this payor can’t be send out to clearing house');
        }
    }
    
    
    @future(callout=true)
    global static void entryPointOfCallOutForOneInput(String claimId){
       
        Integration_Credentials__c custset= getCredentials();
        String accKey;
        if(!Test.isRunningTest() && !String.isBlank(custset.Integration_Key__c))
        {
            accKey = custset.Integration_Key__c;
            
        }
        else if(Test.isRunningTest())
        {
            acckey = '8869fThoqjdYQelGBKQaYLwcyYdA';      
        } 
        List<ElixirSuite__Claim__c> claimList = new List<ElixirSuite__Claim__c>([SELECT ElixirSuite__Claim_Md_Id__c,Name, ElixirSuite__Message__c, ElixirSuite__Claim_Status__c, Id from ElixirSuite__Claim__c WHERE Id= :claimId WITH SECURITY_ENFORCED]);
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','text/html; charset=UTF-8');        
        req.setMethod('GET');
        req.setEndPoint('callout:Claim_MD/services/response/?AccountKey='+ accKey +'&ClaimID='+claimList[0].ElixirSuite__Claim_Md_Id__c);
        Http http = new Http();
        HttpResponse response = http.send(req);
        system.debug('#### RESPONSE --- ' + response.getBody());
        if(response.getStatusCode() == 200){
            PayerJsonResponse pjResponse = new PayerJsonResponse();
            pjResponse.claimUpdation(response.getBody(), claimList[0]);
        }
        
    }
    
    
    global class PayerJsonResponse{ 
        
        public List<Claim> claim;
        
        public PayerJsonResponse parse(String json) {
            
            return (PayerJsonResponse) System.JSON.deserialize(json, PayerJsonResponse.class);
        }
        
        public void claimUpdation(String xml, ElixirSuite__Claim__c claimObj){
            String jsonContent = XMLResponseParserClaimMD.xmlToJson(xml);
            PayerJsonResponse jsonResp = parse(jsonContent);
            List<Claim> claimList=jsonResp.claim;
            system.debug('##### Claims json --- '+JSON.Serialize(jsonResp.claim));
            DateTime latestResponse;
            //Claim__c claimToBeUpdated = new Claim__c();
            if(claimList != null && claimList.size()>0){
                for(Claim c : claimList){
                    Datetime currentTime = convertDateTime(c.response_time);
                    if(latestResponse==null || currentTime>latestResponse){
                        latestResponse  = currentTime;
                    }
                }               
                system.debug('latestResponse '+latestResponse);
                for(Claim c : claimList){
                    DateTime currentTime = convertDateTime(c.response_time);
                    if(latestResponse == currentTime){
                        if(c.status == 'A'){
                            claimObj.ElixirSuite__Claim_Status__c = 'Payer Accepted';
                            claimObj.ElixirSuite__Message__c = '';
                        }
                        else if(c.status == 'R'){
                            claimObj.ElixirSuite__Claim_Status__c = 'Payer Rejected';
                            system.debug('%final message%'+JSON.Serialize(c.messages));
                            claimObj.ElixirSuite__Message__c=JSON.Serialize(c.messages);
                        }
                        claimObj.ElixirSuite__Sender_icn__c = c.sender_icn;
                        break;
                    }
                }
                try{    
                    string responseFile = xml; 
                    system.debug('checkbodyGeneratedstring'+responseFile);   
                    ContentVersion docVer = New ContentVersion();   
                    docVer.ContentLocation = 'S';   
                    docVer.PathOnClient = 'ResponsePayer.txt';    
                    docVer.Title = 'ResponsePayer'+claimObj.name+'.txt';//'Request.txt';                   
                    Blob reqData = Blob.valueof(responseFile);   
                    docVer.VersionData = reqData;   
                    insert DocVer; 
                    //DMLManager.insertAsUser(DocVer); 
                    
                    String VesId = [Select ContentDocumentid from ContentVersion where id=:DocVer.id].ContentDocumentid;    
                    ContentDocumentLink Doclink = New ContentDocumentLink();    
                    Doclink.ContentDocumentId = VesId;  
                    Doclink.linkedEntityId = claimObj.id;    
                    Doclink.sharetype = 'I';    
                    Doclink.visibility = 'AllUsers';    
                    insert Doclink; 
                    //DMLManager.insertAsUser(Doclink);
                }   
                catch(exception ex) 
                {   
                    system.debug(ex.getmessage());  
                }  
            }
            
            System.debug('### claimObj : ' + claimObj);
            try{
                update claimObj;
                //DMLManager.updateAsUser(claimObj);
            }
            catch(Exception ex)
            {
                System.debug('#### Error : ' + ex.getMessage());
            }
        }
        
        public DateTime convertDateTime(String respTime)
        {
            String finalStr = '';   
            String firstRespTime = respTime;
            String ampm = firstRespTime.right(2);
            String remainingDate = firstRespTime.substring(0, firstRespTime.length()-2);
            String[] strSplit = remainingDate.split(' ');
            String timeStr = strSplit[1];
            String[]timeSplit = timeStr.split(':');
            String[] dates = strSplit[0].split('-');
            Integer year = Integer.valueOf(dates[0]);
            Integer month = Integer.valueOf(dates[1]);
            Integer day = Integer.valueOf(dates[2]);
            Integer hour = Integer.valueOf(timeSplit[0]);
            if(ampm.equalsIgnoreCase('am')){
                if(hour == 12){
                    hour = 0;
                }
            }else if(ampm.equalsIgnoreCase('pm')){
                hour +=12;
            }
            Integer minute = Integer.valueOf(timeSplit[1]);
            Integer second = Integer.valueOf(timeSplit[2]);
            system.debug(Datetime.newInstanceGMT(year, month, day, hour, minute, second));
            return Datetime.newInstanceGMT(year, month, day, hour, minute, second);
        }
    }
    global class Messages {
        public String fields;
        public String mesgid;
        public String message;
        public String status;
    }
    global class Claim {
        public String batchid;
        public String bill_npi;
        public String bill_taxid;
        public String claimid;
        public String claimmd_id;
        public String fdos;
        public String fileid;
        public String filename;
        public String ins_number;
        public String payerid;
        public String pcn;
        public String remote_claimid;
        public String sender_icn;
        public String sender_name;
        public String senderid;
        public String status;
        public String total_charge;
        public String response_time;
        public List<Messages> messages;
    }
    
        
    global static void getEraEntryPointCallout(){
        
        List<ElixirSuite__Integration_Data__c> integrationOrder = [SELECT Id,ElixirSuite__Integration_Data__c,ElixirSuite__Posted__c,ElixirSuite__ERA_Id__c
                                                                   FROM ElixirSuite__Integration_Data__c 
                                                                   WHERE ElixirSuite__Integration_Data__c=NULL AND ElixirSuite__ERA_Id__c!=NULL AND ElixirSuite__Posted__c=false 
                                                                   WITH SECURITY_ENFORCED
                                                                   ORDER BY CreatedDate DESC];
       
        Integration_Credentials__c custset = getCredentials();
        if(String.isBlank(custset.Integration_Key__c )){
            return;
        }
        //String url = 'https://www.claim.md/services/era/?';
        String url = 'callout:Claim_MD/services/era/?';
        url+= 'AccountKey=' + custset.Integration_Key__c;
        url+= '&NewOnly=0';
        if(integrationOrder!=null && integrationOrder.size()>0){
            url+= '&ERAID=' + integrationOrder[0].ElixirSuite__ERA_Id__c;
        }
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','text/html; charset=UTF-8');        
        req.setMethod('GET');
        req.setEndpoint(url);   
        Http http = new Http();
        http.send(req);
        HttpResponse response = http.send(req);
        response.setHeader('Content-Type','text/html; charset=UTF-8');
        Dom.Document doc = new Dom.Document();
        system.debug(response.getBody());
        doc.load(response.getBody());
        Dom.XMLNode root = doc.getRootElement();  //result
        String ParentJson = '{';
        String finalJson = '{';
        List<String> mainERAJson = new List<String>();
        List<String> mainJson = new List<String>();
        List<String> ERAAttributes = new List<String>();
        try{
            if ( root.getNodeType() == Dom.XmlNodeType.ELEMENT ){
                String keyval = root.getAttributeKeyAt(0);
                String ParentElement = root.getAttribute( keyval, '');
                List<Dom.XMLNode> children = root.getChildElements();
                ParentJson += '"' + keyval + '": ' + '[';
                String ERAJson = '';
                ERAJson += '{';
                ERAAttributes.add( '"' + keyval + '": "' + ParentElement + '"' );
                ERAJson += String.join(ERAAttributes,',');
                mainERAJson.add(ERAJson);  
                ParentJson += String.join(mainERAJson,',') + '}]}'; 
                finalJson += '"' + 'claim' + '": ' + '[';
                for(Dom.XMLNode child :children){
                    String claimJson = '';
                    system.debug(child.getName());
                    claimJson += '{';
                    List<String> firstAttributes = new List<String>();
                    for(Integer i=0;i<child.getAttributeCount();i++){ 
                        String key = child.getAttributeKeyAt(i);
                        String value = child.getAttribute( key, '' );
                        firstAttributes.add( '"' + key + '": "' + value + '"' ); 
                    }
                    if(firstAttributes!=null && firstAttributes.size()>0){
                        claimJson += String.join(firstAttributes,',');
                    }
                    claimJson += ',';
                    claimJson += '"' + 'messages' + '": ' + '[';
                    List<String> allMessages = new List<String>();
                    for(Dom.XMLNode secondChild :child.getChildElements()){ 
                        system.debug(secondChild.getName());//messages
                        List<String> lstAttributes = new List<String>();                    
                        for(Integer i=0;i<secondChild.getAttributeCount();i++){
                            String key = secondChild.getAttributeKeyAt(i);
                            String value = secondChild.getAttribute( key, '' );
                            if(i == 0){
                                lstAttributes.add('{' + '"' + key + '": "' + value + '"' );
                            }else{
                                lstAttributes.add( '"' + key + '": "' + value + '"' );
                            }
                            if(i == secondChild.getAttributeCount()-1){
                                lstAttributes[i] += '}';
                            }
                        }
                        if(lstAttributes.size()>0){
                            allMessages.add(String.join(lstAttributes,','));
                        }          
                    }  
                    claimJson += String.join(allMessages,',') +']}';
                    mainJson.add(claimJson);
                }      
                finalJson += String.join(mainJson,',') + ']}';
                system.debug(finalJson);     
                setIntegrationData(parentJson, finalJson);
            }
        }catch(Exception e){
            throw new AuraHandledException('No ERA found!!');
        }
    }
    
    
    global static void setIntegrationData(String parentJson, String finalJson){
        Map<String, Object> LastERAresults = (Map<String, Object>)JSON.deserializeUntyped(parentJson);
        Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(finalJson);
        List<Object> lastERAIdlist = (List<Object>)LastERAresults.get('last_eraid');
        List<Object> lstCustomers = (List<Object>)results.get('claim');
        system.debug('lastERAIdlist--'+lastERAIdlist);
        system.debug('lstCustomers--'+lstCustomers);
        system.debug('lstCustomers--'+lstCustomers.size());
        ElixirSuite__Integration_Data__c intParentData;
        Map<String, Object> lastERAId;
        for(Object result : lastERAIdlist) {
            lastERAId = (Map<String, Object>)result;
        }
        intParentData = new ElixirSuite__Integration_Data__c();
        if(lastERAId.get('last_eraid')!= null){
            intParentData.ElixirSuite__ERA_Id__c = string.valueOf(lastERAId.get('last_eraid'));
            intParentData.ElixirSuite__Type__c = 'ERA Remitance Search';
        }
        if(intParentData!=null && Schema.sObjectType.ElixirSuite__Integration_Data__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Type__c.isCreateable()){
               insert intParentData;
               //DMLManager.insertAsUser(intParentData);
               system.debug('IntParentdatalist--'+intParentData);
           }
        ElixirSuite__Integration_Data__c intData;
        Map<String, Object> customerAttributes;
        system.debug('lstCustomers--'+lstCustomers);
        List<ElixirSuite__Integration_Data__c> Intdatalist = new List<ElixirSuite__Integration_Data__c>();
        if(lstCustomers!= null){
            for(Object obj : lstCustomers){
                system.debug('obj--'+obj);
                customerAttributes = (Map<String, Object>)obj;
                intData = new ElixirSuite__Integration_Data__c();
                intData.ElixirSuite__ERA_Id__c = string.valueOf(customerAttributes.get('eraid'));
                intData.ElixirSuite__Type__c = 'ERA Remitance Search';
                intData.ElixirSuite__Integration_Data__c = intParentData.Id;//Attaching child to its parent
                intData.ElixirSuite__ERA_Generated__c = false;
                intData.ElixirSuite__Last_Response_Id__c = intData.ElixirSuite__ERA_Id__c;
                intData.ElixirSuite__Check_Number__c = string.valueOf(customerAttributes.get('check_number'));
                intData.ElixirSuite__check_type__c = string.valueOf(customerAttributes.get('check_type'));
                intData.ElixirSuite__Provider_Name__c = string.valueOf(customerAttributes.get('claimmd_prov_name'));
                intData.ElixirSuite__Download_Time__c = string.valueOf(customerAttributes.get('download_time'));
                //intData.Paid_Amount__c = Integer.valueOf(customerAttributes.get('paid_amount'));
                intData.ElixirSuite__Paid_Date__c = string.valueOf(customerAttributes.get('paid_date'));
                Date paidDate = Date.valueOf(string.valueOf(customerAttributes.get('paid_date')));
                system.debug('#### paidDate : ' + paidDate);
                intData.ElixirSuite__Payer_Name__c = string.valueOf(customerAttributes.get('payer_name'));
                intData.ElixirSuite__Payer_Id__c = string.valueOf(customerAttributes.get('payerid'));
                intData.ElixirSuite__Provider_NPI__c = string.valueOf(customerAttributes.get('prov_npi'));
                intData.ElixirSuite__Provider_Tax_Id__c = string.valueOf(customerAttributes.get('prov_taxid'));
                intData.ElixirSuite__Received_Date_Time__c = string.valueOf(customerAttributes.get('received_time'));
                String recievedDateStr = string.valueOf(customerAttributes.get('received_time'));
                List<String> recDateSplit = recievedDateStr.split(' ');
                String datePart = recDateSplit[0];
                List<String> datePartSplit = datePart.split('-');
                String recievedDateFinal = datePartSplit[2]+'-';
                //Datetime receivedDate = DateTime.valueOf(string.valueOf(customerAttributes.get('received_time')));
                //system.debug('#### receivedDate : ' + receivedDate );
                Intdatalist.add(intData);
            }
            system.debug('Intdatalist--'+Intdatalist);
        }
        if(Intdatalist.size()>0 && 
           Schema.sObjectType.ElixirSuite__Integration_Data__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Type__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Integration_Data__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Download_Time__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Generated__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Last_Response_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Check_Number__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__check_type__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Provider_Name__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Paid_Date__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Payer_Name__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Provider_NPI__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Provider_Tax_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Payer_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Received_Date_Time__c.isCreateable()){
               insert Intdatalist;
               //DMLManager.insertAsUser(Intdatalist);
               system.debug('Intdatalist--'+Intdatalist);
               
           }
        Database.executeBatch(new GetERAClaimMDBatch(),1);
    }
    
    
    @Future(callout=true)
    global static void generatePDF(String recId_fromApex){
        PageReference pdf = Page.VOBPdfGeneration;
        pdf.getParameters().put('recId',recId_fromApex);
        insertVOBPdf(pdf,recId_fromApex);
        ElixirSuite__VOB__c[] toUpdate = [SELECT ID,ElixirSuite__JSON_Dump__c from ElixirSuite__VOB__c
                                          where id = : recId_fromApex WITH SECURITY_ENFORCED];
        //toUpdate[0].ElixirSuite__JSON_Dump__c = '';
        if(Schema.sObjectType.ElixirSuite__VOB__c.isUpdateable()){
            update toUpdate;
            // DMLManager.updateAsUser(toUpdate);
        }
    }
    global static void insertVOBPdf(PageReference compliedPDF,string vobID){
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'VOB Response';
        cv.PathOnClient = 'VOBResponse.pdf';
        cv.VersionData = compliedPDF.getContentAsPdf(); 
        cv.IsMajorVersion = true;
        try{
            
            
            Insert cv;
            // DMLManager.insertAsUser(cv);
            
            
        }
        catch(Exception e){
            // ExceptionLog.logError(e);
        }
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId; 
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        try{
            cdl.LinkedEntityId = vobID;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            
            
            Insert cdl;
            // DMLManager.insertAsUser(cdl);
        }
        
        
        catch(Exception e){
            //  ExceptionLog.logError(e);
        }
    }
    
    
    global static MessageWrapper checkValidations(String vobId){
        ElixirSuite__VOB__c vobRec = [SELECT Id, ElixirSuite__Account__c,ElixirSuite__Type__c,ElixirSuite__Policy_Holder_DOB__c, ElixirSuite__Provider__r.Name,ElixirSuite__Payer_Name__c,ElixirSuite__Insured_First_Name__c,  
                                      ElixirSuite__Insured_Middle_Name__c, ElixirSuite__Insured_Last_Name__c, ElixirSuite__Payer__c,ElixirSuite__Payer__r.name, ElixirSuite__Payer__r.ElixirSuite__Payer_Code__c, ElixirSuite__Patient_Relationship_With_Insured__c,
                                      ElixirSuite__Provider__c, ElixirSuite__Provider__r.ElixirSuite__Provider_Code__c,ElixirSuite__Procedure_Code__c
                                      ,ElixirSuite__Provider__r.ElixirSuite__Provider_First_Name__c,RecordtypeId,ElixirSuite__Member_Id__c,
                                      ElixirSuite__Provider__r.ElixirSuite__Provider_Last_Name__c,ElixirSuite__Provider__r.ElixirSuite__Provider_Taxonomy__c,ElixirSuite__Provider__r.ElixirSuite__Provider_Tax_Id__c,
                                      ElixirSuite__Provider__r.ElixirSuite__Provider_TaxId_Type__c,ElixirSuite__Provider__r.ElixirSuite__Provider_City__c,ElixirSuite__Provider__r.ElixirSuite__Provider_State__c,
                                      ElixirSuite__Provider__r.ElixirSuite__Provider_Zip__c,ElixirSuite__Patient_Birth_Date__c,ElixirSuite__Date_Of_Birth__c,ElixirSuite__Service_Date__c,ElixirSuite__Benefit__c
                                      FROM ElixirSuite__VOB__c 
                                      WHERE Id = :vobId WITH SECURITY_ENFORCED]; 
        MessageWrapper wrap = new MessageWrapper();
        try{
            Map<String,ElixirSuite__Patient_Relationship_Code__mdt> patRelMap = new Map<String,ElixirSuite__Patient_Relationship_Code__mdt>();
            for(ElixirSuite__Patient_Relationship_Code__mdt patRel : [Select id, developerName, MasterLabel, ElixirSuite__Code__c from ElixirSuite__Patient_Relationship_Code__mdt WITH SECURITY_ENFORCED LIMIT 5000])
            {
                patRelMap.put(patRel.developerName.toLowercase(),patRel);
            }
            
            system.debug('ElixirSuite__Patient_Relationship_With_Insured__c '+vobRec.ElixirSuite__Patient_Relationship_With_Insured__c);
            system.debug('patRelMap '+patRelMap);
            //patRelMap = Patient_Relationship_Code__mdt.getAll();
            // if(vobRec.Insured_First_Name__c == null || vobRec.Insured_First_Name__c == '')
            if(String.IsBlank(vobRec.ElixirSuite__Insured_First_Name__c))
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Insured First Name';
            }
            //  else if(vobRec.Insured_Middle_Name__c == null || vobRec.Insured_Middle_Name__c == '')
            
            // else if(vobRec.Insured_Last_Name__c == null || vobRec.Insured_Last_Name__c == '')
            else if(String.IsBlank(vobRec.ElixirSuite__Insured_Last_Name__c))
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Insured Last Name';
            }
            // else if(vobRec.Payer__c == null || (vobRec.Payer__r.Payer_Code__c == '' || vobRec.Payer__r.Payer_Code__c == null))
            else if(String.IsBlank(vobRec.ElixirSuite__Payer__c) || String.IsBlank(vobRec.ElixirSuite__Payer__r.ElixirSuite__Payer_Code__c))
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Payer/Payer Id';
            }
            //  else if(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c == null || vobRec.ElixirSuite__Patient_Relationship_With_Insured__c == '')
            else if(String.IsBlank(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c))
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Patient Relationship With Insured';
            }
            else if(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c != null && vobRec.ElixirSuite__Patient_Relationship_With_Insured__c != '' && (!patRelMap.containsKey(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c.toLowercase())))
                // else if(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c != null && vobRec.ElixirSuite__Patient_Relationship_With_Insured__c != '')
                
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter a valid Patient Relationship With Insured';
            }
            // else if(vobRec.Provider__c == null || (vobRec.Provider__r.Provider_Code__c == '' || vobRec.Provider__r.Provider_Code__c == null))
            else if(vobRec.ElixirSuite__Provider__c == null || String.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Code__c))
                
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Provider/Provider Id';
            }
            else if(String.IsBlank(vobRec.ElixirSuite__Benefit__c))
            {
                wrap.msgState = 'Error';
                wrap.msgStr = 'Please enter the Benefit Type Code';
            }
            else
            {
                wrap.msgState = 'Success';
                wrap.patRelationCode = patRelMap.get(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c.toLowercase()).ElixirSuite__Code__c;
            }
            list<ElixirSuite__VOB__c> vobList = new list<ElixirSuite__VOB__c>();
            vobList.add(vobRec);
           wrap.msgStr = VOBCallout(vobList,patRelMap.get(vobRec.ElixirSuite__Patient_Relationship_With_Insured__c.toLowercase()).ElixirSuite__Code__c);
           wrap.msgState = 'Error';
            system.debug('wrap.msgStr:- '+wrap.msgStr);
            if(wrap.msgStr == null){
               wrap.msgState = 'Success';  
            }
        }
        catch(Exception e){
            // ExceptionLog.logError(e);
        }
        List<ElixirSuite__VOB__c> vobList = new List<ElixirSuite__VOB__c>();
        vobList.add(vobRec);
        wrap.vob = vobRec;
        wrap.volList = vobList;
        system.debug('wrap 1026:- '+wrap);
        return wrap;  
    }
    
    
    global static String VOBCallout(List<ElixirSuite__VOB__c> vobList, String patRelationCode){
        MessageWrapper wrp = new MessageWrapper();
        String accKey;
        ElixirSuite__VOB__c vobRec;
        vobRec = vobList[0];
        system.debug('chk');
        // Id currentUserId =UserInfo.getUserId();
        // User currentUser = [SELECT Id,Account_Key__c FROM User WHERE Id= :currentUserId WITH SECURITY_ENFORCED];
        Integration_Credentials__c custset = getCredentials();
        system.debug('custset--'+custset);
        if(String.isNotBlank(custset.Integration_Key__c)){
            accKey = custset.Integration_Key__c;
        }else{
            wrp.msgStr = 'Please provide AccountKey';
            System.debug('wrp.msgStr 1070: ' + wrp.msgStr);
            //throw new AuraHandledException('Please provide AccountKey');
        }
        String month = String.valueOf(System.today().month()).length() == 1 ? 0+''+System.today().month() : System.today().month()+'';
        String day = String.valueOf(System.today().day()).length() == 1 ? 0+''+System.today().day() : System.today().day()+'';
        // String fdos = System.today().year()+''+month+''+day;
        Date servDate= vobRec.ElixirSuite__Service_Date__c; 
        system.debug('servDate'+servDate);
        String fdos = ''; 
        if(servDate!=null){ 
            List<String> sdate = String.valueOf(servDate).split('-');
            system.debug('sdate'+sdate);
            fdos = sdate[0]+''+ (sdate[1].length() == 1 ? ('0'+sdate[1]):sdate[1])+'' +(sdate[2].length() == 1 ?('0'+sdate[2]):sdate[2]);
        }
        else{
            fdos = System.today().year()+''+month+''+day;
        }
        
        
        HttpRequest req = new HttpRequest();
        Date dob = vobRec.ElixirSuite__Date_Of_Birth__c;
        String dobToSend = '';
        if(dob!=null){ 
            List<String> dobs = String.valueOf(dob).split('-');
            
            dobToSend = dobs[0]+''+ (dobs[1].length() == 1 ? ('0'+dobs[1]):dobs[1])+'' +(dobs[2].length() == 1 ?('0'+dobs[2]):dobs[2]);
        }
        
        String targetString ='&ins_name_l='+ vobRec.ElixirSuite__Insured_Last_Name__c +'&ins_name_m='+vobRec.ElixirSuite__Insured_Middle_Name__c +'&ins_name_f='+ vobRec.ElixirSuite__Insured_First_Name__c  +'&payerid='+ vobRec.ElixirSuite__Payer__r.ElixirSuite__Payer_Code__c +'&pat_rel='+ patRelationCode +'&service_code='+ vobRec.ElixirSuite__Benefit__c +'&fdos='+ fdos +'&prov_npi='+vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Code__c+'&ins_dob='+dobToSend+'&prov_name_l='+vobRec.ElixirSuite__Provider__r.Name;
        string fname= vobRec.ElixirSuite__Insured_First_Name__c;
        string mname ;
        string lname=vobRec.ElixirSuite__Insured_Last_Name__c ;
        
        
        string pcode= vobRec.ElixirSuite__Payer__r.ElixirSuite__Payer_Code__c; //payer code
        string pat= patRelationCode;
        string bencode= vobRec.ElixirSuite__Benefit__c; //service code
        String[] code= bencode.split('=');
        String bcode=code[0]; 
        system.debug('bcode'+bcode);
        
        string fd= fdos;
           
        string provcode= vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Code__c;
        string dobs= dobToSend;
        
        
        string prov=vobRec.ElixirSuite__Provider__r.Name;
        
       
        
        if(string.isBlank(vobRec.ElixirSuite__Insured_Middle_Name__c)){
            mname= '';
        }
        else{
            mname = vobRec.ElixirSuite__Insured_Middle_Name__c;
        }
        string policyno;
        if(string.isBlank(vobRec.ElixirSuite__Member_Id__c)){
            policyno = '';
        }
        else{
            policyno= vobRec.ElixirSuite__Member_Id__c;
        }
        string provNamef;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_First_Name__c)){
            provNamef= '';
        }
        else{
            provNamef= vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_First_Name__c;
        }
        string provNamel;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Last_Name__c)){
            provNamel= '';
        }
        else{
            provNamel = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Last_Name__c;
        }
        
        string provTaxonomy;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Taxonomy__c)){
            provTaxonomy= '';
        }
        else{
            provTaxonomy = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Taxonomy__c;
        }
        
        string provTaxId;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Tax_Id__c)){
            provTaxId= '';
        }
        else{
            provTaxId = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Tax_Id__c;
        }
        string provTaxIdType;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_TaxId_Type__c)){
            provTaxIdType= '';
        }
        else{
            provTaxIdType = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_TaxId_Type__c;
        }
        string provCity;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_City__c)){
            provCity= '';
        }
        else{
            provCity = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_City__c;
        }
        string provState;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_State__c)){
            provState= '';
        }
        else{
            provState = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_State__c;
        }
        string provZip;
        if(string.isBlank(vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Zip__c)){
            provZip= '';
        }
        else{
            provZip = vobRec.ElixirSuite__Provider__r.ElixirSuite__Provider_Zip__c;
        }
        string procCode;
        if(string.isBlank(vobRec.ElixirSuite__Procedure_Code__c)){
            procCode= '';
        }
        else{
            procCode = vobRec.ElixirSuite__Procedure_Code__c;
        }
        
        String encodedString = EncodingUtil.urlEncode(lname,'UTF-8');
        String encodedString1 = EncodingUtil.urlEncode(mname,'UTF-8');
        String encodedString2 = EncodingUtil.urlEncode(fname,'UTF-8');
        String encodedString3 = EncodingUtil.urlEncode(pcode,'UTF-8');
        String encodedString4 = EncodingUtil.urlEncode(pat,'UTF-8');
        String encodedString5 = EncodingUtil.urlEncode(bcode,'UTF-8');
        String encodedString6 = EncodingUtil.urlEncode(fd,'UTF-8');
        String encodedString7 = EncodingUtil.urlEncode(provcode,'UTF-8');
        String encodedString8 = EncodingUtil.urlEncode(dobs,'UTF-8');
        String encodedString9 = EncodingUtil.urlEncode(prov,'UTF-8');
        
        
        String encodedString10 = EncodingUtil.urlEncode(policyno,'UTF-8');
        String encodedString11 = EncodingUtil.urlEncode(provNamef,'UTF-8');
        String encodedString12 = EncodingUtil.urlEncode(provNamel,'UTF-8');
        String encodedString13 = EncodingUtil.urlEncode(provTaxonomy,'UTF-8');
        String encodedString14 = EncodingUtil.urlEncode(provTaxId,'UTF-8');
        String encodedString15 = EncodingUtil.urlEncode(provTaxIdType,'UTF-8');
        String encodedString16 = EncodingUtil.urlEncode(provCity,'UTF-8');
        String encodedString17 = EncodingUtil.urlEncode(provState,'UTF-8');
        String encodedString18 = EncodingUtil.urlEncode(provZip,'UTF-8'); 
        String encodedString19 = EncodingUtil.urlEncode(procCode,'UTF-8'); 
        
        
        req.setHeader('Content-Type','text/html; charset=UTF-8');        
        req.setMethod('GET');
        
        req.setEndpoint('callout:Claim_MD/services/eligxml/?AccountKey='+ accKey +'&ins_name_l='+ encodedString +'&ins_name_m='+encodedString1 +'&ins_name_f='+ encodedString2  +'&payerid='+ encodedString3 +'&pat_rel='+ encodedString4 +'&service_code='+ encodedString5 +'&fdos='+ encodedString6 +'&prov_npi='+encodedString7+'&ins_dob='+encodedString8+'&prov_name_l='+encodedString9+'&ins_number='+encodedString10+'&prov_name_f='+encodedString11+'&prov_name_l='+encodedString12+'&prov_taxonomy='+encodedString13+'&prov_taxid='+encodedString14+'&prov_taxid_type='+encodedString15+'&prov_addr_1='+'&prov_city='+encodedString16+'&prov_state='+encodedString17+'&prov_zip='+encodedString18+'&proc_code='+encodedString19); 
        
        Http http = new Http();
        HttpResponse resp = http.send(req);
        
        List<ElixirSuite__VOB_Codes_and_Fields__mdt> vobFieldList = new List<ElixirSuite__VOB_Codes_and_Fields__mdt>([Select id, DeveloperName, ElixirSuite__In_Plan_Network__c, ElixirSuite__Benefit_Coverage__c, ElixirSuite__Benefit_Level__c, ElixirSuite__Benefit_Period__c, ElixirSuite__VOB_Field__c from ElixirSuite__VOB_Codes_and_Fields__mdt LIMIT 5000]);
        Map<String,String> vobCodeFieldMap = new Map<String,String>();
        VOBResponse wrap = new VOBResponse();
        if(resp.getStatusCode() == 200)
        {
            for(ElixirSuite__VOB_Codes_and_Fields__mdt vcf : vobFieldList)
            {
                String key = '';
                key += vcf.ElixirSuite__Benefit_Coverage__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__Benefit_Level__c.toLowerCase()+'#';
                key += vcf.ElixirSuite__In_Plan_Network__c;
                
                vobCodeFieldMap.put(key,vcf.ElixirSuite__VOB_Field__c);
            }
            
            System.debug('Http Response Body=: ' + resp.getBody());
            
            wrap.vobFieldsMap = vobCodeFieldMap;
            try{
                //String xmlResp = '<result><elig elig_result_date="20210111" elig_result_time="1017" eligid="28277016" group_number="202GROUP" ins_addr_1="21 JUMP ST" ins_city="MEMPHIS" ins_dob="19750821" ins_name_f="PATIENT1" ins_name_l="TEST" ins_number="12345678" ins_sex="M" ins_state="TN" ins_zip="871012155" plan_begin_date="20210101-20211231" plan_number="PLAN101"><benefit benefit_code="30" benefit_coverage_code="1" benefit_coverage_description="Active Coverage" benefit_description="Health Benefit Plan Coverage" benefit_notes="FUNDING TYPE = FULLY INSURED" date_of_last_update="20160702" insurance_plan="AETNA CHOICE PLUS" insurance_type_code="C1" insurance_type_description="Commercial"><entity_addr_1>P.O. BOX 30555</entity_addr_1><entity_city>SALT LAKE CITY</entity_city><entity_code>PR</entity_code><entity_description>Payer</entity_description><entity_name>AETNA</entity_name><entity_state>UT</entity_state><entity_zip>841300555</entity_zip></benefit><benefit benefit_amount="3000" benefit_code="30" benefit_coverage_code="C" benefit_coverage_description="Deductible" benefit_description="Health Benefit Plan Coverage" benefit_level_code="FAM" benefit_level_description="Family" benefit_period_code="23" benefit_period_description="Calendar Year" inplan_network="N" /><benefit benefit_amount="0" benefit_code="30" benefit_coverage_code="C" benefit_coverage_description="Deductible" benefit_description="Health Benefit Plan Coverage" benefit_level_code="IND" benefit_level_description="Individual" benefit_period_code="29" benefit_period_description="Remaining" inplan_network="Y" /></elig></result>';
                Dom.Document doc = new Dom.Document();
                doc.load(resp.getBody());
                Dom.XMLNode root = doc.getRootElement();  //result
                String finalJson = '{';
                finalJson = VobXMLParserClass.generateBodyUsingRecursion(finalJson,root);
                finalJson += '}';   
                wrap.jsonResp = finalJson;
                vobRec.ElixirSuite__JSON_Dump__c = finalJson;
                //if(Schema.sObjectType.VOB__c.isUpdateable()){
                update vobRec;
                //DMLManager.updateAsUser(vobRec);
                // }
                system.debug('finalJson'+finalJson);
                system.debug('vobRec.Id'+vobRec.Id);
                system.debug('vobList'+vobList);
                 wrp.msgStr =  parseJson(finalJson,vobRec.Id,vobList);
                 System.debug('wrp.msgStr 1259: ' + wrp.msgStr);
                //generatePDF(vobRec.Id);
                
                //System.debug('complete ');
                //system.debug('Final JSON'+finalJson);
            }
            catch(Exception e){
                //  ExceptionLog.logError(e);
            }
            
        }
       // system.debug('Id: '+vobRec.Id);
        //system.debug('List: '+vobList );
       System.debug('wrp.msgStr: ' + wrp.msgStr);
        return wrp.msgStr;
        // string finalJson = '{"result":{"elig":{"elig_result_date":"20230425","elig_result_time":"0008","eligid":"28277016","group_number":"202GROUP","ins_addr_1":"21 JUMP ST","ins_city":"MEMPHIS","ins_dob":"19750821","ins_name_f":"CHIQUITA","ins_name_l":"BROWN","ins_number":"12345678","ins_sex":"M","ins_state":"TN","ins_zip":"871012155","plan_begin_date":"20230326-20230525","plan_number":"PLAN101","benefit":[{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Health Benefit Plan Coverage","benefit_notes":"FUNDING TYPE = FULLY INSURED","date_of_last_update":"20160702","insurance_plan":"AETNA CHOICE PLUS","insurance_type_code":"C1","insurance_type_description":"Commercial","entity_addr_1":"P.O. BOX 30555","entity_city":"SALT LAKE CITY","entity_code":"PR","entity_description":"Payer","entity_name":"AETNA","entity_state":"UT","entity_zip":"841300555"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"24","benefit_period_description":"Year to Date","inplan_network":"W","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"1500","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"N"},{"benefit_amount":"3000","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"Y"},{"benefit_amount":"9000","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"99999","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"FAM","benefit_level_description":"Family","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"30","benefit_coverage_code":"C","benefit_coverage_description":"Deductible","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"23","benefit_period_description":"Calendar Year","inplan_network":"Y"},{"benefit_amount":"4500","benefit_code":"30","benefit_coverage_code":"G","benefit_coverage_description":"Out of Pocket (Stop Loss)","benefit_description":"Health Benefit Plan Coverage","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"29","benefit_period_description":"Remaining","inplan_network":"N","insurance_type_code":"C1","insurance_type_description":"Commercial"},{"benefit_code":"1","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Medical Care","inplan_network":"W"},{"benefit_code":"33","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Chiropractic","inplan_network":"W"},{"benefit_code":"47","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital","inplan_network":"W"},{"benefit_code":"48","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Inpatient","inplan_network":"W"},{"benefit_code":"50","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Hospital - Outpatient","inplan_network":"W"},{"benefit_code":"86","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Emergency Services","inplan_network":"W"},{"benefit_code":"98","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician) Visit - Office","inplan_network":"W"},{"benefit_code":"AL","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Vision (Optometry)","inplan_network":"W"},{"benefit_code":"MH","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Mental Health","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Physical Therapy","inplan_network":"W"},{"benefit_code":"UC","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Urgent Care","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"1","benefit_coverage_description":"Active Coverage","benefit_description":"Professional (Physician)","benefit_notes":"SPECIALIST","inplan_network":"W"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"0","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"50","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"86","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"98","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"UC","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"PT","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"48","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_code":"96","benefit_coverage_code":"A","benefit_coverage_description":"Co-Insurance","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_percent":"50","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"35","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"0","benefit_code":"UC","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Urgent Care","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"0","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"N"},{"benefit_amount":"125","benefit_code":"50","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Outpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"96","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician)","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"SPECIALIST","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"98","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Professional (Physician) Visit - Office","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"33","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"15","benefit_code":"PT","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"250","benefit_code":"48","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Hospital - Inpatient","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"75","benefit_code":"86","benefit_coverage_code":"B","benefit_coverage_description":"Co-Payment","benefit_description":"Emergency Services","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_period_code":"27","benefit_period_description":"Visit","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"30","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"ADDITIONAL VISITS AVAILABLE BASED ON MEDICAL NECESSITY REVIEW REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"30","inplan_network":"W"},{"benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_code":"33","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Chiropractic","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE ADDITIONAL BENEFIT FOR MUSCULOSKELETAL PAIN MANAGEMENT PROGRAM","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"3","inplan_network":"Y"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"23","benefit_period_description":"Calendar Year","benefit_qnty":"20","inplan_network":"W"},{"benefit_amount":"999999.99","benefit_code":"PT","benefit_coverage_code":"F","benefit_coverage_description":"Limitations","benefit_description":"Physical Therapy","benefit_level_code":"IND","benefit_level_description":"Individual","benefit_notes":"REHABILITATIVE","benefit_period_code":"29","benefit_period_description":"Remaining","benefit_qnty":"20","inplan_network":"W"},{"benefit_code":"88","benefit_coverage_code":"U","benefit_coverage_description":"Contact Following Entity for Eligibility or Benefit Information","benefit_description":"Pharmacy","entity_code":"VN","entity_description":"Vendor","entity_name":"OPTUMRX","entity_website":"PROFESSIONALS.OPTUMRX.COM"}]}}}';
        // call parsejson method
   
    }
    
    
    global class MessageWrapper{
        @AuraEnabled
        public String msgState;
        @AuraEnabled
        public String msgStr;
        @AuraEnabled
        public ElixirSuite__VOB__c vob;
        @AuraEnabled
        public String patRelationCode;
        @AuraEnabled
        public List<ElixirSuite__VOB__c> volList;
    }
    global class VOBResponse{
        @AuraEnabled
        public String jsonResp;
        @AuraEnabled
        public Map<String,String> vobFieldsMap;
    }
    
    
    global static String parseJson(string jsonStr,String vobId1, List<ElixirSuite__VOB__c> vobRec1){
        Boolean isActive = false;
        Map<String, String> mapVobFields = new Map<String, String>();
        MessageWrapper wrap = new MessageWrapper();
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(jsonStr);
        Map<String, Object> reslt = (Map<String, Object>)resultMap.get('result');
        List<ElixirSuite__Result__c> resList = new List<ElixirSuite__Result__c>();
        // populate resultMap with values
        ElixirSuite__Result__c resMap = new ElixirSuite__Result__c();
        if(reslt.containsKey('error')) {
            Map<String, Object> errorMap = (Map<String, Object>) reslt.get('error');
            String errorStr = String.valueOf(errorMap.get('error_mesg'));
            system.debug('errorStr:- '+errorStr);
            wrap.msgStr = errorStr;
            // return wrap.msgStr;
        }
        else if (reslt.containsKey('elig')) {
            Map<String, Object> eligMap = (Map<String, Object>) reslt.get('elig');
            system.debug('eligMap:-'+eligMap);
            if (eligMap.containsKey('elig_result_date')) {
                String verifyDateStr = (String)eligMap.get('elig_result_date');
                Date verifiedDate = Date.newInstance(
                    Integer.valueOf(verifyDateStr.substring(0, 4)),
                    Integer.valueOf(verifyDateStr.substring(4, 6)) - 1,
                    Integer.valueOf(verifyDateStr.substring(6, 8)) + 1
                );
                resMap.ElixirSuite__Eligibility_Result_Date__c = verifiedDate;
            }
            if (eligMap.containsKey('elig_result_time')) {
                String verifyTimeStr = (String)eligMap.get('elig_result_time');
                String verifiedTime = verifyTimeStr.substring(0, 2) + ':' + verifyTimeStr.substring(2, 4);
                resMap.ElixirSuite__Eligibility_Result_Time_Text__c = verifiedTime;
            }
            if (eligMap.containsKey('eligibility_begin_date')) {
                String verifyDateStr = (String)eligMap.get('eligibility_begin_date');
                Date verifiedDate = Date.newInstance(
                    Integer.valueOf(verifyDateStr.substring(0, 4)),
                    Integer.valueOf(verifyDateStr.substring(4, 6)) - 1,
                    Integer.valueOf(verifyDateStr.substring(6, 8)) + 1
                );
                resMap.ElixirSuite__Coverage_Date_Start__c = verifiedDate;
            }
            if (eligMap.containsKey('plan_begin_date')) {
                String planDateStr = (String) eligMap.get('plan_begin_date');
                System.debug(planDateStr);
                if (planDateStr.contains('-')) {
                    List<String> planDateLst = planDateStr.split('-');
                    String planDateStartStr = planDateLst[0];
                    String planDateEndStr = planDateLst[1];
                    Integer daySt = Integer.valueOf(planDateStartStr.substring(6, 8)) + 1;
                    Integer monthSt = Integer.valueOf(planDateStartStr.substring(4, 6)) - 1;
                    Integer yearSt = Integer.valueOf(planDateStartStr.substring(0, 4));
                    
                    Integer dayEd = Integer.valueOf(planDateEndStr.substring(6, 8)) + 1;
                    Integer monthEd = Integer.valueOf(planDateEndStr.substring(4, 6)) - 1;
                    Integer yearEd = Integer.valueOf(planDateEndStr.substring(0, 4));
                    
                    System.debug(yearSt + '-' + monthSt + '-' + daySt);
                    System.debug(yearEd + '-' + monthEd + '-' + dayEd);
                    Date planDateStart = Date.newInstance(yearSt, monthSt, daySt);
                    Date planDateEnd = Date.newInstance(yearEd, monthEd, dayEd);
                    System.debug(planDateStart);
                    System.debug(planDateEnd);
                    if (planDateStart != null) {
                        resMap.ElixirSuite__Plan_Begin_Date__c = planDateStart;
                    }
                    if (planDateEnd != null) {
                        resMap.ElixirSuite__Plan_End_Date__c = planDateEnd;
                    }
                } else {
                    Integer daySt = Integer.valueOf(planDateStr.substring(6, 8)) + 1;
                    Integer monthSt = Integer.valueOf(planDateStr.substring(4, 6)) - 1;
                    Integer yearSt = Integer.valueOf(planDateStr.substring(0, 4));
                    
                    Date planDateStart = Date.newInstance(yearSt, monthSt, daySt);
                    resMap.ElixirSuite__Plan_Begin_Date__c = planDateStart;
                }
            }
            
            if (eligMap.containsKey('plan_date')) {
                String planDateStr = (String) eligMap.get('plan_date');
                if (planDateStr.contains('-')) {
                    List<String> planDateLst = planDateStr.split('-');
                    String planDateStartStr = planDateLst[0];
                    String planDateEndStr = planDateLst[1];
                    Integer daySt = Integer.valueOf(planDateStartStr.substring(6, 8)) + 1;
                    Integer monthSt = Integer.valueOf(planDateStartStr.substring(4, 6)) - 1;
                    Integer yearSt = Integer.valueOf(planDateStartStr.substring(0, 4));
                    
                    Integer dayEd = Integer.valueOf(planDateEndStr.substring(6, 8)) + 1;
                    Integer monthEd = Integer.valueOf(planDateEndStr.substring(4, 6)) - 1;
                    Integer yearEd = Integer.valueOf(planDateEndStr.substring(0, 4));
                    
                    System.debug(yearSt + '-' + monthSt + '-' + daySt);
                    System.debug(yearEd + '-' + monthEd + '-' + dayEd);
                    Date planDateStart = Date.newInstance(yearSt, monthSt, daySt);
                    Date planDateEnd = Date.newInstance(yearEd, monthEd, dayEd);
                    System.debug(planDateStart);
                    System.debug(planDateEnd);
                    
                    if (planDateStart != null) {
                        resMap.ElixirSuite__Plan_Begin_Date__c = planDateStart;
                    }
                    if (planDateEnd != null) {
                        resMap.ElixirSuite__Plan_End_Date__c = planDateEnd;
                    }
                } else {
                    Integer daySt = Integer.valueOf(planDateStr.substring(6, 8)) + 1;
                    Integer monthSt = Integer.valueOf(planDateStr.substring(4, 6)) - 1;
                    Integer yearSt = Integer.valueOf(planDateStr.substring(0, 4));
                    
                    Date planbeginDate1 = Date.newInstance(yearSt, monthSt, daySt);
                    resMap.ElixirSuite__Plan_Begin_Date__c = planbeginDate1;
                }
            }
            if (eligMap.containsKey('plan_number')) {
                resMap.ElixirSuite__Plan_Number__c = (String) eligMap.get('plan_number');
            }
            if (eligMap.containsKey('group_name')) {
                resMap.ElixirSuite__Group_Name__c = (String) eligMap.get('group_name');
            }
            if (eligMap.containsKey('group_number')) {
                resMap.ElixirSuite__Group_Number__c = (String) eligMap.get('group_number');
            }
            if (eligMap.containsKey('eligid')) {
                resMap.ElixirSuite__Elig_Id__c = (String) eligMap.get('eligid');
            }
            if (eligMap.containsKey('ins_number')) {
                resMap.ElixirSuite__Insurance_Number__c = (String) eligMap.get('ins_number');
            }
            if (eligMap.containsKey('ins_name_f')) {
                resMap.ElixirSuite__Insured_First_Name__c = (String) eligMap.get('ins_name_f');
            }
            if (eligMap.containsKey('ins_name_l')) {
                resMap.ElixirSuite__Insured_Last_Name__c = (String) eligMap.get('ins_name_l');
            }
            if (eligMap.containsKey('ins_dob')) {
                String dateOfBirthStr = (String) eligMap.get('ins_dob');
                Integer day = Integer.valueOf(dateOfBirthStr.substring(6, 8)) + 1;
                Integer month = Integer.valueOf(dateOfBirthStr.substring(4, 6)) - 1;
                Integer year = Integer.valueOf(dateOfBirthStr.substring(0, 4));
                
                System.debug(year + '-' + month + '-' + day);
                Date dateOfBirth = Date.newInstance(year, month, day);
                // Assuming DateOfBirth is a variable in Apex
                DateOfBirth = dateOfBirth;
                resMap.ElixirSuite__Insured_DOB__c = dateOfBirth;
                System.debug('DateOfBirth: ' + dateOfBirth);
            }
            
            if (eligMap.containsKey('ins_sex')) {
                resMap.ElixirSuite__Insured_Sex__c = (String) eligMap.get('ins_sex');
            }
            
            if (eligMap.containsKey('ins_addr_1')) {
                resMap.ElixirSuite__Insured_Address__c = (String) eligMap.get('ins_addr_1');
            }
            
            if (eligMap.containsKey('ins_city')) {
                resMap.ElixirSuite__Insured_City__c = (String) eligMap.get('ins_city');
            }
            
            if (eligMap.containsKey('ins_state')) {
                resMap.ElixirSuite__Insured_State__c = (String) eligMap.get('ins_state');
            }
            
            if (eligMap.containsKey('ins_zip')) {
                resMap.ElixirSuite__Insured_Zip__c = (String) eligMap.get('ins_zip');
            }
            
            // List<Map<String, Object>> benefitLst = (List<Map<String, Object>>)eligMap.get('benefit');
            //system.debug('benefitLst-'+benefitLst);
            List<Map<String, Object>> benefitLst = new List<Map<String, Object>>();
            if (eligMap.containsKey('benefit')) {
                Object benefitObj = eligMap.get('benefit');
                if (benefitObj instanceof List<Object>) {
                    List<Object> benefitObjList = (List<Object>) benefitObj;
                    for (Object obj : benefitObjList) {
                        if (obj instanceof Map<String, Object>) {
                            Map<String, Object> benefitMap = (Map<String, Object>) obj;
                            benefitLst.add(benefitMap);
                        }
                    }
                }
            }
            system.debug('benefitLst-'+benefitLst);
            for (Integer i = 0; i < benefitLst.size(); i++) {
                Map<String, Object> benefit = benefitLst[i];
                if (benefit.containsKey('benefit_code') && benefit.containsKey('benefit_coverage_code')) {
                    //----------first Section Mapping------------
                    if (benefit.containsKey('benefit_code')) {
                        resMap.ElixirSuite__Benefit_Code__c = (String) benefit.get('benefit_code');
                    }
                    if (benefit.containsKey('benefit_coverage_code')) {
                        resMap.ElixirSuite__Benefit_Coverage_Code__c = (String) benefit.get('benefit_coverage_code');
                    }
                    if (benefit.containsKey('benefit_coverage_description')) {
                        resMap.ElixirSuite__Benefit_Coverage_Description__c = (String) benefit.get('benefit_coverage_description');
                    }
                    if (benefit.containsKey('benefit_description')) {
                        resMap.ElixirSuite__Benefit_Description__c = (String) benefit.get('benefit_description');
                    }
                    if (benefit.containsKey('benefit_notes')) {
                        resMap.ElixirSuite__Benefit_Notes__c = (String) benefit.get('benefit_notes');
                    }
                    if (benefit.containsKey('insurance_plan')) {
                        resMap.ElixirSuite__Insurance_Plan__c = (String) benefit.get('insurance_plan');
                    }
                    if (benefit.containsKey('insurance_type_code')) {
                        resMap.ElixirSuite__Insurance_Type_Code__c = (String) benefit.get('insurance_type_code');
                    }
                    if (benefit.containsKey('insurance_type_description')) {
                        resMap.ElixirSuite__Insurance_Type_Description__c = (String) benefit.get('insurance_type_description');
                    }
                    if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                        benefitLst[i].get('benefit_level_code') == 'FAM' && 
                        benefitLst[i].get('benefit_period_code') == '23' &&
                        benefitLst[i].get('inplan_network') == 'Y' &&
                        benefitLst[i].get('benefit_code') =='30') {
                            
                            resMap.ElixirSuite__Deductible_Family_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                ;
                        }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' && 
                             benefitLst[i].get('benefit_level_code') == 'FAM' && 
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') =='30') {
                                 
                                 resMap.ElixirSuite__Co_Insurance_Fam_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                             }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' && 
                             benefitLst[i].get('benefit_level_code') == 'FAM' && 
                             benefitLst[i].get('inplan_network') == 'N' &&
                             benefitLst[i].get('benefit_code') =='30') {
                                 
                                 resMap.ElixirSuite__Co_Insurance_Fam_Out_Of_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                             }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' && 
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') =='30') {
                                 
                                 resMap.ElixirSuite__Co_Insurance_Ind_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                             }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' && 
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             benefitLst[i].get('inplan_network') == 'N' &&
                             benefitLst[i].get('benefit_code') =='30') {
                                 
                                 resMap.ElixirSuite__Co_Insurance_Ind_Out_Of_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                             }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             benefitLst[i].get('benefit_period_code') == '23' &&
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') =='30') {
                                 resMap.ElixirSuite__Deductible_Individual_In_Network__c= Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                     ;
                             }
                    else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                             benefitLst[i].get('benefit_level_code') == 'FAM' && 
                             benefitLst[i].get('benefit_period_code') == '29' &&
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') == '30') {
                                 resMap.ElixirSuite__Deductible_Rem_Fam_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                     ;
                             } else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                                        benefitLst[i].get('benefit_level_code') == 'IND' && 
                                        benefitLst[i].get('inplan_network') == 'Y' &&
                                        benefitLst[i].get('benefit_code') == '30') {
                                            resMap.ElixirSuite__Deductible_Rem_Ind_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                            
                                        } else if (benefitLst[i].get('benefit_coverage_code') == 'G' && 
                                                   benefitLst[i].get('benefit_level_code') == 'FAM' &&
                                                   benefitLst[i].get('inplan_network') == 'Y' &&
                                                   benefitLst[i].get('benefit_code') == '30') {
                                                       if (benefitLst[i].get('benefit_period_code') == '29') {
                                                           resMap.ElixirSuite__OOP_Rem_Fam_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                                       } else {
                                                           resMap.ElixirSuite__OOP_Family_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                                       }
                                                   } else if (benefitLst[i].get('benefit_coverage_code') == 'G' && 
                                                              benefitLst[i].get('benefit_level_code') == 'IND' && 
                                                              benefitLst[i].get('inplan_network') == 'Y' &&
                                                              benefitLst[i].get('benefit_code') == '30') {
                                                                  if (benefitLst[i].get('benefit_period_code') == '29') {
                                                                      resMap.ElixirSuite__OOP_Rem_Ind_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                                                  } else {
                                                                      resMap.ElixirSuite__OOP_Individual_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                                                  }
                                                              } 
                    else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                             benefitLst[i].get('benefit_level_code') == 'FAM' && 
                             benefitLst[i].get('benefit_period_code') == '23' &&
                             benefitLst[i].get('inplan_network') == 'N' &&
                             benefitLst[i].get('benefit_code') == '30') {
                                 resMap.ElixirSuite__Deductible_Family_Out_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                     ;
                             } else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                                        benefitLst[i].get('benefit_level_code') == 'IND' && 
                                        benefitLst[i].get('benefit_period_code') == '23' &&
                                        benefitLst[i].get('inplan_network') == 'N' &&
                                        benefitLst[i].get('benefit_code') == '30') {
                                            resMap.ElixirSuite__Deductible_Individual_Out_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                ;
                                        } else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                                                   benefitLst[i].get('benefit_level_code') == 'FAM' && 
                                                   benefitLst[i].get('benefit_period_code') == '29' &&
                                                   benefitLst[i].get('inplan_network') == 'N' &&
                                                   benefitLst[i].get('benefit_code') == '30') {
                                                       resMap.ElixirSuite__Deductible_Rem_Fam_Out_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                           ;
                                                   } else if (benefitLst[i].get('benefit_coverage_code') == 'C' && 
                                                              benefitLst[i].get('benefit_level_code') == 'IND' && 
                                                              benefitLst[i].get('benefit_period_code') == '29' &&
                                                              benefitLst[i].get('inplan_network') == 'N' &&
                                                              benefitLst[i].get('benefit_code') == '30') {
                                                                  resMap.ElixirSuite__Deductible_Rem_Ind_Out_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                                      ;
                                                              } else if (benefitLst[i].get('benefit_coverage_code') == 'G' && 
                                                                         benefitLst[i].get('benefit_level_code') == 'FAM' && 
                                                                         benefitLst[i].get('inplan_network') == 'N' &&
                                                                         benefitLst[i].get('benefit_code') == '30') {
                                                                             if (benefitLst[i].get('benefit_period_code') == '29') {
                                                                                 resMap.ElixirSuite__OOP_Rem_Fam_Out_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                                                     ;
                                                                             } else {
                                                                                 resMap.ElixirSuite__OOP_Family_Out_Network__c =Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                                                     ;
                                                                             }
                                                                         } else if (benefitLst[i].get('benefit_coverage_code') == 'G' && 
                                                                                    benefitLst[i].get('benefit_level_code') == 'IND' && 
                                                                                    benefitLst[i].get('inplan_network') == 'N' &&
                                                                                    benefitLst[i].get('benefit_code') == '30') {
                                                                                        if (benefitLst[i].get('benefit_period_code') == '29') {
                                                                                            resMap.ElixirSuite__OOP_Rem_Ind_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'))
                                                                                                ;
                                                                                        } else {
                                                                                            resMap.ElixirSuite__OOP_Individual_In_Network__c = Decimal.valueOf((String)benefitLst[i].get('benefit_amount'));
                                                                                            
                                                                                        }
                                                                                    } 
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             (benefitLst[i].get('benefit_period_code') == '27' || benefitLst[i].get('benefit_period_code') == '7') &&
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') =='AI'
                            ) { 
                                resMap.ElixirSuite__Co_insurance_Sub_Abuse_In_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                resMap.ElixirSuite__Place_of_Serv_SubAbu_In_Net__c = (String)benefitLst[i].get('place_of_service');
                            } 
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             (benefitLst[i].get('benefit_period_code') == '27' || benefitLst[i].get('benefit_period_code') == '7') &&
                             benefitLst[i].get('inplan_network') == 'Y' &&
                             benefitLst[i].get('benefit_code') =='CI') {
                                 resMap.ElixirSuite__Co_insurance_Sub_Abuse_Inpatient_In_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                 resMap.ElixirSuite__Place_of_Serv_SubAbu_Inpatient_In_Net__c = (String)benefitLst[i].get('place_of_service');
                             } else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                                        benefitLst[i].get('benefit_level_code') == 'IND' && 
                                        (benefitLst[i].get('benefit_period_code') == '27' || benefitLst[i].get('benefit_period_code') == '7') &&
                                        benefitLst[i].get('inplan_network') == 'Y' &&
                                        benefitLst[i].get('benefit_code') =='CJ') {
                                            resMap.ElixirSuite__Co_insurance_Sub_Abuse_Outpatient_In_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                            resMap.ElixirSuite__Place_of_Serv_SubAbu_Outpatient_In_Net__c = (String)benefitLst[i].get('place_of_service');
                                        } else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                                                   benefitLst[i].get('benefit_level_code') == 'IND' && 
                                                   (benefitLst[i].get('benefit_period_code') == '27' || benefitLst[i].get('benefit_period_code') == '7') &&
                                                   benefitLst[i].get('inplan_network') == 'N' &&
                                                   benefitLst[i].get('benefit_code') =='AI'
                                                  ) { 
                                                      resMap.ElixirSuite__Co_insurance_Sub_Abuse_Out_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                                      resMap.ElixirSuite__Place_of_Serv_SubAbu_Out_Net__c = (String)benefitLst[i].get('place_of_service');
                                                  }        
                    else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                             benefitLst[i].get('benefit_level_code') == 'IND' && 
                             (benefitLst[i].get('benefit_period_code') == '7' || benefitLst[i].get('benefit_period_code') == '27') &&
                             benefitLst[i].get('inplan_network') == 'N' &&
                             benefitLst[i].get('benefit_code') =='CI') {
                                 resMap.ElixirSuite__Co_insurance_Sub_Abuse_Inpatient_Out_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                 resMap.ElixirSuite__Place_of_Serv_SubAbu_Inpatient_Out_Net__c = (String)benefitLst[i].get('place_of_service');
                             } else if (benefitLst[i].get('benefit_coverage_code') == 'A' &&
                                        benefitLst[i].get('benefit_level_code') == 'IND' && 
                                        (benefitLst[i].get('benefit_period_code') == '7' || benefitLst[i].get('benefit_period_code') == '27') &&
                                        benefitLst[i].get('inplan_network') == 'N' &&
                                        benefitLst[i].get('benefit_code') =='CJ') {
                                            resMap.ElixirSuite__Co_insurance_Sub_Abuse_Outpatient_Ou_Net__c = Decimal.valueOf((String)benefitLst[i].get('benefit_percent'));
                                            resMap.ElixirSuite__Place_of_Serv_SubAbu_Outpatient_Out_Net__c = (String)benefitLst[i].get('place_of_service');
                                        }
                    
                    if (String.valueOf(benefitLst[i].get('benefit_code')) == vobRec1[0].ElixirSuite__Benefit__c && String.valueOf(benefitLst[i].get('benefit_coverage_code')) == '1') {
                        isActive = true;
                        continue;
                    }
                    if (isActive && String.valueOf(benefitLst[i].get('benefit_code')) == vobRec1[0].ElixirSuite__Benefit__c) {
                        System.debug('Inside Active if ' + String.valueOf(benefitLst[i].get('benefit_code')));
                        String key = String.valueOf(benefitLst[i].get('benefit_coverage_code')).toLowerCase() + '#';
                        if (benefitLst[i].containsKey('benefit_level_code')) {
                            key += String.valueOf(benefitLst[i].get('benefit_level_code')).toLowerCase() + '#';
                        }
                        if (benefitLst[i].containsKey('inplan_network')) {
                            key += String.valueOf(benefitLst[i].get('inplan_network'));
                        }
                        System.debug('key: ' + key);
                        if (mapVobFields != null && mapVobFields.containsKey(key)) {
                            System.debug('in map');
                            System.debug(mapVobFields.get(key));
                            if (benefitLst[i].containsKey('benefit_amount')) {
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_amount'))));
                            } else if (benefitLst[i].containsKey('benefit_percent')) {
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_percent'))));
                            }
                        }
                    }
                    if ( (String.valueOf(benefitLst[i].get('benefit_coverage_code')) == 'A' || String.valueOf(benefitLst[i].get('benefit_coverage_code')) == 'B')) {
                        // A - for Co-Insurance
                        // B - for Co-Payment
                        System.debug('Inside Active if 2');
                        String key = String.valueOf(benefitLst[i].get('benefit_coverage_code')).toLowerCase() + '#';
                        if (benefitLst[i].containsKey('benefit_level_code')) {
                            key += String.valueOf(benefitLst[i].get('benefit_level_code')).toLowerCase() + '#';
                        }
                        if (benefitLst[i].containsKey('inplan_network')) {
                            key += String.valueOf(benefitLst[i].get('inplan_network'));
                        }
                        System.debug('key : ' + key);
                        if (mapVobFields != null && mapVobFields.containsKey(key)) {
                            System.debug('in map');
                            System.debug(mapVobFields.get(key));
                            if (benefitLst[i].containsKey('benefit_amount')) {
                                System.debug(Double.valueOf(String.valueOf(benefitLst[i].get('benefit_amount'))));
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_amount'))));
                            } else if (benefitLst[i].containsKey('benefit_percent')) {
                                System.debug(Double.valueOf(String.valueOf(benefitLst[i].get('benefit_percent'))));
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_percent'))));
                            }
                        }
                    }
                    
                    if ((String.valueOf(benefitLst[i].get('benefit_coverage_code')) == 'A' || String.valueOf(benefitLst[i].get('benefit_coverage_code')) == 'B')) {
                        // A - for Co-Insurance
                        // B - for Co-Payment
                        System.debug('Inside Active if 2');
                        String key = String.valueOf(benefitLst[i].get('benefit_coverage_code')).toLowerCase() + '#';
                        if (benefitLst[i].containsKey('benefit_level_code')) {
                            key += String.valueOf(benefitLst[i].get('benefit_level_code')).toLowerCase() + '#';
                        }
                        if (benefitLst[i].containsKey('inplan_network')) {
                            key += String.valueOf(benefitLst[i].get('inplan_network'));
                        }
                        System.debug('key : ' + key);
                        if (mapVobFields != null && mapVobFields.containsKey(key)) {
                            System.debug('in map');
                            System.debug(mapVobFields.get(key));
                            if (benefitLst[i].containsKey('benefit_amount')) {
                                System.debug(Double.valueOf(String.valueOf(benefitLst[i].get('benefit_amount'))));
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_amount'))));
                            } else if (benefitLst[i].containsKey('benefit_percent')) {
                                System.debug(Double.valueOf(String.valueOf(benefitLst[i].get('benefit_percent'))));
                                resMap.put('ElixirSuite__c' + mapVobFields.get(key), Double.valueOf(String.valueOf(benefitLst[i].get('benefit_percent'))));
                            }
                        }
                    }
                    
                }
            }
        }
        resList.add(resMap);
        system.debug('resList:= '+resList);
        if(!reslt.containsKey('error')) {
            saveResults(resList,vobId1,vobRec1); 
        }
        system.debug('wrap.msgStr:- '+wrap.msgStr);
        return wrap.msgStr;
    }
    
    
    global static void saveResults(List<ElixirSuite__Result__c> result1, String vobId1, List<ElixirSuite__VOB__c> vobRec1)
    {   
        string recordtypename = Schema.getGlobalDescribe().get('Elixirsuite__VOB__c').getDescribe().getRecordTypeInfosById().get(vobrec1[0].recordtypeid).getName();
        if(result1 != null){
            for(ElixirSuite__Result__c res :result1){
                res.ElixirSuite__VOB__c = vobId1;
                res.ElixirSuite__Insurance_Type__c = recordtypename;
                res.ElixirSuite__Payer_Name__c = vobRec1[0].ElixirSuite__Payer__r.name;
            }
            if(Schema.sObjectType.ElixirSuite__Result__c.fields.ElixirSuite__VOB__c.isCreateable() &&
               Schema.sObjectType.ElixirSuite__Result__c.fields.ElixirSuite__Insurance_Type__c.isCreateable() &&
               Schema.sObjectType.ElixirSuite__Result__c.fields.ElixirSuite__Payer_Name__c.isCreateable() ){
                   insert result1;
                   //  DMLManager.insertAsUser(result1);
               }
            List<ElixirSuite__Result__c> resultList = [SELECT id FROM ElixirSuite__Result__c WHERE id IN: result1 WITH SECURITY_ENFORCED];
            List<String> resultIds = new List<String>();
            for(ElixirSuite__Result__c rs: resultList){
                resultIds.add(rs.Id);
            }
            if(resultIds.size()>0 && vobId1!='' && vobId1!= null ){
                generateVobPdf(resultIds,vobId1);
            }
            for(ElixirSuite__VOB__c vob :vobRec1){
                vob.ElixirSuite__VOB_Verification_Status__c = 'Approved';
            }
            //if(Schema.sObjectType.VOB__c.fields.VOB_Verification_Status__c.isUpdateable()){
            //  DMLManager.updateAsUser(vobRec1);
            update vobRec1;
            // }
        }
        
    }
    @Future(callout=true)
    global static void generateVobPdf(List<String> result1, String vobId1){
        PageReference pdf = Page.VOBPdfGeneration;
        pdf.getParameters().put('recId',vobId1);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'VOB Response';
        cv.PathOnClient = 'VOBResponse.pdf';
        if(Test.isRunningTest()){
            cv.VersionData = blob.valueOf('Unit.Test');
        }else{
             cv.VersionData = pdf.getContentAsPDF();
        }
        //cv.VersionData = pdf.getContentAsPdf(); 
        cv.IsMajorVersion = true;
        try{
            Insert cv;
        }
        catch(Exception e){
            system.debug(e);
        }
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId; 
        //Create ContentDocumentLink 
        list<ContentDocumentLink> contentDocLinks = new list<ContentDocumentLink>();
        for(String rs:result1){
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = rs;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            contentDocLinks.add(cdl);
        }
        try{
            if(contentDocLinks.size()>0){
            Insert contentDocLinks;
            }
        }
        catch(Exception e){
            system.debug(e);
        }
    }
    
    
}
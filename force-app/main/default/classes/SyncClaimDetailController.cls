public with sharing class SyncClaimDetailController {
    
     @AuraEnabled  
    public static void updateClaim( String recId ) {
        
        List<ElixirSuite__Claim__c> acclst = [select Id ,ElixirSuite__Account__r.Name ,ElixirSuite__Insured_s_Name__c, ElixirSuite__Account__r.Id,ElixirSuite__VOB_lookup__c,ElixirSuite__Payor__c,ElixirSuite__Visits__c from ElixirSuite__Claim__c where Id =: recId WITH SECURITY_ENFORCED];
        String patientId;
        String vobId;
        String payorId;
        String careEpisodeId;
        if(!acclst.isEmpty() && acclst[0].ElixirSuite__Account__c != null){
            patientId = acclst[0].ElixirSuite__Account__c;
        }
        if(!acclst.isEmpty() && acclst[0].ElixirSuite__VOB_lookup__c != null){
            vobId = acclst[0].ElixirSuite__VOB_lookup__c;
        }
        if(!acclst.isEmpty() && acclst[0].ElixirSuite__Payor__c != null){
            payorId = acclst[0].ElixirSuite__Payor__c;
        }
        if(!acclst.isEmpty() && acclst[0].ElixirSuite__Visits__c != null){
            careEpisodeId = acclst[0].ElixirSuite__Visits__c;
        }
        //Account Detail
        Schema.DescribeSObjectResult res1 = Account.sObjectType.getDescribe();
        List<String> apiNames1 =  new List<String>(res1.fields.getMap().keySet());
        String query1 = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNames1,',')) +' FROM Account ';
        query1+= 'WHERE Id = :patientId ';
        List<Account> alst = (List<Account>)Database.query(query1);  
        Boolean territory = Account.getSobjectType().getDescribe().fields.getMap().keySet().contains('billingcountrycode');
        
        //Insurance Detail
        Schema.DescribeSObjectResult res2 = ElixirSuite__VOB__c.sObjectType.getDescribe();
        List<String> apiNames2 =  new List<String>(res2.fields.getMap().keySet());
        String query2 = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNames2,',')) +' FROM ElixirSuite__VOB__c ';
        query2+= 'WHERE Id = :vobId ';
        List<ElixirSuite__VOB__c> voblst = (List<ElixirSuite__VOB__c>)Database.query(query2);
        
         Map<String, String> patientSex = new Map<String, String> {
            'female' => 'F',
             'male' => 'M',
             'f' => 'F',
             'm' => 'M'};
       
        
        List<ElixirSuite__Payor__c> payorlst = [Select id,Name,ElixirSuite__Payer_Code__c from ElixirSuite__Payor__c where Id =:payorId AND ElixirSuite__Payer_Code__c !=null WITH SECURITY_ENFORCED];
        
        
        // map to get practitioner contact details
         Map<id,ElixirSuite__Visits__c> visitAndRendPractiotioner = new Map<id,ElixirSuite__Visits__c>([SELECT id , name,ElixirSuite__Care_Episode_Location__c,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Code__c,ElixirSuite__Care_Episode_Location__r.Name,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Address__c,
                                                                                                       ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_City__c,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_State__c,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Zip__c,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Tax_Id__c,ElixirSuite__Care_Episode_Location__r.ElixirSuite__Address_2__c,
                                                                                                       ElixirSuite__Billing_Provider__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Code__c,ElixirSuite__Billing_Provider__r.Name,ElixirSuite__Billing_Provider__r.ElixirSuite__Address__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Phone__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Tax_Id_Type__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Address_2__c,
                                                                                                       ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_City__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_State__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Zip__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Tax_Id__c,ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Taxonomy__c,
                                                                                                       ElixirSuite__Rendering_Provider__r.Name,ElixirSuite__Rendering_Provider__r.FirstName,ElixirSuite__Rendering_Provider__r.LastName,ElixirSuite__Rendering_Provider__r.ElixirSuite__Taxonomy__c, ElixirSuite__Rendering_Provider__r.ElixirSuite__Practitioner_NPI__c, ElixirSuite__Rendering_Provider__r.ElixirSuite__ID_Number__c,
                                                                                                       ElixirSuite__Rendering_Provider__r.MailingStreet, ElixirSuite__Rendering_Provider__r.MailingCity, ElixirSuite__Rendering_Provider__r.MailingState, ElixirSuite__Rendering_Provider__r.MailingPostalCode, ElixirSuite__Rendering_Provider__r.MailingCountry 
                                                                                                       FROM ElixirSuite__Visits__c where id =: careEpisodeId WITH SECURITY_ENFORCED]);
                
        Map<String, String> stateMap = new Map<String, String> {
                'Alabama' => 'AL', 'AL' => 'AL',
                    'Alaska' => 'AK','AK' => 'AK',
                    'Arizona' => 'AZ', 'AZ' => 'AZ',
                    'Arkansas' => 'AR', 'AR' => 'AR',
                    'California' => 'CA', 'CA' => 'CA',
                    'Colorado' => 'CO', 'CO' => 'CO',
                    'Connecticut' => 'CT', 'CT' => 'CT',
                    'District Of Columbia' => 'DC', 'DC' => 'DC',
                    'Florida' => 'FL', 'FL' => 'FL',
                    'Georgia' => 'GA', 'GA' => 'GA',
                    'Hawaii' => 'HI', 'HI' => 'HI',
                    'Idaho' => 'ID', 'ID' => 'ID',
                    'Illinois' => 'IL', 'IL' => 'IL',
                    'Indiana' => 'IN', 'IN' => 'IN',
                    'Iowa' => 'IA', 'IA' => 'IA',
                    'Kansas' => 'KS', 'KS' => 'KS',
                    'Maine' => 'ME', 'ME' => 'ME',
                    'Maryland' => 'MD','MD' => 'MD',
                    'Massachusetts' => 'MA', 'MA' => 'MA',
                    'Michigan' => 'MA', 'MA' => 'MA',
                    'Minnesota' => 'MN', 'MN' => 'MN',
                    'Mississippi' => 'MS', 'MS' => 'MS',
                    'Missouri' => 'MA', 'MA' => 'MA',
                    'Montana' => 'MO', 'MO' => 'MO',
                    'Nebraska' => 'NE', 'NE' => 'NE',
                    'Nevada' => 'MN','MN' => 'MN',
                    'New Jersey' => 'NJ','NJ' => 'NJ',
                    'New Hampshire' => 'NH', 'NH' => 'NH',
                    'New Mexico' => 'MA', 'MA' => 'MA',
                    'New York' => 'NM', 'NM' => 'NM',
                    'North Carolina' => 'NC', 'NC' => 'NC',
                    'Dakota' => 'ND', 'ND' => 'ND',
                    'Ohio' => 'OH', 'OH' => 'OH',
                    'Oklahoma' => 'OK','OK' => 'OK',
                    'Oregon' => 'OR','OR' => 'OR',
                    'Pennsylvania' => 'PA', 'PA' => 'PA',
                    'Rhode Island' => 'RI', 'RI' => 'RI',
                    'South Carolina' => 'SC', 'SC' => 'SC',
                    'South Dakota' => 'SD', 'SD' => 'SD',
                    'Tennessee' => 'TN', 'TN' => 'TN',
                    'Texas' => 'TX','TX' => 'TX',
                    'Utah' => 'UT', 'UT' => 'UT',
                    'Vermont' => 'VT', 'VT' => 'VT',
                    'Virginia' => 'VA','VA' => 'VA',
                    'Washington' => 'WA','WA' => 'WA',
                    'West Virginia' => 'WV','WV' => 'WV',
                    'Wisconsin' => 'WI','WI' => 'WI',
                    'Wyoming' => 'WY','WY' => 'WY'
                    
                    };
        
        
        ElixirSuite__Claim__c claim = new ElixirSuite__Claim__c( Id = recId);
        if(alst !=null && alst.size() >0 ){
            Account ac = alst[0];
            claim.ElixirSuite__Patient_Name__c = alst[0].Name;
            claim.ElixirSuite__Patient_Account_Number__c = alst[0].AccountNumber;
            claim.ElixirSuite__Patient_DOB__c =alst[0].ElixirSuite__DOB__c;
            claim.ElixirSuite__Patient_s_Address__c= alst[0].BillingStreet;
            if(alst[0].ElixirSuite__Gender__c != null && patientSex.containsKey((alst[0].ElixirSuite__Gender__c).toLowerCase())){
                claim.ElixirSuite__Patient_Sex__c = patientSex.get((alst[0].ElixirSuite__Gender__c).toLowerCase());
            }else {
                claim.ElixirSuite__Patient_Sex__c = 'U';
            }
            if(territory){
                claim.ElixirSuite__Patient_Country_Code__c = String.valueOf(ac.get('BillingCountryCode'));  
            }else{
                claim.ElixirSuite__Patient_Country_Code__c = alst[0].BillingCountry;
            }
            claim.ElixirSuite__Patient_s_City__c= alst[0].BillingCity;
            claim.ElixirSuite__Patient_Zip_Code__c= alst[0].BillingPostalCode;
            claim.ElixirSuite__Patient_s_Phone__c= alst[0].Phone;
            String PatientState = alst[0].BillingState;
            if(PatientState != null && !String.isBlank(PatientState) ){
            patientState = patientState.toUppercase();
            }
            if(stateMap.containsKey(patientState)){
                claim.ElixirSuite__Patient_s_State__c = stateMap.get(patientState);
            }else{
                claim.ElixirSuite__Patient_s_State__c = alst[0].BillingState;
            } 
        }
        if(voblst !=null && voblst.size() >0 ){
            
            if(voblst[0].ElixirSuite__Gender__c != null && patientSex.containsKey((voblst[0].ElixirSuite__Gender__c).toLowerCase())){
                claim.ElixirSuite__Insured_Sex__c = patientSex.get((voblst[0].ElixirSuite__Gender__c).toLowerCase());
            }else {
                claim.ElixirSuite__Insured_Sex__c = 'U';
            }
            //claim.ElixirSuite__Federal_Tax_Id_Number__c = voblst[0].ElixirSuite__Federal_Tax_ID_Number__c;
            claim.ElixirSuite__Insured_s_ID_Number__c = voblst[0].ElixirSuite__Member_Id__c;
            claim.ElixirSuite__Insured_Address__c = voblst[0].ElixirSuite__Insured_Address__c;
            claim.ElixirSuite__Insured_City__c = voblst[0].ElixirSuite__Insured_City__c;
            claim.ElixirSuite__Insurance_Type__c = voblst[0].ElixirSuite__Insurance_Type__c;
            claim.ElixirSuite__Medicare_Type_Code__c = voblst[0].ElixirSuite__Medicare_Type_Code__c;
            String insuredState = voblst[0].ElixirSuite__Insured_State__c;
            if(insuredState != null && !String.isBlank(insuredState) ){
            insuredState = insuredState.toUppercase();
            }
            if(stateMap.containsKey(insuredState)){
                claim.ElixirSuite__Insured_State__c = stateMap.get(insuredState);
            }else{
                claim.ElixirSuite__Insured_State__c =  voblst[0].ElixirSuite__Insured_State__c;   
            }
            claim.ElixirSuite__Insured_Zip_Code__c = voblst[0].ElixirSuite__Insured_Zipcode__c;
            claim.ElixirSuite__Insured_Country_Code__c = voblst[0].ElixirSuite__Insured_Country__c;
            claim.ElixirSuite__Insured_Telephone__c = voblst[0].ElixirSuite__InsPhone__c;
            claim.ElixirSuite__Other_Insured_s_Name__c = voblst[0].ElixirSuite__Other_Insured_s_Name__c;
            claim.ElixirSuite__Insured_DOB__c = voblst[0].ElixirSuite__Date_Of_Birth__c;
            claim.ElixirSuite__Insured_Policy__c = voblst[0].ElixirSuite__Insured_Policy_Group_FECA_Number__c;
            claim.ElixirSuite__Patient_Relationship_to_Insured__c = voblst[0].ElixirSuite__Patient_Relationship_With_Insured__c;
            claim.ElixirSuite__Accept_Assignment__c = voblst[0].ElixirSuite__Accept_Asignment__c;
            claim.ElixirSuite__Auto_Accident_Related__c = voblst[0].ElixirSuite__Auto_Accident__c;
            claim.ElixirSuite__Employment_Related__c = voblst[0].ElixirSuite__Employment__c;
            
            String insuredName;
            if(voblst[0].ElixirSuite__Insured_First_Name__c != null && voblst[0].ElixirSuite__Insured_First_Name__c != ''){
                insuredName = voblst[0].ElixirSuite__Insured_First_Name__c;
            }
            if(voblst[0].ElixirSuite__Insured_Middle_Name__c != null && voblst[0].ElixirSuite__Insured_Middle_Name__c != ''){
                insuredName = insuredName + ' ' + voblst[0].ElixirSuite__Insured_Middle_Name__c;
            }
            if(voblst[0].ElixirSuite__Insured_Last_Name__c != null && voblst[0].ElixirSuite__Insured_Last_Name__c != ''){
                insuredName = insuredName + ' ' + voblst[0].ElixirSuite__Insured_Last_Name__c;
            }
            
            claim.ElixirSuite__Insured_s_Name__c = insuredName;
            claim.ElixirSuite__Insured_First_name__c=voblst[0].ElixirSuite__Insured_First_Name__c;
            claim.ElixirSuite__Payor__c=voblst[0].ElixirSuite__Payer__c;
            // added by jami for 11362
            if (careEpisodeId != null && visitAndRendPractiotioner.containsKey(careEpisodeId)) {
                ElixirSuite__Visits__c renderingProvider = visitAndRendPractiotioner.get(careEpisodeId);
                if (renderingProvider != null) {
                    claim.ElixirSuite__Rendering_Provider_First_Name__c = renderingProvider.ElixirSuite__Rendering_Provider__r.FirstName;
                    claim.ElixirSuite__Rendering_Provider_Last_Name__c = renderingProvider.ElixirSuite__Rendering_Provider__r.LastName;
                    claim.ElixirSuite__Rendering_Provider_Taxonomy__c = renderingProvider.ElixirSuite__Rendering_Provider__r.ElixirSuite__Taxonomy__c;
                    claim.ElixirSuite__Rendering_Provider_NPI__c = renderingProvider.ElixirSuite__Rendering_Provider__r.ElixirSuite__Practitioner_NPI__c;
                    claim.ElixirSuite__Rendering_Provider_Tax_Id__c = renderingProvider.ElixirSuite__Rendering_Provider__r.ElixirSuite__ID_Number__c;
                    String street = '';
                    String city = '';
                    String state = '';
                    String postalCode = '';
                    String country = '';
                    if(renderingProvider.ElixirSuite__Rendering_Provider__r.MailingStreet != null){
                        street = renderingProvider.ElixirSuite__Rendering_Provider__r.MailingStreet;
                    }
                    if(renderingProvider.ElixirSuite__Rendering_Provider__r.MailingCity != null){
                        city = renderingProvider.ElixirSuite__Rendering_Provider__r.MailingCity;
                    }
                    if(renderingProvider.ElixirSuite__Rendering_Provider__r.MailingState != null){
                        state = renderingProvider.ElixirSuite__Rendering_Provider__r.MailingState;
                    }
                    if(renderingProvider.ElixirSuite__Rendering_Provider__r.MailingPostalCode != null){
                        postalCode = renderingProvider.ElixirSuite__Rendering_Provider__r.MailingPostalCode;
                    }
                    if(renderingProvider.ElixirSuite__Rendering_Provider__r.MailingCountry != null){
                        country = renderingProvider.ElixirSuite__Rendering_Provider__r.MailingCountry;
                    }
                    String mailingAddress = street + '\n' +
                        city + ', ' + 
                        state + ' ' +
                        postalCode + '\n' +
                        country;
                    claim.ElixirSuite__Rendering_Provider_Address__c =  mailingAddress;
                    
                    //Service Facility Info
                    claim.ElixirSuite__Service_Facility_Location_NPI__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Code__c;
                    claim.ElixirSuite__Service_Facility_Location_Information__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.Name;
                    claim.ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Tax_Id__c;
                    claim.ElixirSuite__Service_Facility_Loc_Address__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Address__c; 
                    claim.ElixirSuite__Service_Facility_Address_2__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Address_2__c;
                    claim.ElixirSuite__Service_Facility_Loc_City__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_City__c;
                    claim.ElixirSuite__Service_Facility_Loc_State__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_State__c;
                    claim.ElixirSuite__Service_Facility_Loc_Zip__c = renderingProvider.ElixirSuite__Care_Episode_Location__r.ElixirSuite__Provider_Zip__c;

                    //Billing Information
                    claim.ElixirSuite__Billing_Provider_Info__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Code__c;//Added by Ashwini before ElixirSuite__BILLING_PROVIDER_INFO__c
                    claim.ElixirSuite__Billing_Provider_Address_1__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Address__c; 
                    claim.ElixirSuite__Billing_Provider_Address_2__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Address_2__c; 
                    claim.ElixirSuite__Billing_Provider_City__c =  renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_City__c;
                    claim.ElixirSuite__Billing_Provider_Name__c =  renderingProvider.ElixirSuite__Billing_Provider__r.Name;
                    claim.ElixirSuite__Billing_Provider_State__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_State__c;
                    claim.ElixirSuite__Billing_Provider_Zip__c =  renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Zip__c;
                    claim.ElixirSuite__Billing_Provider_Tax_ID__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Tax_Id__c;
                    claim.ElixirSuite__Billing_Provider_Info_NPI__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Code__c; 
                    claim.ElixirSuite__Billing_Provider_Taxonomy__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Taxonomy__c;
                    claim.ElixirSuite__Bill_Phone__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Phone__c;
                    claim.ElixirSuite__Federal_Tax_Id_Number__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Provider_Tax_Id__c;
                    claim.ElixirSuite__Billing_Provider_Tax_ID_Type__c = renderingProvider.ElixirSuite__Billing_Provider__r.ElixirSuite__Tax_Id_Type__c;
                }
            }
        }
       
        if(payorlst != null && payorlst.size() > 0){
                        claim.ElixirSuite__Payer_ID__c = payorlst[0].ElixirSuite__Payer_Code__c;
            
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
                    
                    
        List<ElixirSuite__Claim_Line_Items__c> claimLimelst =[Select id,Name,ElixirSuite__Procedure__c,ElixirSuite__Diagnosis_Pointer__c,
                                                              ElixirSuite__Procedure_Charge__c, ElixirSuite__Days_Units__c 
                                                              from ElixirSuite__Claim_Line_Items__c where ElixirSuite__Claim__c =:recId WITH SECURITY_ENFORCED ORDER BY Name]; 
        List<ElixirSuite__Claim_Line_Items__c> updatelist = New List<ElixirSuite__Claim_Line_Items__c>();
        Map<string,ElixirSuite__Procedure__c> claimproc= new Map <string,ElixirSuite__Procedure__c>();
        Set<string> procelstid = new Set<string>();
        Set<string> claimlstid = new Set<string>();
        
        for(ElixirSuite__Claim_Line_Items__c C2:claimLimelst){
            procelstid.add(C2.ElixirSuite__Procedure__c);
            claimlstid.add(C2.Id);
        }
        ElixirSuite__Procedure__c [] Procedurels = [Select id,ElixirSuite__Charges__c, Name,ElixirSuite__Place_Of_Service_Picklist__c, 
                                                    ElixirSuite__Days_Units__c, ElixirSuite__To_Date_of_Service__c, ElixirSuite__From_Date_of_Service__c,
                                                    ElixirSuite__Diagnosis_Pointer__c,ElixirSuite__CPT_HCPCS_Code__c,
                                                    ElixirSuite__Surgeon__c,ElixirSuite__Surgeon__r.Name,ElixirSuite__Surgeon__r.FirstName,ElixirSuite__Surgeon__r.LastName,
                                                    ElixirSuite__Surgeon__r.ElixirSuite__Taxonomy__c,ElixirSuite__Surgeon__r.ElixirSuite__Practitioner_NPI__c,ElixirSuite__Surgeon__r.ElixirSuite__ID_Number__c,
                                                    ElixirSuite__Surgeon__r.MailingStreet,ElixirSuite__Surgeon__r.MailingCity,ElixirSuite__Surgeon__r.MailingState,
                                                    ElixirSuite__Surgeon__r.MailingPostalCode ,ElixirSuite__Surgeon__r.MailingCountry , 
                                                    (Select id from ElixirSuite__Claim_Line_Items__r)
                                                    from ElixirSuite__Procedure__c where id IN: procelstid WITH SECURITY_ENFORCED];
        List<ElixirSuite__Procedure_Diagnosis__c>  Procediaglst = [Select id,ElixirSuite__ICD_Codes__r.name,
                                                                   ElixirSuite__Procedure__r.ElixirSuite__Claim__c,
                                                                   ElixirSuite__Procedure__c from ElixirSuite__Procedure_Diagnosis__c 
                                                                   where ElixirSuite__Procedure__c IN:procelstid WITH SECURITY_ENFORCED];
        
        Map<id,Set<String>> procDiagnosisCode = new Map<id,Set<String>>();//
        if(Procediaglst != null && Procediaglst.size()> 0){
            for(ElixirSuite__Procedure_Diagnosis__c diag:Procediaglst){
                if(procDiagnosisCode.containsKey(diag.ElixirSuite__Procedure__c)) {
                    procDiagnosisCode.get(diag.ElixirSuite__Procedure__c).add(diag.ElixirSuite__ICD_Codes__r.name);
                }else{
                    procDiagnosisCode.put(diag.ElixirSuite__Procedure__c,new Set<String>{diag.ElixirSuite__ICD_Codes__r.name});
                }  
            }
        }
        
        for(ElixirSuite__Procedure__c P1: Procedurels ){
            if(P1.ElixirSuite__Claim_Line_Items__r != null){
                String ClaimId = P1.ElixirSuite__Claim_Line_Items__r[0].Id;
                claimproc.put(P1.Id,P1);
            }
        }
        Decimal sum =0; 
        Map<Id,List<string>> claimDiagCode = new Map<Id,List<string>>();
        Map<String,Integer> ClaimFieldCodeMap = new  Map<String,Integer>();
        Boolean rendInfoCheck = false;
        for(ElixirSuite__Claim_Line_Items__c C1: claimLimelst){
            if(claimproc.get(C1.ElixirSuite__Procedure__c)!=null){
                C1.ElixirSuite__Days_Units__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Days_Units__c;
                C1.ElixirSuite__CPT_HCPCS_Code__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).Name;
                C1.ElixirSuite__To_Date_Of_Service__c = Date.valueOf((claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__To_Date_of_Service__c); 
                C1.ElixirSuite__From_Date_Of_Service__c = Date.valueOf((claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__From_Date_of_Service__c); 
                C1.ElixirSuite__Procedure_Charge__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Charges__c; 
                //C1.ElixirSuite__Place_of_Service__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Place_Of_Service_Picklist__c!=null ? (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Place_Of_Service_Picklist__c.substring(0,2) : '';
                C1.ElixirSuite__Place_of_Service__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Place_Of_Service_Picklist__c;
                C1.ElixirSuite__Place_of_Service_Code_s__c = (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Place_Of_Service_Picklist__c!=null ? (claimproc.get(C1.ElixirSuite__Procedure__c)).ElixirSuite__Place_Of_Service_Picklist__c.substring(0,2) : '';
                C1.ElixirSuite__Diagnosis_Pointer__c = null;
                List<String> existingCode = claimDiagCode.get(claim.id);
                if(procDiagnosisCode.containsKey(C1.ElixirSuite__Procedure__c) && procDiagnosisCode.get(C1.ElixirSuite__Procedure__c) != null) { 
                    for(String diag: procDiagnosisCode.get(C1.ElixirSuite__Procedure__c)){
                        Integer fieldCode = 64;
                        if(ClaimFieldCodeMap.containsKey(claim.id)){
                            fieldCode = ClaimFieldCodeMap.get(claim.id);   
                        }
                        
                        if(((existingCode != null && !(existingCode.contains(diag))) || existingCode == null) && fieldCode < 76){
                            
                            String fieldName = 'ElixirSuite__Diagnosis_'+string.fromCharArray(new List<Integer> {fieldCode+1})+'__c';
                            claim.put(fieldName,diag);
                            if(C1.ElixirSuite__Diagnosis_Pointer__c != null && C1.ElixirSuite__Diagnosis_Pointer__c != '' && C1.ElixirSuite__Diagnosis_Pointer__c != string.fromCharArray(new List<Integer> {fieldCode+1})){
                                C1.ElixirSuite__Diagnosis_Pointer__c = C1.ElixirSuite__Diagnosis_Pointer__c + ','+string.fromCharArray(new List<Integer> {fieldCode+1}); 
                            }else{
                                C1.ElixirSuite__Diagnosis_Pointer__c = string.fromCharArray(new List<Integer> {fieldCode+1});
                            }
                            ClaimFieldCodeMap.put(claim.id,fieldCode+1);
                            if(claimDiagCode.get(claim.Id) != null && (claimDiagCode.get(claim.Id)).size() >0){
                                claimDiagCode.get(claim.Id).add(diag);
                            }else{
                                List<String> diagnosisCode = new List<String>();
                                diagnosisCode.add(diag);
                                claimDiagCode.put(claim.Id,diagnosisCode);
                            }
                            
                            
                        }else{
                            for(integer k=65;k<=76;k++){
                                String fieldName = 'ElixirSuite__Diagnosis_'+string.fromCharArray(new List<Integer> {k})+'__c';
                                if(diag == claim.get(fieldName)){
                                    
                                    if(C1.ElixirSuite__Diagnosis_Pointer__c != null){
                                        C1.ElixirSuite__Diagnosis_Pointer__c = C1.ElixirSuite__Diagnosis_Pointer__c + ','+string.fromCharArray(new List<Integer> {k}); 
                                    }else{
                                        C1.ElixirSuite__Diagnosis_Pointer__c = string.fromCharArray(new List<Integer> {k});
                                    }  
                                    break;
                                }  
                            }
                            
                        }
                    }
                    
                    
                }else{
                    C1.ElixirSuite__Diagnosis_Pointer__c = '';
                }
            }
            
            if (C1.ElixirSuite__Days_Units__c != null && C1.ElixirSuite__Procedure_Charge__c != null) {
                sum += C1.ElixirSuite__Days_Units__c * C1.ElixirSuite__Procedure_Charge__c;
            }
            else {
                
                C1.ElixirSuite__Days_Units__c = 0;
                C1.ElixirSuite__Procedure_Charge__c = 0;
            }
            // adding rendering practitioner by jami for 11363
            if(claimproc.containsKey(C1.ElixirSuite__Procedure__c) && claimproc.get(C1.ElixirSuite__Procedure__c).ElixirSuite__Surgeon__c != null){
                ElixirSuite__Procedure__c renderingProvider = claimproc.get(C1.ElixirSuite__Procedure__c);
                C1.ElixirSuite__Rendering_Provider_First_Name__c = renderingProvider.ElixirSuite__Surgeon__r.FirstName;
                C1.ElixirSuite__Rendering_Provider_Last_Name__c = renderingProvider.ElixirSuite__Surgeon__r.LastName;
                C1.ElixirSuite__Rendering_Provider_Taxonomy__c = renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__Taxonomy__c;
                C1.ElixirSuite__Rendering_Provider_NPI__c = renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__Practitioner_NPI__c;
                C1.ElixirSuite__Rendering_Provider_Non_NPI__c = renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__ID_Number__c;
                String street = '';
                String city = '';
                String state = '';
                String postalCode = '';
                String country = '';
                if(renderingProvider.ElixirSuite__Surgeon__r.MailingStreet != null){
                    street = renderingProvider.ElixirSuite__Surgeon__r.MailingStreet;
                }
                if(renderingProvider.ElixirSuite__Surgeon__r.MailingCity != null){
                    city = renderingProvider.ElixirSuite__Surgeon__r.MailingCity;
                }
                if(renderingProvider.ElixirSuite__Surgeon__r.MailingState != null){
                    state = renderingProvider.ElixirSuite__Surgeon__r.MailingState;
                }
                if(renderingProvider.ElixirSuite__Surgeon__r.MailingPostalCode != null){
                    postalCode = renderingProvider.ElixirSuite__Surgeon__r.MailingPostalCode;
                }
                if(renderingProvider.ElixirSuite__Surgeon__r.MailingCountry != null){
                    country = renderingProvider.ElixirSuite__Surgeon__r.MailingCountry;
                }
                String mailingAddress = street + '\n' +
                    city + ', ' + 
                    state + ' ' +
                    postalCode + '\n' +
                    country;
                C1.ElixirSuite__Rendering_Provider_Address__c =  mailingAddress;
            if(!rendInfoCheck){
                 rendInfoCheck = true; 
                 claim.ElixirSuite__Rendering_Provider_First_Name__c = renderingProvider.ElixirSuite__Surgeon__r.FirstName;
                 claim.ElixirSuite__Rendering_Provider_Last_Name__c = renderingProvider.ElixirSuite__Surgeon__r.LastName;
                 claim.ElixirSuite__Rendering_Provider_Taxonomy__c = renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__Taxonomy__c;
                 claim.ElixirSuite__Rendering_Provider_NPI__c =  renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__Practitioner_NPI__c;
                 claim.ElixirSuite__Rendering_Provider_Tax_Id__c = renderingProvider.ElixirSuite__Surgeon__r.ElixirSuite__ID_Number__c;
                 claim.ElixirSuite__Rendering_Provider_Address__c =  mailingAddress;
                }
            }
           
            updatelist.add(C1);

        }
        
        
        claim.ElixirSuite__Total_Charge__c = sum;
        if(procDiagnosisCode.size() <= 0){
            for(integer k=65;k<=76;k++){
            String fieldName = 'ElixirSuite__Diagnosis_'+string.fromCharArray(new List<Integer> {k})+'__c';
            claim.put(fieldName,'');
            }
        }else if(ClaimFieldCodeMap.containsKey(claim.id)){
            Integer fieldCode = ClaimFieldCodeMap.get(claim.id); 
            fieldCode = fieldCode + 1;
            for(integer k=fieldCode;k<=76;k++){
            String fieldName = 'ElixirSuite__Diagnosis_'+string.fromCharArray(new List<Integer> {k})+'__c';
            claim.put(fieldName,'');
            } 
        }
        if(Schema.sObjectType.ElixirSuite__Claim__c.isUpdateable() && 
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_DOB__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_s_Address__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_Sex__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_s_City__c.isUpdateable() && 
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_Zip_Code__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_s_Phone__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_s_State__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_Country_Code__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Address__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_State__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Sex__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_s_ID_Number__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_City__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Zip_Code__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Country_Code__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Telephone__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_DOB__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insured_Policy__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Federal_Tax_Id_Number__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Patient_Relationship_to_Insured__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Accept_Assignment__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Auto_Accident_Related__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Employment_Related__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Payer_ID__c.isUpdateable() &&
           Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Total_Charge__c.isUpdateable() 
          ){
              update claim;
          }
        
        
        if(updatelist !=null && updatelist.size()>0){
            if(Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.isUpdateable() && 
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__Days_Units__c.isUpdateable() &&
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__Diagnosis_Pointer__c.isUpdateable() &&
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__CPT_HCPCS_Code__c.isUpdateable() &&
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__To_Date_Of_Service__c.isUpdateable() &&
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__From_Date_Of_Service__c.isUpdateable() &&
               Schema.sObjectType.ElixirSuite__Claim_Line_Items__c.fields.ElixirSuite__Procedure_Charge__c.isUpdateable() 
               
               
               
              ){
                  update updatelist;
              }
            
        }
        
        
    }

}
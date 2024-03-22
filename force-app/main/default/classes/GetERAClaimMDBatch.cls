global with sharing class GetERAClaimMDBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{ 
    
    global Database.QueryLocator start(Database.BatchableContext bc){       
        String query = 'SELECT Id, ElixirSuite__ERA_Id__c, ElixirSuite__ERA_Generated__c, ElixirSuite__Check_Number__c'+
            ' FROM ElixirSuite__Integration_Data__c'+
            ' WHERE ElixirSuite__ERA_Id__c!= NULL AND ElixirSuite__Integration_Data__c!=NULL AND ElixirSuite__ERA_Generated__c = false';
        return Database.getQueryLocator(query);
        
    }      
    global static Integration_Credentials__c getCredentials(){
        return [SELECT Id, Integration_Key__c 
            FROM Integration_Credentials__c WHERE Name='ClaimMD' WITH SECURITY_ENFORCED];
    } 
    global void execute(Database.BatchableContext BC, List<ElixirSuite__Integration_Data__c> scope){
        entryPointOfExecution(scope,scope[0].ElixirSuite__ERA_Id__c); 
    }
    global void finish(Database.BatchableContext BC){        
    }
    
    global static void entryPointOfExecution(List<ElixirSuite__Integration_Data__c> records, String eraId){
        ClaimJsonResponse.eraReceived = true;
        
        Integration_Credentials__c custset = getCredentials();
        String accountKey = custset.Integration_Key__c;
        
        if(String.isBlank(accountKey)){
            return;
        }
        ElixirSuite__Integration_Data__c data = records[0];
        ElixirSuite__ERA_Generation__c eraCS = ElixirSuite__ERA_Generation__c.getInstance();
        Boolean manualERA = eraCS.ElixirSuite__Manual_ERA_Posting_Opted__c==null?false:eraCS.ElixirSuite__Manual_ERA_Posting_Opted__c;
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','text/html; charset=UTF-8');        
        req.setMethod('GET');
        string url = 'callout:Claim_MD/services/eraxml/?';
        url+= 'AccountKey='+accountKey;
        url+= '&eraid='+eraId;
        system.debug('url '+url);
        req.setEndpoint(url);
        Http http = new Http();
        HttpResponse response = http.send(req);
        response.setHeader('Content-Type','text/html; charset=UTF-8');
        String resp = String.valueOf(response.getBody());
        Dom.Document doc = new Dom.Document();
        doc.load(response.getBody());
        system.debug(response.getBody());
        Dom.XMLNode root = doc.getRootElement();  //result
        if(root.getAttributeCount() != 0){
        String finalJson = '{';
        finalJson = generateBodyUsingRecursion(finalJson,root);
        finalJson += '}';   
        system.debug('&&'+finalJson);
        // Create a Unit Of Work
        fflib_SObjectUnitOfWorkClass uow = new fflib_SObjectUnitOfWorkClass(
            new Schema.SObjectType[] {
                ElixirSuite__EOB__c.SObjectType,
                    ElixirSuite__ERA_Line_Item__c.SObjectType
                    }
        );
        Map<String, Object> responseJson = (Map<String, Object>)JSON.deserializeUntyped(finalJson);        
        List<Object> result = (List<Object>)responseJson.get('result');
        Map<String, Object> claim = (Map<String, Object>) result[0];
        Map<String,ElixirSuite__EOB__c> pcnERAMap = new Map<String,ElixirSuite__EOB__c>();
        Map<String,ElixirSuite__EOB__c> uniquePcnERAMap = new Map<String,ElixirSuite__EOB__c>();
        Map<String,List<String>> claimVSEras = new Map<String,List<String>>();
        Set<String> chgIdSet = new Set<String>();
        
        Map<String,String> paymentMethodMap = new Map<String,String>{'FWT' =>'Check Federal Reserve Funds/Wire Transfer - Non-repetitive','NON'=>'Non-Payment Data',
            'ACH' =>'Automated Clearing House (ACH)','BOP' =>'Financial Institution Option','CCP' => 'Cash Concentration/Disbursement plus Addenda','CHK' => 'Cheque'};
                
                String payerName = (String)claim.get('payer_name');
        System.debug('payerName '+payerName);
        List<ElixirSuite__Payor__c> payerList = [SELECT Id FROM ElixirSuite__Payor__c WHERE Name =: payerName LIMIT 1];
        System.debug('payerList '+payerList);  
            
        List<Object> claims = (List<Object>) claim.get('claim');
        List<String> allClaims = new List<String>();
         // checking with Org-Id
        String orgsId = (UserInfo.getOrganizationId()).toUpperCase();
        if(claims!=null){
            for(Object claimRec : claims){    
                system.debug(claimRec);
                Map<String, Object> era = (Map<String, Object>) claimRec;
                if(era.get('pcn')!=null){
                    //allClaims.add(String.valueOf(era.get('pcn')));
                    //Check Org-id in pcn
                    if(String.valueOf(era.get('pcn')).containsIgnoreCase(orgsId)){
                        allClaims.add((String.valueOf(era.get('pcn'))).substringBefore(orgsId));
                    }else{
                        allClaims.add(String.valueOf(era.get('pcn'))); 
                    }
                }
            }
        }
         
        Boolean alreadyExistedClaims = false;
        List<ElixirSuite__Claim__c> claimList = [Select Id, Name,ElixirSuite__Claim_Status__c, ElixirSuite__Account__c,ElixirSuite__Posted__c
                                        FROM ElixirSuite__Claim__c WHERE Name IN :allClaims WITH SECURITY_ENFORCED];    
        
        if(claimList != null && claimList.size() > 0 && !claimList.isEmpty()){
        ElixirSuite__EOB__c masterEra = new ElixirSuite__EOB__c();
        masterEra.ElixirSuite__Payment_Trace__c = string.valueOf(claim.get('check_number'));
        masterEra.ElixirSuite__Provider_Name__c = string.valueOf(claim.get('claimmd_prov_name'));
        masterEra.ElixirSuite__Download_Time__c = string.valueOf(claim.get('download_time'));
        masterEra.ElixirSuite__Provider_Name__c = String.valueOf(claim.get('ins_name_l'));
        masterEra.ElixirSuite__Claim_Insurance_Id__c = String.valueOf(claim.get('ins_number'));
        masterEra.ElixirSuite__Amount_paid_by_Payer__c = claim.get('paid_amount')!=null?decimal.valueof((String)claim.get('paid_amount')):0;
        masterEra.ElixirSuite__Check_EFT_Date__c = claim.get('paid_date')!=null?Date.valueOf(string.valueOf(claim.get('paid_date'))):null;
        if(paymentMethodMap != null && paymentMethodMap.get((String)claim.get('payment_method')) != null){
        masterEra.ElixirSuite__Payment_Method__c = paymentMethodMap.get((String)claim.get('payment_method'));
        }else{
        masterEra.ElixirSuite__Payment_Method__c = (String)claim.get('payment_method');
        }
        masterEra.ElixirSuite__payer_address1__c = (String)claim.get('payer_addr_1');
        if(payerList != null && payerList.size() > 0){
            masterEra.ElixirSuite__Payer__c = payerList[0].Id;   
        }
        masterEra.ElixirSuite__payer_city__c = (String)claim.get('payer_city');
        masterEra.ElixirSuite__payer_name__c = (String)claim.get('payer_name');
        masterEra.ElixirSuite__Payer_Id__c = string.valueOf(claim.get('payerid'));
        masterEra.ElixirSuite__Provider_NPI__c = string.valueOf(claim.get('prov_npi'));
        masterEra.ElixirSuite__EOB_Id__c = string.valueOf(claim.get('eraid')); //Added by sonal
        if(Schema.sObjectType.ElixirSuite__EOB__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Claim_Insurance_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Download_Time__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Check_Number__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Provider_Name__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Amount_paid_by_Payer__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__payer_address1__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__paiddate__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__payer_city__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Payer_Id__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__Provider_NPI__c.isCreateable() &&
           Schema.sObjectType.ElixirSuite__EOB__c.fields.ElixirSuite__EOB_Id__c.isCreateable()){
               
               insert masterEra;
               
           }
        
        String eraName = [Select Name from ElixirSuite__EOB__c where id=:masterEra.id].Name;
        
        //Response Insertion    
        try{   
            String responseFile = resp; 
            system.debug('checkresponseRequestcontent'+responseFile);   
            ContentVersion docVer = New ContentVersion();   
            docVer.ContentLocation = 'S';   
            docVer.PathOnClient = 'Response.txt';   
            docVer.Title = eraName + 'Response'+'.txt';                  
            Blob reqData = Blob.valueof(responseFile);  
            docVer.VersionData = reqData;   
            
            insert DocVer;
            
            
            String VesId = [Select ContentDocumentid from ContentVersion where id=:DocVer.id].ContentDocumentid;    
            ContentDocumentLink Doclink = New ContentDocumentLink();    
            Doclink.ContentDocumentId = VesId;  
            Doclink.linkedEntityId = masterEra.id;    
            Doclink.sharetype = 'I';    
            Doclink.visibility = 'AllUsers';    
            insert Doclink;
            
        }   
        catch(exception ex) 
        {   
ElixirSuite__Exception_Log__c objExp = new ElixirSuite__Exception_Log__c();
            objExp.ElixirSuite__Line_Number__c = ex.getLineNumber();
            objExp.ElixirSuite__Stack_Trace_Long__c = ex.getMessage();
            Insert objExp;
            system.debug(ex.getmessage());  
        }
        
        Map<String,ElixirSuite__ERA_Line_Item__c> chgIdELIMap = new Map<String,ElixirSuite__ERA_Line_Item__c>();
        Map<String,ElixirSuite__ERA_Line_Item__c> uniqueELIMap = new Map<String,ElixirSuite__ERA_Line_Item__c>(); 

       
        
       /*
        Set<String> allAlreadyExistingClaims = new Set<String>();
        if(allClaims!=null && allClaims.size()>0){
            List<ElixirSuite__EOB__c> DBclaims = [SELECT Id,ElixirSuite__Pcn__c FROM ElixirSuite__EOB__c 
                                                  WHERE ElixirSuite__Pcn__c IN :allClaims AND ElixirSuite__Is_Excluded__c = FALSE
                                                  WITH SECURITY_ENFORCED
                                                  LIMIT 40000];
            if(DBclaims!=null && DBclaims.size()>0){
                for(ElixirSuite__EOB__c era:DBclaims){
                    allAlreadyExistingClaims.add(era.ElixirSuite__Pcn__c);
                }
            }
        }
        system.debug(allAlreadyExistingClaims);
        if(allAlreadyExistingClaims.size()>0){
            alreadyExistedClaims = true;
        }
        //END
        */
        Map<String,String> eraStatusdMap = new Map<String,String>{'1' =>'Process as Primary','2'=>'Processed as Secondary',
            '3' =>'Processed as Tertiary','4' =>'Denied','19' =>'19: Processed as Primary, Forwarded to Additional Payer(s)','20' => '20: Processed as Secondary, Forwarded to Additional Payer(s)','21' => '21: Processed as Tertiary, Forwarded to Additional Payer(s)','22' => '22: Reversal of Previous Payment','23' => '23: Not our Claim, Forwarded to Additional Payer(s)','25' => '25: Predetermination Pricing Only – No Payment'};
            ElixirSuite__Elixir_Custom_Setting__c customSetting = ElixirSuite__Elixir_Custom_Setting__c.getOrgDefaults();       
        Map<String,Boolean> claimStatusIfDenied = new Map<String,Boolean>();
        identifyDeniedClaims(claims,claimStatusIfDenied);
        List<String> pcnList = new List<String>();
        Boolean claimCheck= false;
        if(claims!=null){
            for(Object claimRec : claims){    
                system.debug('Claims '+claimRec);
                Map<String, Object> era = 
                    (Map<String, Object>) claimRec;
                if(era.get('pcn')!=null && String.isNotBlank((String)era.get('pcn')) && String.valueOf(era.get('pcn')).containsIgnoreCase(orgsId) && customSetting.ElixirSuite__By_Pass_Claim_Name__c){
                    System.debug('AAAAAAAAAAAA if');
                    claimCheck = true;   
                    alreadyExistedClaims = true;
                    ElixirSuite__EOB__c childEra = new ElixirSuite__EOB__c(); 
                    childEra.ElixirSuite__Check_Number__c = string.valueOf(era.get('check_number'));
                    childEra.ElixirSuite__Provider_Name__c = string.valueOf(era.get('claimmd_prov_name'));
                    if(((String)era.get('total_paid')) != null && ((String)era.get('total_paid')) != '' && String.isNotBlank((String)era.get('total_paid'))){
                        childEra.ElixirSuite__Net_Paid_Amt__c = Decimal.valueOf((String)era.get('total_paid'));}  
                    childEra.ElixirSuite__Provider_NPI__c = string.valueOf(era.get('prov_npi'));
                    childEra.ElixirSuite__Pcn__c = (String.valueOf(era.get('pcn'))).substringBefore(orgsId);
                    childEra.ElixirSuite__ERA_Status_Code__c = eraStatusdMap.get(string.ValueOf(era.get('status_code')));
                    //added 6830
                    childEra.ElixirSuite__Payer_ICN__c = string.valueOf(era.get('payer_icn'));
                    //end 6830
                    /*if(allAlreadyExistingClaims.contains(childEra.ElixirSuite__Pcn__c)){
                         continue;
                    }*/
                    if(((String)era.get('total_charge')) != null && ((String)era.get('total_charge')) != '' && String.isNotBlank((String)era.get('total_charge'))){
                        childEra.ElixirSuite__Total_Charge__c = decimal.valueof((String)era.get('total_charge'));}
                    if(manualERA){
                        childEra.ElixirSuite__Manual_ERA__c = true;
                        childEra.ElixirSuite__Manual_ERA_Status__c = 'ERA Generated';
                    }
                    uow.registerRelationship(childEra, ElixirSuite__EOB__c.ElixirSuite__EOB__c, masterEra);
                    uow.registerNew(childEra);
                    
                    pcnList.add(childEra.ElixirSuite__Pcn__c);
                    String uniqueKey;
                    /*if(childEra.ElixirSuite__Pcn__c.startsWithIgnoreCase('claim')){
                       if(!childEra.ElixirSuite__Pcn__c.contains('-')){
                            Integer index1 = childEra.ElixirSuite__Pcn__c.toLowerCase().lastIndexOf('m');
                            String numVal = childEra.ElixirSuite__Pcn__c.subString(index1+1,childEra.ElixirSuite__Pcn__c.length());
                            String claimNameKey = 'Claim'+'-'+numVal;
                            pcnERAMap.put(claimNameKey,childERA);
                        }
                        else{*/
                            pcnERAMap.put(childEra.ElixirSuite__Pcn__c,childERA);
                            uniqueKey = childEra.ElixirSuite__Pcn__c + ';' + string.valueOf(era.get('payer_icn'));
                            if(claimVSEras == null || (claimVSEras != null && !claimVSEras.containsKey(childEra.ElixirSuite__Pcn__c))){
                                        List<String> CmList = new List<String>();
                                        CmList.add(uniqueKey);  
                                        claimVSEras.put(childEra.ElixirSuite__Pcn__c,CmList);  
                            }else{
                                        List<String> CmList = claimVSEras.get(childEra.ElixirSuite__Pcn__c); 
                                        CmList.add(uniqueKey);
                                        claimVSEras.put(childEra.ElixirSuite__Pcn__c,CmList);   
                            }
                            uniquePcnERAMap.put(uniqueKey,childERA);
                     //    }
                    //}
                    
                    List<Object> charges = (List<Object>) era.get('charge');
                    for(Object eraLineItemRec :charges){
                        Map<String, Object> charge = (Map<String, Object>) eraLineItemRec;
                        if(charge != null && charge.size() > 0){
                        ElixirSuite__ERA_Line_Item__c eraLineItem = new ElixirSuite__ERA_Line_Item__c();
                        if(((String)charge.get('allowed')) != null && ((String)charge.get('allowed')) != '' && String.isNotBlank((String)charge.get('allowed'))){
                            eraLineItem.ElixirSuite__total_allowed_amount__c = Decimal.valueOf((String)charge.get('allowed'));
                        }
                        if(((String)charge.get('charge')) != null && ((String)charge.get('charge')) != '' && String.isNotBlank((String)charge.get('charge'))){
                            eraLineItem.ElixirSuite__Charge__c  = Decimal.valueOf((String)charge.get('charge'));
                        }
                        eraLineItem.ElixirSuite__chg_Id__c =(String) charge.get('chgid');
                        eraLineItem.ElixirSuite__From_Dos__c = (String) charge.get('from_dos');
                        if(((String)charge.get('paid')) != null && ((String)charge.get('paid')) != '' && String.isNotBlank((String)charge.get('paid'))){
                            eraLineItem.ElixirSuite__Paid__c  = Decimal.valueOf((String)charge.get('paid')); 
                        }
                        eraLineItem.ElixirSuite__Proc_code__c = String.valueOf(charge.get('proc_code'));
                        eraLineItem.ElixirSuite__Units__c = String.valueOf(charge.get('units'));
                        
                        Decimal PatRes = 0;
                        String patResValue = 'PR';
                        List<Object> adjustments = (List<Object>) charge.get('adjustment');
                        if(adjustments != null && adjustments.size() > 0){
                            for(Integer i=1 ; i<=adjustments.size() ; i++){
                                Map<String, Object> adjustment = (Map<String, Object>) adjustments[i-1];
                                if(adjustment != null && adjustment.size() > 0){
                                    if(((String)adjustment.get('amount')) != null && ((String)adjustment.get('amount')) != '' && String.isNotBlank((String)adjustment.get('amount'))){
                                        eraLineItem.put('ElixirSuite__Adjustment_Amount_'+ i + '__c', Decimal.valueOf((String)adjustment.get('amount')));}              
                                    eraLineItem.put('ElixirSuite__Code_'+ i + '__c', (String)(adjustment.get('code')));
                                    eraLineItem.put('ElixirSuite__Group_'+ i + '__c', (String)(adjustment.get('group')));
                                    eraLineItem.put('ElixirSuite__Count_of_total_adjustments_used__c', i);  
                                    if(((String)(adjustment.get('group'))).containsIgnoreCase(patResValue)) {
                                        PatRes = PatRes+ Decimal.valueOf((String)adjustment.get('amount')); 
                                    }    
                                }
                            }
                        }
                        eraLineItem.ElixirSuite__Patient_Responsibility__c = PatRes;
                            // added by Jami to handle the Remarks codes : LX3-10605
                              List<Object> remarkCodes = (List<Object>) charge.get('remark_code');
                            String remarkCodeString = '';
                            if (remarkCodes != null && remarkCodes.size() > 0) {
                                for (Object remarkCodeObj : remarkCodes) {
                                    String remarkCode = (String) remarkCodeObj;
                                    if (remarkCode != null && !String.isEmpty(remarkCode)) {
                                        if (!String.isEmpty(remarkCodeString)) {
                                            remarkCodeString += '; ';
                                        }
                                        remarkCodeString += remarkCode;
                                    }
                                }
                            }
                            if(remarkCodeString !=''){
                            eraLineItem.ElixirSuite__Remark_Codes__c = remarkCodeString;
                            }
                        String uniqueELi;
                        if(eraLineItem.ElixirSuite__chg_Id__c.startsWithIgnoreCase('cl'))
                        {
                            if(!eraLineItem.ElixirSuite__chg_Id__c.contains('-'))
                            {
                                Integer index1 = eraLineItem.ElixirSuite__chg_Id__c.toLowerCase().lastIndexOf('l');
                                String numVal = eraLineItem.ElixirSuite__chg_Id__c.subString(index1+1,eraLineItem.ElixirSuite__chg_Id__c.length());
                                String cliKey = 'CL'+'-'+numVal;
                                
                                uniqueELi = uniqueKey + cliKey;
                                chgIdELIMap.put(cliKey,eraLineItem);
                                uniqueELIMap.put(uniqueELi,eraLineItem);
                                chgIdSet.add(cliKey);
                                eraLineItem.ElixirSuite__chg_Id__c = uniqueELi;
                            }
                            else{
                                uniqueELi = uniqueKey + eraLineItem.ElixirSuite__chg_Id__c;
                                uniqueELIMap.put(uniqueELi,eraLineItem);
                                chgIdELIMap.put(eraLineItem.ElixirSuite__chg_Id__c,eraLineItem);
                                eraLineItem.ElixirSuite__chg_Id__c = uniqueELi;
                            }
                        } 
                        uow.registerRelationship(eraLineItem, ElixirSuite__ERA_Line_Item__c.ElixirSuite__EOB__c, childEra);
                        uow.registerNew(eraLineItem);
                    
                    }
                    }
                }else if(era.get('pcn')!=null && String.isNotBlank((String)era.get('pcn')) && !(String.valueOf(era.get('pcn')).containsIgnoreCase(orgsId)) && !(customSetting.ElixirSuite__By_Pass_Claim_Name__c)){
                    System.debug('AAAAAAAAAAAA else'); 
                    claimCheck = true; 
                    alreadyExistedClaims = true;
                    ElixirSuite__EOB__c childEra = new ElixirSuite__EOB__c(); 
                    childEra.ElixirSuite__Check_Number__c = string.valueOf(era.get('check_number'));
                    childEra.ElixirSuite__Provider_Name__c = string.valueOf(era.get('claimmd_prov_name'));
                    if(((String)era.get('total_paid')) != null && ((String)era.get('total_paid')) != '' && String.isNotBlank((String)era.get('total_paid'))){
                    childEra.ElixirSuite__Net_Paid_Amt__c = Decimal.valueOf((String)era.get('total_paid'));}  
                    childEra.ElixirSuite__Provider_NPI__c = string.valueOf(era.get('prov_npi'));
                    childEra.ElixirSuite__Pcn__c = (String.valueOf(era.get('pcn')));
                    childEra.ElixirSuite__ERA_Status_Code__c = eraStatusdMap.get(string.ValueOf(era.get('status_code')));
                    //added 6830
                    childEra.ElixirSuite__Payer_ICN__c = string.valueOf(era.get('payer_icn'));
                    //end 6830
                    /* if(allAlreadyExistingClaims.contains(childEra.ElixirSuite__Pcn__c)){
                         continue;
                    }*/
                    if(((String)era.get('total_charge')) != null && ((String)era.get('total_charge')) != '' && String.isNotBlank((String)era.get('total_charge'))){
                    childEra.ElixirSuite__Total_Charge__c = decimal.valueof((String)era.get('total_charge'));}
                    if(manualERA){
                        childEra.ElixirSuite__Manual_ERA__c = true;
                        childEra.ElixirSuite__Manual_ERA_Status__c = 'ERA Generated';
                    }
                    uow.registerRelationship(childEra, ElixirSuite__EOB__c.ElixirSuite__EOB__c, masterEra);
                    uow.registerNew(childEra);
                    
                    pcnList.add(childEra.ElixirSuite__Pcn__c);
                    String uniqueKey;
                    /*if(childEra.ElixirSuite__Pcn__c.startsWithIgnoreCase('claim')){
                        if(!childEra.ElixirSuite__Pcn__c.contains('-')){
                            Integer index1 = childEra.ElixirSuite__Pcn__c.toLowerCase().lastIndexOf('m');
                            String numVal = childEra.ElixirSuite__Pcn__c.subString(index1+1,childEra.ElixirSuite__Pcn__c.length());
                            String claimNameKey = 'Claim'+'-'+numVal;
                            pcnERAMap.put(claimNameKey,childERA);
                        }
                        else{*/
                            pcnERAMap.put(childEra.ElixirSuite__Pcn__c,childERA);
                            uniqueKey = childEra.ElixirSuite__Pcn__c + ';' + string.valueOf(era.get('payer_icn'));
                            if(claimVSEras == null || (claimVSEras != null && !claimVSEras.containsKey(childEra.ElixirSuite__Pcn__c))){
                                        List<String> CmList = new List<String>();
                                        CmList.add(uniqueKey);  
                                        claimVSEras.put(childEra.ElixirSuite__Pcn__c,CmList);  
                            }else{
                                        List<String> CmList = claimVSEras.get(childEra.ElixirSuite__Pcn__c); 
                                        CmList.add(uniqueKey);
                                        claimVSEras.put(childEra.ElixirSuite__Pcn__c,CmList);   
                            }
                            uniquePcnERAMap.put(uniqueKey,childERA);
                     //   }
                    //}
                    
                    List<Object> charges = (List<Object>) era.get('charge');
                    for(Object eraLineItemRec :charges){
                        Map<String, Object> charge = (Map<String, Object>) eraLineItemRec;
                        if(charge != null && charge.size() > 0){
                        ElixirSuite__ERA_Line_Item__c eraLineItem = new ElixirSuite__ERA_Line_Item__c();
                        if(((String)charge.get('allowed')) != null && ((String)charge.get('allowed')) != '' && String.isNotBlank((String)charge.get('allowed'))){
                            eraLineItem.ElixirSuite__total_allowed_amount__c = Decimal.valueOf((String)charge.get('allowed'));
                        }
                        if(((String)charge.get('charge')) != null && ((String)charge.get('charge')) != '' && String.isNotBlank((String)charge.get('charge'))){
                            eraLineItem.ElixirSuite__Charge__c  = Decimal.valueOf((String)charge.get('charge'));
                        }
                        eraLineItem.ElixirSuite__chg_Id__c =(String) charge.get('chgid');
                        eraLineItem.ElixirSuite__From_Dos__c = (String) charge.get('from_dos');
                        if(((String)charge.get('paid')) != null && ((String)charge.get('paid')) != '' && String.isNotBlank((String)charge.get('paid'))){
                            eraLineItem.ElixirSuite__Paid__c  = Decimal.valueOf((String)charge.get('paid')); 
                        }
                        eraLineItem.ElixirSuite__Proc_code__c = String.valueOf(charge.get('proc_code'));
                        eraLineItem.ElixirSuite__Units__c = String.valueOf(charge.get('units'));
                        
                        Decimal PatRes = 0;
                        String patResValue = 'PR';
                        List<Object> adjustments = (List<Object>) charge.get('adjustment');
                        if(adjustments != null && adjustments.size() > 0){
                            for(Integer i=1 ; i<=adjustments.size() ; i++){
                                Map<String, Object> adjustment = (Map<String, Object>) adjustments[i-1];
                                if(adjustment != null && adjustment.size() > 0){
                                    if(((String)adjustment.get('amount')) != null && ((String)adjustment.get('amount')) != '' && String.isNotBlank((String)adjustment.get('amount'))){
                                    eraLineItem.put('ElixirSuite__Adjustment_Amount_'+ i + '__c', Decimal.valueOf((String)adjustment.get('amount')));}              
                                    eraLineItem.put('ElixirSuite__Code_'+ i + '__c', (String)(adjustment.get('code')));
                                    eraLineItem.put('ElixirSuite__Group_'+ i + '__c', (String)(adjustment.get('group')));
                                    eraLineItem.put('ElixirSuite__Count_of_total_adjustments_used__c', i);  
                                    if(((String)(adjustment.get('group'))).containsIgnoreCase(patResValue)) {
                                        PatRes = PatRes+ Decimal.valueOf((String)adjustment.get('amount')); 
                                    }    
                                }
                            }
                        }
                        eraLineItem.ElixirSuite__Patient_Responsibility__c = PatRes;
                            // added by Jami to handle the Remarks codes : LX3-10605
                             List<Object> remarkCodes = (List<Object>) charge.get('remark_code');
                            String remarkCodeString = '';
                            if (remarkCodes != null && remarkCodes.size() > 0) {
                                for (Object remarkCodeObj : remarkCodes) {
                                    String remarkCode = (String) remarkCodeObj;
                                    if (remarkCode != null && !String.isEmpty(remarkCode)) {
                                        if (!String.isEmpty(remarkCodeString)) {
                                            remarkCodeString += '; ';
                                        }
                                        remarkCodeString += remarkCode;
                                    }
                                }
                            }
                            if(remarkCodeString !=''){
                            eraLineItem.ElixirSuite__Remark_Codes__c = remarkCodeString;
                            }
                       
                        String uniqueELi;
                        if(eraLineItem.ElixirSuite__chg_Id__c.startsWithIgnoreCase('cl'))
                        {
                            if(!eraLineItem.ElixirSuite__chg_Id__c.contains('-'))
                            {
                                Integer index1 = eraLineItem.ElixirSuite__chg_Id__c.toLowerCase().lastIndexOf('l');
                                String numVal = eraLineItem.ElixirSuite__chg_Id__c.subString(index1+1,eraLineItem.ElixirSuite__chg_Id__c.length());
                                String cliKey = 'CL'+'-'+numVal;
                                
                                uniqueELi = uniqueKey + cliKey;
                                chgIdELIMap.put(cliKey,eraLineItem);
                                uniqueELIMap.put(uniqueELi,eraLineItem);
                                chgIdSet.add(cliKey);
                                eraLineItem.ElixirSuite__chg_Id__c = uniqueELi;
                            }
                            else{
                                uniqueELi = uniqueKey + eraLineItem.ElixirSuite__chg_Id__c;
                                uniqueELIMap.put(uniqueELi,eraLineItem);
                                chgIdELIMap.put(eraLineItem.ElixirSuite__chg_Id__c,eraLineItem);
                                eraLineItem.ElixirSuite__chg_Id__c = uniqueELi;
                            }
                        } 
                        uow.registerRelationship(eraLineItem, ElixirSuite__ERA_Line_Item__c.ElixirSuite__EOB__c, childEra);
                        uow.registerNew(eraLineItem);
                    
                    }
                    }
                    
                }
            }
        }
        system.debug('pcnERAMap '+pcnERAMap);
        if(!claimCheck){
            String fileName = eraName + 'Response.txt';
            delete([Select Name from  ElixirSuite__EOB__c where id=:masterEra.id]);
            delete([SELECT Id, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:masterEra.id AND ContentDocument.Title=:fileName ]);
            
        }
        uow.commitWork();
        if(data != null && Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Generated__c.isUpdateable()){
            data.ElixirSuite__ERA_Generated__c = true;
            
            update data;
            
        }
        
        //Escaping already Created ERA -
        //system.debug(allAlreadyExistingClaims);
        /*
        if(!alreadyExistedClaims){//DELETE MasterERA if No new Claims are Present
            if(ElixirSuite__EOB__c.sObjectType.getDescribe().isDeletable()){
                delete masterERA;
                system.debug('Deleting Master ERA');
                return;
            }
        }*/
        Map<String,ElixirSuite__Claim__c> claimMap = new Map<String,ElixirSuite__Claim__c>();
        Map<String,ElixirSuite__Claim_Line_Items__c> cliMap = new Map<String,ElixirSuite__Claim_Line_Items__c>();
        List<ElixirSuite__EOB__c> erasToUpdate = new List<ElixirSuite__EOB__c>();
        List<ElixirSuite__ERA_Line_Item__c> elisToUpdate = new List<ElixirSuite__ERA_Line_Item__c>();
        List<ElixirSuite__Claim__c> claimsToUpdate = new List<ElixirSuite__Claim__c>();
        List<ElixirSuite__Claim_Line_Items__c> clisToUpdate = new List<ElixirSuite__Claim_Line_Items__c>();
        Map<String,ElixirSuite__ERA_Line_Item__c> eliChargeIdMap = new Map<String,ElixirSuite__ERA_Line_Item__c>();
        Set<Id> procedureIdSet = new Set<Id>();
        Map<Id,ElixirSuite__Payment_Transaction__c> procedurePaymentTransactionMap = new Map<Id,ElixirSuite__Payment_Transaction__c>();
        Map<String,String> procTranMap = new Map<String,String>();
        List<ElixirSuite__Payment_Transaction__c> mainPaymentTransactionsToUpdate = new List<ElixirSuite__Payment_Transaction__c>();
        
        
        fflib_SObjectUnitOfWorkClass uow1 = new fflib_SObjectUnitOfWorkClass(
            new Schema.SObjectType[] {
                ElixirSuite__Master_Transaction__c.SObjectType,
                    ElixirSuite__Payment_Transaction__c.SObjectType
                    }
        );
        system.debug('chgIdELIMap '+chgIdELIMap.keySet());
        for(ElixirSuite__Claim_Line_Items__c cli : [Select Id, ElixirSuite__Procedure__c from ElixirSuite__Claim_Line_Items__c WHERE Name IN: chgIdELIMap.keySet() LIMIT 50000]){
            procedureIdSet.add(cli.ElixirSuite__Procedure__c);
        }
        for(ElixirSuite__Procedure__c pro : [SELECT Id, (SELECT Id, ElixirSuite__Actual_Price__c,ElixirSuite__Total_Paid_Amount__c ,ElixirSuite__Status__c, ElixirSuite__Payment_Adjustments__c, 
                                                         ElixirSuite__Total_Received_Amount__c, ElixirSuite__Insurance_Payments__c,ElixirSuite__PatientOutstanding__c,ElixirSuite__Credit_Amount__c,ElixirSuite__Patient_Responsibility__c, ElixirSuite__ERA_Arrived__c
                                                         FROM ElixirSuite__Payment_Transaction__r WHERE ElixirSuite__Master_Transaction__c = null AND ElixirSuite__Payment_Sub_Transaction__c = null LIMIT 1) 
                                             FROM ElixirSuite__Procedure__c WHERE Id IN: procedureIdSet 
                                             WITH SECURITY_ENFORCED
                                             LIMIT 50000]){
                                                 if(pro.ElixirSuite__Payment_Transaction__r.size()>0){
                                                     procedurePaymentTransactionMap.put(pro.Id,pro.ElixirSuite__Payment_Transaction__r[0]);
                                                     procTranMap.put(pro.Id,pro.ElixirSuite__Payment_Transaction__r[0].Id);
                                                 }
                                             }   
        for(ElixirSuite__ERA_Line_Item__c eli : [Select Id, ElixirSuite__chg_Id__c, ElixirSuite__Total_Allowed_Amount__c,ElixirSuite__Charge__c,ElixirSuite__Provider_Adjustment__c, ElixirSuite__Patient_Responsibility__c,ElixirSuite__Other_Insurance_Responsibility__c,ElixirSuite__Total_Adjustment_Amount__c, ElixirSuite__Paid__c,ElixirSuite__Proc_code__c 
                                                 FROM ElixirSuite__ERA_Line_Item__c 
                                                 WHERE ElixirSuite__Chg_Id__c IN :uniqueELIMap.keySet()  
                                                 WITH SECURITY_ENFORCED
                                                 ORDER BY CreatedDate LIMIT 50000]){
                                                     eliChargeIdMap.put(eli.ElixirSuite__chg_Id__c,eli);
                                                 }
        
        Map<String,ElixirSuite__EOB__c> updatedPcnERAMap = new Map<String,ElixirSuite__EOB__c>();
        for(ElixirSuite__EOB__c era: [Select Id,Name,ElixirSuite__Pcn__c,ElixirSuite__EOB__r.Name,ElixirSuite__EOB__r.ElixirSuite__Payment_Method__c,ElixirSuite__Claim__r.ElixirSuite__Claim__c From ElixirSuite__EOB__c where ElixirSuite__Pcn__c IN :pcnList
                                      WITH SECURITY_ENFORCED
                                      ORDER BY CreatedDate ASC LIMIT 50000]){
                                          /*if(era.ElixirSuite__Pcn__c.startsWithIgnoreCase('claim')){
                                              if(!era.ElixirSuite__Pcn__c.contains('-')){
                                                  Integer index1 = era.ElixirSuite__Pcn__c.toLowerCase().lastIndexOf('m');
                                                  String numVal = era.ElixirSuite__Pcn__c.subString(index1+1,era.ElixirSuite__Pcn__c.length());
                                                  String claimNameKey = 'Claim'+'-'+numVal;
                                                  updatedPcnERAMap.put(claimNameKey,era);
                                              }
                                              else{*/
                                                  updatedPcnERAMap.put(era.ElixirSuite__Pcn__c,era);
                                           //   }
                                          //}
                                         
                                          
                                      }
        List<String> priClaimIds = new List<String>();
        List<String> secClaimCreationList = new  List<String>();
        List<String> createSecClaimList = new  List<String>();
        List<String> accIdList = new List<String>();
        List<ElixirSuite__Claim__c> claimLst = [Select Id, Name,ElixirSuite__Claim_Status__c,ElixirSuite__Claim__c,ElixirSuite__Claim__r.ElixirSuite__Primary_Patient_Responsibility__c,ElixirSuite__Claim__r.ElixirSuite__Primary_Paid__c,ElixirSuite__Account__c,ElixirSuite__Posted__c,ElixirSuite__Payer_Order__c,ElixirSuite__Primary_Paid__c,ElixirSuite__Amount_Paid__c,ElixirSuite__Total_Amount_Paid_By_Insurance__c,
                                               (Select Id, ElixirSuite__Claim__c,ElixirSuite__Primary_Paid__c,ElixirSuite__Total_Billed__c, ElixirSuite__CPT_HCPCS_Code__c, Name, ElixirSuite__Procedure__c, ElixirSuite__Total_Allowed_Amount__c, ElixirSuite__ERA_Received__c, ElixirSuite__Total_Adjustment__c,ElixirSuite__Amount_Paid_by_Insurance__c,ElixirSuite__Claim_Procedure_Line_Item__c,ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Paid__c,ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Patient_Responsibility__c
                                                FROM ElixirSuite__Claim_Line_Items__r LIMIT 30000) FROM ElixirSuite__Claim__c
                                                WHERE Name IN :pcnERAMap.keySet()
                                                WITH SECURITY_ENFORCED
                                                LIMIT 2000];
        for(ElixirSuite__Claim__c c:claimLst){
          priClaimIds.add(c.ElixirSuite__Claim__c); 
          secClaimCreationList.add(c.Id);  
          accIdList.add(c.ElixirSuite__Account__c);
        }
        System.debug('updatedPcnERAMapkeyset '+updatedPcnERAMap.keySet());
        system.debug('pcnERAMap '+pcnERAMap.keySet());
        system.debug('eliChargeIdMap '+eliChargeIdMap.keySet());
        Map<Id,ElixirSuite__Claim__c> primaryClaimVsSecClaim;
        if(priClaimIds != Null && priClaimIds.size() > 0){
        primaryClaimVsSecClaim = new Map<Id,ElixirSuite__Claim__c>( [Select id, Name, ElixirSuite__Claim__c,ElixirSuite__Claim_Status__c From ElixirSuite__Claim__c where Id IN:priClaimIds WITH SECURITY_ENFORCED]);
        }
        List<String> secClaimIds = new List<String>();
        if(secClaimCreationList != null && secClaimCreationList.size() >0 && accIdList != null && accIdList.size() >0){
          List<ElixirSuite__Claim__c> secExistingClaim = [Select id, Name, ElixirSuite__Claim__c From ElixirSuite__Claim__c where ElixirSuite__Claim__c IN:secClaimCreationList WITH SECURITY_ENFORCED];
            for(ElixirSuite__Claim__c c: secExistingClaim){
               secClaimIds.add(c.ElixirSuite__Claim__c);
            }
        }
        List<Id> accVSIns = new List<Id>();
        List<Account> accList = new  List<Account>();
        if(secClaimCreationList != null && secClaimCreationList.size() >0 && accIdList != null && accIdList.size() > 0){
           accList = [Select Id, Name,(Select id,name from ElixirSuite__VOB__r where ElixirSuite__Status__c ='Active' AND RecordType.DeveloperName='Secondary_VOB' LIMIT 1 ) from account where id IN: accIdList WITH SECURITY_ENFORCED];
        }
        for(Account ac: accList){
            if(ac.ElixirSuite__VOB__r != null && (ac.ElixirSuite__VOB__r).size() > 0){
               accVSIns.add(ac.Id);
            }
        }
       Map<String,ElixirSuite__Claim__c> updatedClaimpList = new  Map<String,ElixirSuite__Claim__c>();
        Map<String,ElixirSuite__Claim_Line_Items__c> updateClineItemList = new  Map<String,ElixirSuite__Claim_Line_Items__c>();
        ElixirSuite__Master_Transaction__c[] otherTrasnactionLstForChildERA = new List<ElixirSuite__Master_Transaction__c>();
        ElixirSuite__Transactions__c[] toInsertTransaction = new List<ElixirSuite__Transactions__c>();
        for(ElixirSuite__Claim__c cl : claimLst){
                                            system.debug(cl.Name.toUpperCase());
                                            Boolean Status = false;
                                            if(claimVSEras.containsKey(cl.Name)){
                                            for(string eraKey:claimVSEras.get(cl.Name)){
                                            if(uniquePcnERAMap.containsKey(eraKey)){
                                            ElixirSuite__EOB__c eraRec = uniquePcnERAMap.get(eraKey);
                                            system.debug(eraRec);
                                            eraRec.ElixirSuite__Claim__c = cl.Id;
                                            eraRec.ElixirSuite__Account__c = cl.ElixirSuite__Account__c;
                                            eraRec.ElixirSuite__Total_Allowed__c = 0;
                                            eraRec.ElixirSuite__Total_Adjustment_Amount__c = 0;
                                            eraRec.ElixirSuite__Total_Paid__c = 0;  
                                            eraRec.ElixirSuite__Total_Patient_Responsibility__c = 0; 
                                            eraRec.ElixirSuite__Total_OI_Responsibility__c = 0;                 
                                            cl.ElixirSuite__Manual_ERA__c = manualERA;
                                            if(Status == false && eraRec.ElixirSuite__ERA_Status_Code__c == 'Denied' && cl.ElixirSuite__Claim_Status__c != 'ERA Received'){
                                                    cl.ElixirSuite__Claim_Status__c = 'Denied';     
                                            }else if(cl.ElixirSuite__Claim_Status__c != 'ERA Received'){
                                                    cl.ElixirSuite__Claim_Status__c = 'ERA Received';  
                                                    Status = true;   
                                            }  
                                            if(primaryClaimVsSecClaim != null && primaryClaimVsSecClaim.size() > 0 && primaryClaimVsSecClaim.get(cl.ElixirSuite__Claim__c) != null){
                                            ElixirSuite__Claim__c priClaim = primaryClaimVsSecClaim.get(cl.ElixirSuite__Claim__c);
                                            priClaim.ElixirSuite__Claim_Status__c = 'ERA Received - Transferred to Secondary'; 
                                            //claimsToUpdate.add(priClaim);
                                            updatedClaimpList.put(priClaim.Id,priClaim); 
                                            }
                                            if((secClaimIds== null || !secClaimIds.contains(cl.Id)) && eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && manualERA == false){
                                                createSecClaimList.add(cl.Id);
                                            }
                                            System.debug('createSecClaimList '+createSecClaimList);
                                            String actionToTaken;
                                            if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0 && manualERA == false){
                                            eraRec.ElixirSuite__Action_to_be_Taken__c = 'Transfer to Secondary'; 
                                            actionToTaken = 'Transfer to Secondary';
                                            }
                                            if(cl.ElixirSuite__Amount_Paid__c == null){
                                             cl.ElixirSuite__Amount_Paid__c = 0;   
                                            }
                                            if(cl.ElixirSuite__Total_Amount_Paid_By_Insurance__c == null){
                                              cl.ElixirSuite__Total_Amount_Paid_By_Insurance__c = 0; 
                                            }
                                            //added 6830
                                             if(eraRec.ElixirSuite__Payer_ICN__c != null){
                                                    cl.ElixirSuite__Original_Ref_No__c = eraRec.ElixirSuite__Payer_ICN__c;
                                             }
                                            //end 6830                 
                                            String claimNameKey = '';
                                           /* if(cl.Name.startsWithIgnoreCase('claim')){
                                                if(!cl.Name.contains('-')){
                                                    Integer index1 = cl.Name.toLowerCase().lastIndexOf('m');
                                                    String numVal = cl.Name.subString(index1+1,cl.Name.length());
                                                    claimNameKey = 'Claim'+'-'+numVal;
                                                }
                                                else{*/
                                                    claimNameKey = cl.Name;
                                               // }
                                           // }
                                            if(cl.ElixirSuite__Claim_Line_Items__r.size()>0)
                                            {
                                                for(ElixirSuite__Claim_Line_Items__c cli : cl.ElixirSuite__Claim_Line_Items__r)
                                                {
                                                    system.debug('cliName '+cli.Name);
                                                     String cliKey = eraKey +cli.Name;
                                                    if(eliChargeIdMap.containsKey(cliKey))
                                                    {
                                                        ElixirSuite__ERA_Line_Item__c eli = eliChargeIdMap.get(cliKey);
                                                        eli.ElixirSuite__Claim_Line_Items__c = cli.Id;
                                                        
                                                        cli.ElixirSuite__ERA_Received__c = manualERA? false : true;
                                                        cli.ElixirSuite__Total_Allowed_Amount__c = eli.ElixirSuite__Total_Allowed_Amount__c;
                                                        cli.ElixirSuite__Total_Adjustment__c = eli.ElixirSuite__Total_Adjustment_Amount__c;
                                                        cli.ElixirSuite__Amount_Paid_by_Insurance__c = eli.ElixirSuite__Paid__c;
                                                        
                                                        eraRec.ElixirSuite__Total_Allowed__c += eli.ElixirSuite__Total_Allowed_Amount__c;
                                                        eraRec.ElixirSuite__Total_Adjustment_Amount__c += eli.ElixirSuite__Total_Adjustment_Amount__c;
                                                        System.debug('eli.ElixirSuite__Paid__c '+eli.ElixirSuite__Paid__c);
                                                        eraRec.ElixirSuite__Total_Paid__c += eli.ElixirSuite__Paid__c;
                                                        eraRec.ElixirSuite__Total_Patient_Responsibility__c +=eli.ElixirSuite__Patient_Responsibility__c;
                                                        eraRec.ElixirSuite__Total_OI_Responsibility__c +=eli.ElixirSuite__Other_Insurance_Responsibility__c;
                                                        
                                                        
                                                        elisToUpdate.add(eli);
                                                        system.debug('before ManualERA'+procedurePaymentTransactionMap.keySet());
                                                        if(manualERA == false && !ClaimJsonResponse.isDenied.containsKey(cl.Id)){ //Reconciliation will happen only when Auto ERA generation is opted
                                                            //Payment Transaction Reconciliation Logic
                                                            system.debug('after ManualERA'+cli.ElixirSuite__Procedure__c);
                                                            if((eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' || eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary') && cl.ElixirSuite__Posted__c == false){ //eraRec.ElixirSuite__ERA_Status_Code__c == 'Denied' || eraRec.ElixirSuite__ERA_Status_Code__c == '19: Processed as Primary, Forwarded to Additional Payer(s)'
                                                                if(procedurePaymentTransactionMap.containsKey(cli.ElixirSuite__Procedure__c)){
                                                                    system.debug('ManualERA '+cli.ElixirSuite__Procedure__c);
                                                                    ElixirSuite__Payment_Transaction__c paymentRecord  = procedurePaymentTransactionMap.get(cli.ElixirSuite__Procedure__c);
                                                                    if(accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0){
                                                                       paymentRecord.ElixirSuite__Patient_Responsibility__c = 0;
                                                                    }
                                                                    
                                                                    else if(accVSIns.contains(cl.ElixirSuite__Account__c) && (eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary' || eraRec.ElixirSuite__Action_to_be_Taken__c == 'Adjustment Writeoff')){
                                                                    Decimal patientres=0;
                                                                    patientres = cli.ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Patient_Responsibility__c - eli.ElixirSuite__Paid__c;
                                                                        if(patientres > 0 || patientres >0.0){
                                                                            paymentRecord.ElixirSuite__Patient_Responsibility__c = patientres;
                                                                        }else{
                                                                            paymentRecord.ElixirSuite__Patient_Responsibility__c = 0;
                                                                        }
                                                                    }
                                                                    else{
                                                                        paymentRecord.ElixirSuite__Patient_Responsibility__c = eli.ElixirSuite__Patient_Responsibility__c;}
                                                                    paymentRecord.ElixirSuite__Posted__c = true;
                                                                    if(procedurePaymentTransactionMap.get(cli.ElixirSuite__Procedure__c) != null){
                                                                        if(cl.ElixirSuite__Posted__c){
                                                                            
                                                                            ElixirSuite__Transactions__c transactionRec = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = cli.ElixirSuite__Total_Billed__c - eli.ElixirSuite__Paid__c,                                                                                        
                                                                                                                                                           ElixirSuite__Payment_DateTime__c = System.now(),
                                                                                                                                                           ElixirSuite__Master_Transaction__c = procTranMap.get(cli.ElixirSuite__Procedure__c),
                                                                                                                                                           ElixirSuite__Type_of_Payment__c = 'Payment'
                                                                                                                                                          );  
                                                                            if(cl.ElixirSuite__Payer_Order__c == 'Secondary'){
                                                                                transactionRec.ElixirSuite__Payment_Received_By__c='Secondary Insurance';
                                                                            }else{
                                                                                transactionRec.ElixirSuite__Payment_Received_By__c='Insurance';      
                                                                            }
                                                                            toInsertTransaction.add(transactionRec);
                                                                            if(eraRec.ElixirSuite__Action_to_be_Taken__c != 'Transfer to Patient' || (!accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0)){
                                                                                
                                                                                ElixirSuite__Transactions__c transactionRec1 = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = eli.ElixirSuite__Provider_Adjustment__c,                                                                                        
                                                                                                                                                                ElixirSuite__Payment_DateTime__c = System.now(),
                                                                                                                                                                ElixirSuite__Type_of_Payment__c='Adjustment',
                                                                                                                                                                ElixirSuite__Master_Transaction__c = procTranMap.get(cli.ElixirSuite__Procedure__c) 
                                                                                                                                                               );
                                                                                if(cl.ElixirSuite__Payer_Order__c == 'Secondary'){
                                                                                    transactionRec1.ElixirSuite__Payment_Received_By__c='Secondary Insurance';
                                                                                }else{
                                                                                    transactionRec1.ElixirSuite__Payment_Received_By__c='Insurance';      
                                                                                }
                                                                                toInsertTransaction.add(transactionRec1);
                                                                                
                                                                            }
                                                                        }else{
                                                                            ElixirSuite__Transactions__c transactionRec = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = eli.ElixirSuite__Paid__c,                                                                                        
                                                                                                                                                           ElixirSuite__Payment_DateTime__c = System.now(),
                                                                                                                                                           ElixirSuite__Master_Transaction__c = procTranMap.get(cli.ElixirSuite__Procedure__c),
                                                                                                                                                           ElixirSuite__Type_of_Payment__c = 'Payment'
                                                                                                                                                          );  
                                                                             if(cl.ElixirSuite__Payer_Order__c == 'Secondary'){
                                                                                transactionRec.ElixirSuite__Payment_Received_By__c='Secondary Insurance';
                                                                            }else{
                                                                                transactionRec.ElixirSuite__Payment_Received_By__c='Insurance';      
                                                                            }
                                                                            toInsertTransaction.add(transactionRec);
                                                                            
                                                                            if(eraRec.ElixirSuite__Action_to_be_Taken__c != 'Transfer to Patient' || (!accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0)){
                                                                                
                                                                                ElixirSuite__Transactions__c transactionRec1 = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = eli.ElixirSuite__Provider_Adjustment__c,                                                                                        
                                                                                                                                                                ElixirSuite__Payment_DateTime__c = System.now(),
                                                                                                                                                                ElixirSuite__Type_of_Payment__c='Adjustment',
                                                                                                                                                                ElixirSuite__Master_Transaction__c = procTranMap.get(cli.ElixirSuite__Procedure__c) 
                                                                                                                                                               );
                                                                                if(cl.ElixirSuite__Payer_Order__c == 'Secondary'){
                                                                                    transactionRec1.ElixirSuite__Payment_Received_By__c='Secondary Insurance';
                                                                                }else{
                                                                                    transactionRec1.ElixirSuite__Payment_Received_By__c='Insurance';      
                                                                                }
                                                                                
                                                                                toInsertTransaction.add(transactionRec1);
                                                                                
                                                                            }
                                                                        }
                                                                        
                                                                    }
                                                                }
                                                                
                                                                //ClaimLineItem Reconcilaation Summary
                                                                cli.ElixirSuite__Primary_Billed__c= eli.ElixirSuite__Charge__c;
                                                                cli.ElixirSuite__Primary_Allowed__c= eli.ElixirSuite__total_allowed_amount__c;
                                                                cli.ElixirSuite__Primary_Paid__c= eli.ElixirSuite__Paid__c;
                                                                cli.ElixirSuite__Primary_Patient_Responsibility__c= eli.ElixirSuite__Patient_Responsibility__c;
                                                                cli.ElixirSuite__Primary_Other_Insurance_Responsibility__c=eli.ElixirSuite__Other_Insurance_Responsibility__c;
                                                                cli.ElixirSuite__Primary_Adjustment__c= eli.ElixirSuite__Total_Adjustment_Amount__c;
                                                                cli.ElixirSuite__Total_Billed__c= eli.ElixirSuite__Charge__c;
                                                                cli.ElixirSuite__Total_Paid__c= eli.ElixirSuite__Paid__c;
                                                                if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && eraRec.ElixirSuite__Action_to_be_Taken__c == 'Transfer to Patient' && actionToTaken != 'Transfer to Secondary'){
                                                                  cli.ElixirSuite__Total_Patient_Responsibility__c=(eli.ElixirSuite__Charge__c - eli.ElixirSuite__Paid__c);
                                                                  cli.ElixirSuite__Total_Adjustment__c=0; 
                                                                }else if((eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' || eraRec.ElixirSuite__Action_to_be_Taken__c == 'Adjustment Writeoff') &&  actionToTaken != 'Transfer to Secondary'){
                                                                  cli.ElixirSuite__Total_Patient_Responsibility__c=eli.ElixirSuite__Patient_Responsibility__c;
                                                                  cli.ElixirSuite__Total_Adjustment__c= (eli.ElixirSuite__Charge__c - eli.ElixirSuite__Paid__c) - eli.ElixirSuite__Patient_Responsibility__c;
                                                                }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0 && actionToTaken == 'Transfer to Secondary'){
                                                                  cli.ElixirSuite__Total_Patient_Responsibility__c=eli.ElixirSuite__Patient_Responsibility__c;
                                                                  cli.ElixirSuite__Total_Adjustment__c=eli.ElixirSuite__Total_Adjustment_Amount__c;   
                                                                }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary' || eraRec.ElixirSuite__Action_to_be_Taken__c == 'Adjustment Writeoff'){
                                                                    Decimal patientres=0;
                                                                    Decimal adjAmt = 0;
                                                                    patientres = cli.ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Patient_Responsibility__c - eli.ElixirSuite__Paid__c;
                                                                    system.debug('patientres '+patientres);
                                                                    if(patientres > 0 || patientres >0.0){
                                                                        cli.ElixirSuite__Primary_Patient_Responsibility__c = patientres;
                                                                        cli.ElixirSuite__Total_Patient_Responsibility__c = patientres;
                                                                        adjAmt = eli.ElixirSuite__Charge__c - cli.ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Paid__c - eli.ElixirSuite__Paid__c - patientres;
                                                                    }else{
                                                                        cli.ElixirSuite__Primary_Patient_Responsibility__c = 0;
                                                                        cli.ElixirSuite__Total_Patient_Responsibility__c = 0; 
                                                                        adjAmt = eli.ElixirSuite__Charge__c - cli.ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Paid__c - eli.ElixirSuite__Paid__c;
                                                                    }
                                                                    
                                                                    
                                                                    cli.ElixirSuite__Total_Adjustment__c = adjAmt;
                                                                    cli.ElixirSuite__Primary_Adjustment__c = adjAmt;
                                                                }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary' && eraRec.ElixirSuite__Action_to_be_Taken__c == 'Transfer to Patient'){
                                                                    Decimal patientres=0;
                                                                    patientres = eli.ElixirSuite__Charge__c -cli.ElixirSuite__Claim_Procedure_Line_Item__r.ElixirSuite__Primary_Paid__c - eli.ElixirSuite__Paid__c;
                                                                    cli.ElixirSuite__Primary_Patient_Responsibility__c = patientres;
                                                                    cli.ElixirSuite__Total_Patient_Responsibility__c = patientres;
                                                                    cli.ElixirSuite__Total_Adjustment__c = 0;
                                                                    cli.ElixirSuite__Primary_Adjustment__c = 0;
                                                                }
                                                               
                                                            }
                                                        }
                                                        //clisToUpdate.add(cli);
updateClineItemList.put(cli.Id,cli);
                                                    }
                                                }
                                               
                                                cl.ElixirSuite__Total_Amount_Paid_By_Insurance__c += eraRec.ElixirSuite__Total_Paid__c;
                                            }
                                            if(manualERA == false && !ClaimJsonResponse.isDenied.containsKey(cl.Id)){ //Reconciliation will happen only when Auto ERA generation is opted
                                                if((eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' || eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary') && cl.ElixirSuite__Posted__c == false){ //eraRec.ElixirSuite__ERA_Status_Code__c == 'Denied' || eraRec.ElixirSuite__ERA_Status_Code__c == '19: Processed as Primary, Forwarded to Additional Payer(s)'
                                                    if(eraRec.ElixirSuite__Net_Paid_Amt__c!=null && eraRec.ElixirSuite__Total_Paid__c!=null)
                                                    {
                                                        Decimal intrstOrLateFilingCharges = eraRec.ElixirSuite__Net_Paid_Amt__c - eraRec.ElixirSuite__Total_Paid__c;
                                                        system.debug('intrstOrLateFilingCharges '+intrstOrLateFilingCharges);
                                                        if(intrstOrLateFilingCharges != 0 ){
                                                            ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c(
                                                                ElixirSuite__Account__c = eraRec.ElixirSuite__Account__c,
                                                                ElixirSuite__Allocated_Amount__c = 0,
                                                                ElixirSuite__Reason_Of_Payment__c  = 'Interest/Late Filing Charges', 
                                                                ElixirSuite__Payment_Notes__c = (updatedPcnERAMap.get(cl.Name.toUpperCase())).ElixirSuite__EOB__r.Name + (updatedPcnERAMap.get(cl.Name.toUpperCase())).Name  + cl.Name.toUpperCase(),   
                                                                ElixirSuite__Mode_of_Payment__c = (updatedPcnERAMap.get(cl.Name.toUpperCase())).ElixirSuite__EOB__r.ElixirSuite__Payment_Method__c,
                                                                ElixirSuite__Payment_Received_By__c = 'Insurance',
                                                                ElixirSuite__Transaction_Date__c = System.today(),
                                                                ElixirSuite__Total_Amount_Paid__c = intrstOrLateFilingCharges,                                              
                                                                ElixirSuite__Interest_Late_Filling_Charges__c = intrstOrLateFilingCharges
                                                            ); 
                                                            otherTrasnactionLstForChildERA.add(otherTransaction);
                                                        }
                                                    }
                                                    ElixirSuite__Master_Transaction__c otherTransaction_Static = new ElixirSuite__Master_Transaction__c(
                                                        ElixirSuite__Account__c = eraRec.ElixirSuite__Account__c,
                                                        ElixirSuite__Allocated_Amount__c = eraRec.ElixirSuite__Total_Paid__c,
                                                        ElixirSuite__Reason_Of_Payment__c  = 'ERA/EOB Payment',          
                                                        ElixirSuite__Payment_Notes__c = (updatedPcnERAMap.get(cl.Name.toUpperCase())).ElixirSuite__EOB__r.Name + (updatedPcnERAMap.get(cl.Name.toUpperCase())).Name  + cl.Name.toUpperCase(), 
                                                        ElixirSuite__Mode_of_Payment__c = (updatedPcnERAMap.get(cl.Name.toUpperCase())).ElixirSuite__EOB__r.ElixirSuite__Payment_Method__c,
                                                        ElixirSuite__Payment_Received_By__c = 'Insurance',
                                                        ElixirSuite__Transaction_Date__c = System.today(),
                                                        ElixirSuite__Total_Amount_Paid__c = eraRec.ElixirSuite__Total_Paid__c,
                                                        ElixirSuite__Refrence_Key__c = eraRec.Id
                                                    ); 
                                                    otherTrasnactionLstForChildERA.add(otherTransaction_Static);
                                                    
                                                    //Claim Reconcillation Summary
                                                    cl.ElixirSuite__Primary_Billed__c= eraRec.ElixirSuite__Total_Charge__c;
                                                    cl.ElixirSuite__Primary_Allowed__c= eraRec.ElixirSuite__Total_Allowed__c;
                                                    if(cl.ElixirSuite__Posted__c){
                                                        ElixirSuite__Master_Transaction__c diffAmtsObj = new ElixirSuite__Master_Transaction__c(
                                                            ElixirSuite__Account__c =  eraRec.ElixirSuite__Account__c,
                                                            ElixirSuite__Reason_Of_Payment__c  = 'ERA/EOB Payment',          
                                                            ElixirSuite__Mode_of_Payment__c = (updatedPcnERAMap.get(cl.Name.toUpperCase())).ElixirSuite__EOB__r.ElixirSuite__Payment_Method__c,
                                                            ElixirSuite__Payment_Received_By__c = 'Insurance',
                                                            ElixirSuite__Transaction_Date__c = System.today(),
                                                            ElixirSuite__Total_Amount_Paid__c = cl.ElixirSuite__Primary_Paid__c - eraRec.ElixirSuite__Net_Paid_Amt__c);
                                                        
                                                        otherTrasnactionLstForChildERA.add(diffAmtsObj);
                                                    }
                                                   
                                                    cl.ElixirSuite__Primary_Paid__c= eraRec.ElixirSuite__Total_Paid__c;
                                                    cl.ElixirSuite__Primary_Patient_Responsibility__c= eraRec.ElixirSuite__Total_Patient_Responsibility__c;
                                                    cl.ElixirSuite__Interest_Late_filing_charges__c= eraRec.ElixirSuite__Net_Paid_Amt__c - eraRec.ElixirSuite__Total_Paid__c;
                                                    cl.ElixirSuite__Primary_Adjustment__c= eraRec.ElixirSuite__Total_Adjustment_Amount__c;
                                                    cl.ElixirSuite__Total_Billed__c= eraRec.ElixirSuite__Total_Charge__c;
                                                    cl.ElixirSuite__Total_Paid__c = eraRec.ElixirSuite__Net_Paid_Amt__c;
                                                    cl.ElixirSuite__Posted__c = true;
                                                    cl.ElixirSuite__Amount_Paid__c += eraRec.ElixirSuite__Total_Paid__c;
                                                    cl.ElixirSuite__Primary_Other_Insurance_Responsibility__c= eraRec.ElixirSuite__Total_OI_Responsibility__c;
                                                    if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && eraRec.ElixirSuite__Action_to_be_Taken__c == 'Transfer to Patient' && actionToTaken != 'Transfer to Secondary'){
                                                         
                                                        cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = (eraRec.ElixirSuite__Total_Charge__c-eraRec.ElixirSuite__Total_Paid__c) - (eraRec.ElixirSuite__Net_Paid_Amt__c-eraRec.ElixirSuite__Total_Paid__c);
                                                        cl.ElixirSuite__Total_Adjustment__c= (eraRec.ElixirSuite__Net_Paid_Amt__c-eraRec.ElixirSuite__Total_Paid__c);
                                                    }else if((eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' || eraRec.ElixirSuite__Action_to_be_Taken__c == 'Adjustment Writeoff') && actionToTaken != 'Transfer to Secondary'){//changes to OR just because action to be taken is by default as adjustment write off
                                                         
                                                        cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = eraRec.ElixirSuite__Total_Patient_Responsibility__c;
                                                        cl.ElixirSuite__Total_Adjustment__c= (eraRec.ElixirSuite__Total_Charge__c-eraRec.ElixirSuite__Net_Paid_Amt__c) - eraRec.ElixirSuite__Total_Patient_Responsibility__c;
                                                    }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Process as Primary' && accVSIns.contains(cl.ElixirSuite__Account__c) && createSecClaimList != null && createSecClaimList.size() > 0 && actionToTaken == 'Transfer to Secondary'){
                                                         
                                                        cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = eraRec.ElixirSuite__Total_Patient_Responsibility__c;
                                                        cl.ElixirSuite__Total_Adjustment__c= eraRec.ElixirSuite__Total_Adjustment_Amount__c;
                                                        cl.ElixirSuite__Claim_Status__c = 'Paid with Patient Responsibility – Ready to submit Secondary Insurance';
                                                    }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary' || eraRec.ElixirSuite__Action_to_be_Taken__c == 'Adjustment Writeoff'){
                                                        
                                                        Decimal patientres=0;
                                                        Decimal adjAmt = 0;
                                                        patientres = cl.ElixirSuite__Claim__r.ElixirSuite__Primary_Patient_Responsibility__c - eraRec.ElixirSuite__Total_Paid__c;
                                                        system.debug('patientres '+patientres);
                                                        if(patientres > 0 || patientres >0.0){
                                                            cl.ElixirSuite__Primary_Patient_Responsibility__c = patientres;
                                                            cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = patientres;
                                                            adjAmt = eraRec.ElixirSuite__Total_Charge__c - cl.ElixirSuite__Claim__r.ElixirSuite__Primary_Paid__c - eraRec.ElixirSuite__Total_Paid__c - patientres;
                                                        }else{
                                                            cl.ElixirSuite__Primary_Patient_Responsibility__c = 0;
                                                            cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = 0; 
                                                            adjAmt = eraRec.ElixirSuite__Total_Charge__c - cl.ElixirSuite__Claim__r.ElixirSuite__Primary_Paid__c - eraRec.ElixirSuite__Total_Paid__c;
                                                        }
                                                        cl.ElixirSuite__Total_Adjustment__c = adjAmt;
                                                        cl.ElixirSuite__Primary_Adjustment__c = adjAmt;
                                                    }else if(eraRec.ElixirSuite__ERA_Status_Code__c == 'Processed as Secondary' && eraRec.ElixirSuite__Action_to_be_Taken__c == 'Transfer to Patient'){
                                                  
                                                        Decimal patientres=0;
                                                        patientres = eraRec.ElixirSuite__Total_Charge__c - cl.ElixirSuite__Claim__r.ElixirSuite__Primary_Paid__c - eraRec.ElixirSuite__Total_Paid__c;
                                                        cl.ElixirSuite__Primary_Patient_Responsibility__c = patientres;
                                                        cl.ElixirSuite__Total_Patient_Responsibility_Primary__c = patientres;
                                                        cl.ElixirSuite__Total_Adjustment__c = 0;
                                                        cl.ElixirSuite__Primary_Adjustment__c = 0;
                                                    }
                                                   
                                                    // 
                                                    eraRec.ElixirSuite__Primary_Posted__c = true;
                                                }
                                            }
                                            
                                            
                                            
                                            erasToUpdate.add(eraRec);
                                            
                                            }
                                            }
                                                 updatedClaimpList.put(cl.Id,cl); 
                                           system.debug('claimsToUpdate '+updatedClaimpList.values());
                                            }
                                        }     
        try {
            
            System.debug('claimsToUpdate '+updatedClaimpList.values());
            if(updatedClaimpList != null && updatedClaimpList.size()>0){
                
                
                update updatedClaimpList.values();
                
            }
            if(accVSIns != null && accVSIns.size() > 0 && createSecClaimList != null && createSecClaimList.size() > 0){
              system.debug('claimsToUpdate '+claimsToUpdate);
              secClaimCreation(createSecClaimList,accIdList);
            }
            if(erasToUpdate != null && erasToUpdate.size()>0){
                
                
                update erasToUpdate;
                
            }
            if(updateClineItemList != null && updateClineItemList.size()>0){
                
                
                update updateClineItemList.values();
                
            }
            if(elisToUpdate != null && elisToUpdate.size()>0){
                
                
                update elisToUpdate;
                
            }
            if(toInsertTransaction != null && toInsertTransaction.size() >0){
                
                insert toInsertTransaction;
            }
            if(otherTrasnactionLstForChildERA != null && otherTrasnactionLstForChildERA.size() >0){
                
                insert otherTrasnactionLstForChildERA;
            }
            
            if(manualERA == false){
                if(procedurePaymentTransactionMap != null && procedurePaymentTransactionMap.size() >0 ) {
                    Database.update(procedurePaymentTransactionMap.values(),false);
                }
                uow1.commitWork();
            }   
        } catch(Exception e) {
ElixirSuite__Exception_Log__c objExp = new ElixirSuite__Exception_Log__c();
            objExp.ElixirSuite__Line_Number__c = e.getLineNumber();
            objExp.ElixirSuite__Stack_Trace_Long__c = e.getMessage();
            Insert objExp;
            
        }
        }else if(data != null && Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Generated__c.isUpdateable()){
            data.ElixirSuite__ERA_Generated__c = true;
            Update data;
        }
        }
        else if(data != null && Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Generated__c.isUpdateable()){
            data.ElixirSuite__ERA_Generated__c = true;
            Update data;
        }
    }
    
    public static void secClaimCreation(List<String> secClaimCreationList, List<String> accIdList){
       try{
           system.debug('AAAAAA ');
       Map<String, String> stateAbbreviationMap = new Map<String, String> {
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
                            'Idaho' => 'In', 'In' => 'In',
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
        
        Schema.DescribeSObjectResult result = ElixirSuite__Claim__c.sObjectType.getDescribe();
        List<String> apiNames =  new List<String>(result.fields.getMap().keySet());
        String query = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNames,','))  + ',ElixirSuite__payor__r.ElixirSuite__Payer_Code__c' + ' FROM ElixirSuite__Claim__c ';
        query+= 'WHERE Id IN: secClaimCreationList';
        List<ElixirSuite__Claim__c> listOfClaims = (List<ElixirSuite__Claim__c>)Database.query(query);
        
        Schema.DescribeSObjectResult resultVob = ElixirSuite__VOB__c.sObjectType.getDescribe();
        List<String> apiNamesVob =  new List<String>(resultVob.fields.getMap().keySet());
        String queryVob = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNamesVob,','))  + ' FROM ElixirSuite__VOB__c ';
        queryVob+= 'WHERE ElixirSuite__Account__c IN: accIdList AND ElixirSuite__Status__c = ' +'\''+ 'Active' + '\' AND RecordType.DeveloperName= ' +'\''+ 'Secondary_VOB' + '\''+' Order By CreatedDate Asc';
        List<ElixirSuite__VOB__c> listOfSecIns = (List<ElixirSuite__VOB__c>)Database.query(queryVob);
        
        Map<Id,ElixirSuite__VOB__c> VobMap = new Map<Id,ElixirSuite__VOB__c>();
        for(ElixirSuite__VOB__c ins: listOfSecIns){
          VobMap.put(ins.ElixirSuite__Account__c,ins);
        }
        
        List<ElixirSuite__Claim__c> secClaimInsertionList = new List<ElixirSuite__Claim__c>();
        for(ElixirSuite__Claim__c c: listOfClaims){
          ElixirSuite__Claim__c newClaim = new ElixirSuite__Claim__c();
          newClaim.ElixirSuite__Account__c = c.ElixirSuite__Account__c; 
          newClaim.ElixirSuite__Patient_DOB__c = c.ElixirSuite__Patient_DOB__c;
          newClaim.ElixirSuite__Patient_Name__c = c.ElixirSuite__Patient_Name__c;
          newClaim.ElixirSuite__Patient_Address_2__c = c.ElixirSuite__Patient_Address_2__c;
          newClaim.ElixirSuite__Patient_s_Address_2__c = c.ElixirSuite__Patient_s_Address_2__c;
          newClaim.ElixirSuite__Patient_s_City__c = c.ElixirSuite__Patient_s_City__c;
          newClaim.ElixirSuite__Patient_s_State__c = c.ElixirSuite__Patient_s_State__c;
          newClaim.ElixirSuite__Patient_Country_Code__c = c.ElixirSuite__Patient_Country_Code__c;
          newClaim.ElixirSuite__Patient_Zip_Code__c = c.ElixirSuite__Patient_Zip_Code__c;
          newClaim.ElixirSuite__Patient_s_Phone__c = c.ElixirSuite__Patient_s_Phone__c;
          newClaim.ElixirSuite__Patient_Account_Number__c = c.ElixirSuite__Patient_Account_Number__c;
          newClaim.ElixirSuite__Patient_Sex__c = c.ElixirSuite__Patient_Sex__c;
          if(VobMap != null && VobMap.get(c.ElixirSuite__Account__c) != null){
             String insuredName;
              if((VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_First_Name__c != null) {
               insuredName = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_First_Name__c;    
              }
              if((VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Middle_Name__c != null){
                  insuredName = insuredName +' '+(VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Middle_Name__c;
              }
              if((VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Last_Name__c != null){
                  insuredName = insuredName +' '+(VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Last_Name__c;
              }
          newClaim.ElixirSuite__Insured_s_Name__c =insuredName;
          newClaim.ElixirSuite__Insurance_Type__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insurance_Type__c;   
          newClaim.ElixirSuite__Patient_Relationship_to_Insured__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Patient_Relationship_With_Insured__c;
          newClaim.ElixirSuite__Insured_Address__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Address__c;
          if(stateAbbreviationMap.get((VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_State__c) != null){
          newClaim.ElixirSuite__Insured_State__c = stateAbbreviationMap.get((VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_State__c);
          }else{
          newClaim.ElixirSuite__Insured_State__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_State__c;   
          }
          newClaim.ElixirSuite__Insured_City__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_City__c;
          newClaim.ElixirSuite__Insured_Zip_Code__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Zipcode__c;
          newClaim.ElixirSuite__Insured_Country_Code__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Country__c;
          newClaim.ElixirSuite__Insured_Telephone__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__InsPhone__c;
          newClaim.ElixirSuite__Insured_s_ID_Number__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Member_Id__c;
          newClaim.ElixirSuite__Other_Insured_s_Name__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Other_Insured_s_Name__c;
          newClaim.ElixirSuite__Other_Insured_s_Policy_Group_Number__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Other_Insured_Policy_Group_FECA_Number__c;
          newClaim.ElixirSuite__Other_Insurance_Plan_Name__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__OtherInsurancePlanName__c; 
          newClaim.ElixirSuite__Insured_Policy__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insured_Policy_Group_FECA_Number__c;
          newClaim.ElixirSuite__Insurance_Plan_Name__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Insurance_Plan_Name__c; 
          newClaim.ElixirSuite__Billing_Provider_Tax_ID_Type__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Federal_Tax_ID_Number__c;
          newClaim.ElixirSuite__Insured_DOB__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Date_Of_Birth__c;
          newClaim.ElixirSuite__VOB_lookup__c =  (VobMap.get(c.ElixirSuite__Account__c)).Id; 
          newClaim.ElixirSuite__Insured_Sex__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Gender__c =='Female'? 'F' : 'M';
          newClaim.ElixirSuite__Payor__c = (VobMap.get(c.ElixirSuite__Account__c)).ElixirSuite__Payer__c;
          }
          newClaim.ElixirSuite__Other_Claim_Id__c = c.ElixirSuite__Other_Claim_Id__c;
          newClaim.ElixirSuite__Claim_Codes__c = c.ElixirSuite__Claim_Codes__c; 
          newClaim.ElixirSuite__Diagnosis_A__c = c.ElixirSuite__Diagnosis_A__c;
          newClaim.ElixirSuite__Diagnosis_B__c = c.ElixirSuite__Diagnosis_B__c;
          newClaim.ElixirSuite__Diagnosis_C__c = c.ElixirSuite__Diagnosis_C__c;
          newClaim.ElixirSuite__Diagnosis_D__c = c.ElixirSuite__Diagnosis_D__c;
          newClaim.ElixirSuite__Diagnosis_E__c = c.ElixirSuite__Diagnosis_E__c;
          newClaim.ElixirSuite__Diagnosis_F__c = c.ElixirSuite__Diagnosis_F__c;
          newClaim.ElixirSuite__Diagnosis_G__c = c.ElixirSuite__Diagnosis_G__c;
          newClaim.ElixirSuite__Diagnosis_H__c = c.ElixirSuite__Diagnosis_H__c;
          newClaim.ElixirSuite__Diagnosis_I__c = c.ElixirSuite__Diagnosis_I__c;
          newClaim.ElixirSuite__Diagnosis_J__c = c.ElixirSuite__Diagnosis_J__c;
          newClaim.ElixirSuite__Diagnosis_K__c = c.ElixirSuite__Diagnosis_K__c;
          newClaim.ElixirSuite__Diagnosis_L__c = c.ElixirSuite__Diagnosis_L__c;
          newClaim.ElixirSuite__Additional_Claim_Information__c = c.ElixirSuite__Additional_Claim_Information__c;
          newClaim.ElixirSuite__Insured_Authorized_Person_Signature__c = c.ElixirSuite__Insured_Authorized_Person_Signature__c;
          newClaim.ElixirSuite__Patient_Signature__c = c.ElixirSuite__Patient_Signature__c;
          newClaim.ElixirSuite__Federal_Tax_Id_Number__c = c.ElixirSuite__Federal_Tax_Id_Number__c;
          newClaim.ElixirSuite__Name_of_referring_provider_Other_sourc__c = c.ElixirSuite__Name_of_referring_provider_Other_sourc__c;
                    newClaim.ElixirSuite__Bill_Phone__c=c.ElixirSuite__Bill_Phone__c;
                    newClaim.ElixirSuite__Accept_Assignment__c = c.ElixirSuite__Accept_Assignment__c;
          newClaim.ElixirSuite__Reserved_For_NUCC_Use3__c = c.ElixirSuite__Reserved_For_NUCC_Use3__c;
          newClaim.ElixirSuite__Sign_of_Phy_or_Supplier_Signature__c = c.ElixirSuite__Sign_of_Phy_or_Supplier_Signature__c;
                    newClaim.ElixirSuite__Reserved_For_NUCC_Use1__c = c.ElixirSuite__Reserved_For_NUCC_Use1__c;
          newClaim.ElixirSuite__Reserved_For_NUCC_Use2__c = c.ElixirSuite__Reserved_For_NUCC_Use2__c;
          newClaim.ElixirSuite__NPI__c = c.ElixirSuite__NPI__c;
          newClaim.ElixirSuite__QUAL_For_Date_current_illness_injury__c = c.ElixirSuite__QUAL_For_Date_current_illness_injury__c; 
          newClaim.ElixirSuite__QUAL_For_Other_Dates__c = c.ElixirSuite__QUAL_For_Other_Dates__c;
          newClaim.ElixirSuite__NUCC__c = c.ElixirSuite__NUCC__c;
          newClaim.ElixirSuite__NUCC_Description__c = c.ElixirSuite__NUCC_Description__c;
          newClaim.ElixirSuite__Outside_Lab_new__c =c.ElixirSuite__Outside_Lab_new__c;
          newClaim.ElixirSuite__Outside_Lab_Charges__c =c.ElixirSuite__Outside_Lab_Charges__c;
          newClaim.ElixirSuite__QUAL_For_Name_of_referring_provider__c = c.ElixirSuite__QUAL_For_Name_of_referring_provider__c;
          newClaim.ElixirSuite__First_Name_NAME_OF_REFERRING_PROVIDER__c = c.ElixirSuite__First_Name_NAME_OF_REFERRING_PROVIDER__c;
          newClaim.ElixirSuite__Last_Name_NAME_OF_REFERRING_PROVIDER__c = c.ElixirSuite__Last_Name_NAME_OF_REFERRING_PROVIDER__c;
          newClaim.ElixirSuite__MiddleName_NAME_OF_REFERRING_PROVIDER__c = c.ElixirSuite__MiddleName_NAME_OF_REFERRING_PROVIDER__c;
          //newClaim.ElixirSuite__Prior_Authorization_Number__c = c.ElixirSuite__Prior_Authorization_Number__c;
          //newClaim.ElixirSuite__Resubmission_Code__c = c.ElixirSuite__Resubmission_Code__c;
          //newClaim.ElixirSuite__Original_Ref_No__c = c.ElixirSuite__Original_Ref_No__c;
          newClaim.ElixirSuite__Hospitalization_From_Date__c = c.ElixirSuite__Hospitalization_From_Date__c;
          newClaim.ElixirSuite__Hospitalization_To_Date__c = c.ElixirSuite__Hospitalization_To_Date__c;
          newClaim.ElixirSuite__Sign_of_Phy_or_Supplier_Date__c = c.ElixirSuite__Sign_of_Phy_or_Supplier_Date__c;
          newClaim.ElixirSuite__From_Date_Patient_Unable_To_Work__c = c.ElixirSuite__From_Date_Patient_Unable_To_Work__c;
          newClaim.ElixirSuite__To_Date_Patient_Unable_To_Work__c = c.ElixirSuite__To_Date_Patient_Unable_To_Work__c;
          newClaim.ElixirSuite__Patient_Condition_Related_To_Employment__c = c.ElixirSuite__Patient_Condition_Related_To_Employment__c;
          newClaim.ElixirSuite__Patient_Condition_Related_To_Accident__c = c.ElixirSuite__Patient_Condition_Related_To_Accident__c;
          newClaim.ElixirSuite__Patient_Condition_to_Other_Accident__c = c.ElixirSuite__Patient_Condition_to_Other_Accident__c;
          newClaim.ElixirSuite__Any_Other_Health_Benefit_Plan__c = c.ElixirSuite__Any_Other_Health_Benefit_Plan__c;
          newClaim.ElixirSuite__Date_Of_Current_Illness__c = c.ElixirSuite__Date_Of_Current_Illness__c;
          newClaim.ElixirSuite__Hospitalization_Dates__c = c.ElixirSuite__Hospitalization_Dates__c;
          newClaim.ElixirSuite__Other_Date__c = c.ElixirSuite__Other_Date__c;
          newClaim.ElixirSuite__Dates_Patient_Unable_To_Work__c = c.ElixirSuite__Dates_Patient_Unable_To_Work__c;
          newClaim.ElixirSuite__Amount_Paid__c = c.ElixirSuite__Amount_Paid__c;
          newClaim.ElixirSuite__Total_Charge__c = c.ElixirSuite__Total_Charge__c;
          //newClaim.ElixirSuite__Insured_Or_Auth_Persn_Date__c = c.ElixirSuite__Insured_Or_Auth_Persn_Date__c;
          //newClaim.ElixirSuite__Auto_Accident_Related__c = c.ElixirSuite__Auto_Accident_Related__c;
          newClaim.ElixirSuite__Claim_Status__c = 'Ready to Submit';
          newClaim.ElixirSuite__Payer_Order__c = 'Secondary';
          newClaim.ElixirSuite__Claim__c = c.Id;

         //Billing Details
          newClaim.ElixirSuite__Billing_Provider_Other_ID__c = c.ElixirSuite__Billing_Provider_Other_ID__c;
          newClaim.ElixirSuite__Billing_Provider_Info__c = c.ElixirSuite__Billing_Provider_Info__c;
          newClaim.ElixirSuite__Billing_Provider_Name__c =c.ElixirSuite__Billing_Provider_Name__c;   
          newClaim.ElixirSuite__Billing_Provider_Address_1__c=c.ElixirSuite__Billing_Provider_Address_1__c;
          newClaim.ElixirSuite__Billing_Provider_Address_2__c=c.ElixirSuite__Billing_Provider_Address_2__c;
          newClaim.ElixirSuite__Billing_Provider_City__c=c.ElixirSuite__Billing_Provider_City__c;
          newClaim.ElixirSuite__Billing_Provider_State__c=c.ElixirSuite__Billing_Provider_State__c;
          newClaim.ElixirSuite__Billing_Provider_Zip__c=c.ElixirSuite__Billing_Provider_Zip__c;
          newClaim.ElixirSuite__Billing_Provider_Tax_ID__c=c.ElixirSuite__Billing_Provider_Tax_ID__c;
          newClaim.ElixirSuite__Billing_Provider_Taxonomy__c = c.ElixirSuite__Billing_Provider_Taxonomy__c;
          newClaim.ElixirSuite__Billing_Provider_Info_NPI__c = c.ElixirSuite__Billing_Provider_Info_NPI__c;  
            
          //Service Details
           newClaim.ElixirSuite__Service_Facility_Location_NPI__c = c.ElixirSuite__Service_Facility_Location_NPI__c;
           newClaim.ElixirSuite__Service_Facility_Location_Information__c = c.ElixirSuite__Service_Facility_Location_Information__c;
           newClaim.ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c = c.ElixirSuite__Servic_Fcility_Loc_Informaton_OtherID__c;
           newClaim.ElixirSuite__Service_Facility_Loc_Address__c = c.ElixirSuite__Service_Facility_Loc_Address__c; 
           newClaim.ElixirSuite__Service_Facility_Address_2__c = c.ElixirSuite__Service_Facility_Address_2__c;
           newClaim.ElixirSuite__Service_Facility_Loc_City__c = c.ElixirSuite__Service_Facility_Loc_City__c;
           newClaim.ElixirSuite__Service_Facility_Loc_State__c = c.ElixirSuite__Service_Facility_Loc_State__c;
           newClaim.ElixirSuite__Service_Facility_Loc_Zip__c = c.ElixirSuite__Service_Facility_Loc_Zip__c;
            
          //Rendering Details
           newClaim.ElixirSuite__Rendering_Provider_First_Name__c = c.ElixirSuite__Rendering_Provider_First_Name__c;
           newClaim.ElixirSuite__Rendering_Provider_Last_Name__c = c.ElixirSuite__Rendering_Provider_Last_Name__c;
           newClaim.ElixirSuite__Rendering_Provider_Taxonomy__c = c.ElixirSuite__Rendering_Provider_Taxonomy__c ;
           newClaim.ElixirSuite__Rendering_Provider_NPI__c = c.ElixirSuite__Rendering_Provider_NPI__c;
           newClaim.ElixirSuite__Rendering_Provider_Tax_Id__c = c.ElixirSuite__Rendering_Provider_Tax_Id__c;
           newClaim.ElixirSuite__Rendering_Provider_Address__c = c.ElixirSuite__Rendering_Provider_Address__c;
            
           //Care Episode Lookup
            newClaim.ElixirSuite__Visits__c = c.ElixirSuite__Visits__c;
            
            
          secClaimInsertionList.add(newClaim);
        }
        system.debug('AAAAAA ');
        if(secClaimInsertionList != null && secClaimInsertionList.size() > 0){
           insert secClaimInsertionList;
        }
        
        Map<String,String> priClaimVSSecClaim = new Map<String,String>(); 
        for(ElixirSuite__Claim__c cd:secClaimInsertionList){
           priClaimVSSecClaim.put(cd.ElixirSuite__Claim__c,cd.Id);
        }
        
        Schema.DescribeSObjectResult resultCL = ElixirSuite__Claim_Line_Items__c.sObjectType.getDescribe();
        List<String> apiNamesCL =  new List<String>(resultCL.fields.getMap().keySet());
        String queryCL = 'SELECT ' +String.escapeSingleQuotes(String.join(apiNamesCL,','))  + ' FROM ElixirSuite__Claim_Line_Items__c ';
        queryCL+= 'WHERE ElixirSuite__Claim__c IN: secClaimCreationList';
        List<ElixirSuite__Claim_Line_Items__c> listOfClaimLineItems = (List<ElixirSuite__Claim_Line_Items__c>)Database.query(queryCL);
        system.debug('AAAAAA ');
        List<ElixirSuite__Claim_Line_Items__c> InsertionClaimLineItemsList = new List<ElixirSuite__Claim_Line_Items__c>();
        for(ElixirSuite__Claim_Line_Items__c rec:listOfClaimLineItems){
            ElixirSuite__Claim_Line_Items__c newClaimLineItem = new  ElixirSuite__Claim_Line_Items__c();
            if(priClaimVSSecClaim != null && priClaimVSSecClaim.get(rec.ElixirSuite__Claim__c) != null){
                newClaimLineItem.ElixirSuite__Claim__c = priClaimVSSecClaim.get(rec.ElixirSuite__Claim__c);
            }
            newClaimLineItem.ElixirSuite__Claim_Procedure_Line_Item__c = rec.Id;
            newClaimLineItem.ElixirSuite__EMG__c = rec.ElixirSuite__EMG__c;
            newClaimLineItem.ElixirSuite__Place_of_Service__c = rec.ElixirSuite__Place_of_Service__c;
            newClaimLineItem.ElixirSuite__Place_of_Service_Code_s__c = rec.ElixirSuite__Place_of_Service_Code_s__c;
            newClaimLineItem.ElixirSuite__Modifier_1__c = rec.ElixirSuite__Modifier_1__c;
            newClaimLineItem.ElixirSuite__Modifier_2__c = rec.ElixirSuite__Modifier_2__c;
            newClaimLineItem.ElixirSuite__Modifier_3__c = rec.ElixirSuite__Modifier_3__c;
            newClaimLineItem.ElixirSuite__Modifier_4__c = rec.ElixirSuite__Modifier_4__c;
            newClaimLineItem.ElixirSuite__Diagnosis_Pointer__c = rec.ElixirSuite__Diagnosis_Pointer__c;
            newClaimLineItem.ElixirSuite__Procedure_Charge__c = rec.ElixirSuite__Procedure_Charge__c;
            newClaimLineItem.ElixirSuite__Days_Units__c = rec.ElixirSuite__Days_Units__c;
            newClaimLineItem.ElixirSuite__Family_Plan__c = rec.ElixirSuite__Family_Plan__c;
            newClaimLineItem.ElixirSuite__EPSTD__c = rec.ElixirSuite__EPSTD__c;
            newClaimLineItem.ElixirSuite__ID_Qual__c = rec.ElixirSuite__ID_Qual__c;
                        newClaimLineItem.ElixirSuite__CPT_HCPCS_Code__c =  rec.ElixirSuite__CPT_HCPCS_Code__c;                                                           
            newClaimLineItem.ElixirSuite__Procedure__c= rec.ElixirSuite__Procedure__c;
            newClaimLineItem.ElixirSuite__From_Date_Of_Service__c = rec.ElixirSuite__From_Date_Of_Service__c;
            newClaimLineItem.ElixirSuite__To_Date_Of_Service__c = rec.ElixirSuite__To_Date_Of_Service__c;

            //Rendering Information
            newClaimLineItem.ElixirSuite__Rendering_Provider_First_Name__c = rec.ElixirSuite__Rendering_Provider_First_Name__c;
            newClaimLineItem.ElixirSuite__Rendering_Provider_Last_Name__c = rec.ElixirSuite__Rendering_Provider_Last_Name__c;
            newClaimLineItem.ElixirSuite__Rendering_Provider_Taxonomy__c = rec.ElixirSuite__Rendering_Provider_Taxonomy__c;
            newClaimLineItem.ElixirSuite__Rendering_Provider_NPI__c = rec.ElixirSuite__Rendering_Provider_NPI__c;
            newClaimLineItem.ElixirSuite__Rendering_Provider_Non_NPI__c = rec.ElixirSuite__Rendering_Provider_Non_NPI__c;
            newClaimLineItem.ElixirSuite__Rendering_Provider_Address__c = rec.ElixirSuite__Rendering_Provider_Address__c;
            
            InsertionClaimLineItemsList.add(newClaimLineItem);
        }
        if(InsertionClaimLineItemsList != null && InsertionClaimLineItemsList.size() > 0){
           insert InsertionClaimLineItemsList;
        }
           system.debug('AAAAAA ');
       }catch(Exception e){
           ElixirSuite__Exception_Log__c objExp = new ElixirSuite__Exception_Log__c();
           objExp.ElixirSuite__Line_Number__c = e.getLineNumber();
           objExp.ElixirSuite__Stack_Trace_Long__c = e.getMessage();
           Insert objExp;
          System.debug('exception '+e); 
       }
    }
    
    private static void identifyDeniedClaims(List<Object> claims, Map<String,Boolean> claimStatusIfDenied){
        if(claims!=null){
             String orgsId = (UserInfo.getOrganizationId()).toUpperCase();
             System.debug('Organization ID: ' + orgsId);
            for(Object claimRec : claims){    
                Map<String, Object> era = 
                    (Map<String, Object>) claimRec;
                 String pcn ;
                if(String.valueOf(era.get('pcn')).containsIgnoreCase(orgsId)){
                pcn = (String.valueOf(era.get('pcn'))).substringBefore(orgsId);
                }else{
                pcn = (String.valueOf(era.get('pcn')));    
                }
               /* if(pcn.startsWithIgnoreCase('claim')){
                    if(!pcn.contains('-')){
                        Integer index1 = pcn.toLowerCase().lastIndexOf('m');
                        String numVal = pcn.subString(index1+1,pcn.length());
                        String claimNameKey = 'Claim'+'-'+numVal;
                        pcn = claimNameKey;
                        claimStatusIfDenied.put(claimNameKey,false);
                    }
                    else{*/
                        claimStatusIfDenied.put(pcn,false);
                  //  }
               // }
                List<Object> charges = (List<Object>) era.get('charge');
                for(Object eraLineItemRec :charges){
                    Map<String, Object> charge = (Map<String, Object>) eraLineItemRec;
                    if(((String)charge.get('allowed')) != null && ((String)charge.get('allowed')) != '' && String.isNotBlank((String)charge.get('allowed'))){
                        Decimal allowedAmt = Decimal.valueOf((String)charge.get('allowed')); 
                        if(allowedAmt == 0 || allowedAmt == 0.0){
                            claimStatusIfDenied.put(pcn,true);
                        }
                    }
                }
            }
        }
    }
    
    public static String generateBodyUsingRecursion(String finalJson, Dom.XMLNode root){
        
        if ( root.getNodeType() == Dom.XmlNodeType.ELEMENT ){     
            finalJson += '"' + root.getName() + '":[{' ;
            system.debug('&&&'+finalJson);
            List<String> resultAttributes = new List<String>();
            for(Integer i=0;i<root.getAttributeCount();i++){ 
                String key = root.getAttributeKeyAt(i);
                String value = root.getAttribute( key, '' );
                resultAttributes.add( '"' + key + '": "' + value + '"' ); 
            }
            if(resultAttributes.size()>0){
                finalJson += String.join(resultAttributes,',');
            }
            if(root.getChildElements()!=null && root.getChildElements().size()>0){
                finalJson += ',"' + root.getChildElements()[0].getName() + '":' + '[' ;  
                String secondLevel = '';
                Integer count = 0;
                for(Dom.XMLNode child :root.getChildElements()){
                    count++;
                    secondLevel += '{';
                    List<String> secondLevelAttributes = new List<String>();
                    for(Integer i=0;i<child.getAttributeCount();i++){ 
                        String key = child.getAttributeKeyAt(i);
                        String value = child.getAttribute( key, '' );
                        secondLevelAttributes.add( '"' + key + '": "' + value + '"' ); 
                    }
                    if(resultAttributes.size()>0){
                        secondLevel += String.join(secondLevelAttributes,',');
                    }
                    
                    if(child.getChildElements()!=null && child.getChildElements().size()>0){
                        secondLevel += ',"' + child.getChildElements()[0].getName() + '":' + '[' ;  
                        String thirdLevel = '';
                        Integer thirdCount = 0;
                        for(Dom.XMLNode thirdChild :child.getChildElements()){
                            thirdCount++;
                            thirdLevel += '{';
                            List<String> thirdLevelAttributes = new List<String>();
                            for(Integer i=0;i<thirdChild.getAttributeCount();i++){ 
                                String key = thirdChild.getAttributeKeyAt(i);
                                String value = thirdChild.getAttribute( key, '' );
                                thirdLevelAttributes.add( '"' + key + '": "' + value + '"' ); 
                            }
                            if(thirdLevelAttributes.size()>0){
                                thirdLevel += String.join(thirdLevelAttributes,',');   
                            }                  
                           
							//Adjustments START
                            if(thirdChild.getChildElements()!=null && thirdChild.getChildElements().size()>0){
                                thirdLevel += ',"' + thirdChild.getChildElements()[0].getName() + '":' + '[' ;  
                                String fourthLevel = '';
                                Integer fourthCount = 0;
                                 List<String> remarkCodes = new List<String>();
                                for(Dom.XMLNode fourthChild :thirdChild.getChildElements()){
                                    fourthCount++;
                                    fourthLevel += '{';
                                    List<String> fourthLevelAttributes = new List<String>();
                                    for(Integer i=0;i<fourthChild.getAttributeCount();i++){ 
                                        String key = fourthChild.getAttributeKeyAt(i);
                                        String value = fourthChild.getAttribute( key, '' );
                                        fourthLevelAttributes.add( '"' + key + '": "' + value + '"' ); 
                                    }
                                    if(fourthLevelAttributes.size()>0){
                                        fourthLevel += String.join(fourthLevelAttributes,',');                                    
                                    }
                                    fourthLevel += '}';
                                    if(thirdChild.getChildElements().size() != fourthCount){
                                        fourthLevel += ',';
                                    }
                                    // added by Jami to handle the Remarks codes : LX3-10605
                                    if (fourthChild.getName() == 'remark_code') {
                                    remarkCodes.add(fourthChild.getText());
                                }

                                }
                                thirdLevel += fourthLevel;
                                thirdLevel += ']';
                                //Adjustments END
                                // added by Jami to handle the Remarks codes : LX3-10605
                                 if (!remarkCodes.isEmpty()) {
                                thirdLevel += ',"remark_code": ' + JSON.serialize(remarkCodes) + '';
                            }
                            }
                            thirdLevel += '}';
                            if(child.getChildElements().size() != thirdCount){
                                thirdLevel += ',';
                            }
                        }
                        secondLevel += thirdLevel;
                        secondLevel += ']';
                    }//         
                    secondLevel += '}';
                    if(root.getChildElements().size() != count){
                        secondLevel += ',';
                    }
                }
                finalJson += secondLevel;
                finalJson += ']';
            }
            finalJson += '}]';            
        }
        return finalJson;
    }
    
    
}
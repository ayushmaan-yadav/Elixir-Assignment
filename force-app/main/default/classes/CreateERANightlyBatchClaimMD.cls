public with sharing class CreateERANightlyBatchClaimMD implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new GetERABatchHandler());
        
    }
    Public static Integration_Credentials__c getCredentials(){
		return [SELECT Id, Integration_Key__c 
            FROM Integration_Credentials__c WHERE Name='ClaimMD' WITH SECURITY_ENFORCED];
        
    }
    
    @AuraEnabled
    public static void entryPointCallout(){
        List<ElixirSuite__Integration_Data__c> integrationOrder = [SELECT Id,ElixirSuite__Integration_Data__c,ElixirSuite__Posted__c,ElixirSuite__ERA_Id__c
                                                    FROM ElixirSuite__Integration_Data__c 
                                                    WHERE ElixirSuite__Integration_Data__c=NULL AND ElixirSuite__ERA_Id__c!=NULL AND ElixirSuite__Posted__c=false 
                                                    WITH SECURITY_ENFORCED
                                                    ORDER BY CreatedDate DESC];
      
        Integration_Credentials__c custset = getCredentials();
        
        if(String.isBlank(custset.Integration_Key__c )){
            return;
        }

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
                //throw new AuraHandledException('No ERA found!!');
            }
    }
   public static void setIntegrationData(String parentJson, String finalJson){
        Map<String, Object> LastERAresults = (Map<String, Object>)JSON.deserializeUntyped(parentJson);
        Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(finalJson);
        List<Object> lastERAIdlist = (List<Object>)LastERAresults.get('last_eraid');
        List<Object> lstCustomers = (List<Object>)results.get('claim');
        system.debug('lastERAIdlist--'+lastERAIdlist);
        system.debug('lstCustomers--'+lstCustomers);
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
               system.debug('Intdatalist--'+Intdatalist);
               
           }
        Database.executeBatch(new GetERAClaimMDBatch(),1);
    }
    
}
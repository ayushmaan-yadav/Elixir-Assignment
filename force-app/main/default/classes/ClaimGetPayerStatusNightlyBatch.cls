/*Author name           :  
* Purpose               :  To automatically get payer response
* Schedule              :  Scheduling on daily basis
* Test Class            :  
* Schedular class       :  
*/
public with sharing class ClaimGetPayerStatusNightlyBatch implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        
        List<ElixirSuite__Elixir_Pluggable_Classes__mdt> pluggableClass = new List<ElixirSuite__Elixir_Pluggable_Classes__mdt>();
        String virtualClassName;
        if(
            ElixirSuite__Elixir_Pluggable_Classes__mdt.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.ElixirSuite__Elixir_Pluggable_Classes__mdt.fields.DeveloperName.isAccessible() &&
            Schema.SObjectType.ElixirSuite__Elixir_Pluggable_Classes__mdt.fields.ElixirSuite__Virtual_Class__c.isAccessible()
        ) {
        pluggableClass = [SELECT DeveloperName,ElixirSuite__Virtual_Class__c FROM ElixirSuite__Elixir_Pluggable_Classes__mdt WHERE DeveloperName='NewClaimMDIntegration'];
        }
        if(pluggableClass != null && !pluggableClass.isEmpty()){
            
            virtualClassName = pluggableClass[0].ElixirSuite__Virtual_Class__c;
            
        }
        if(virtualClassName != '' && virtualClassName !=null){
        System.enqueueJob(new ClaimGetPayerStatusNightlyHandler());
        }
     
    }
    
   public static void entryPointCallout(){
        
        List<ElixirSuite__Integration_Data__c> integrationOrder = [SELECT Id,ElixirSuite__Integration_Data__c,ElixirSuite__Posted__c,ElixirSuite__Last_Response_Id__c
                                                      FROM ElixirSuite__Integration_Data__c  
                                                      WHERE ElixirSuite__Type__c='Payer response' AND ElixirSuite__Posted__c=false 
                                                      WITH SECURITY_ENFORCED
                                                      ORDER BY CreatedDate DESC];
        
        String responseId;  
        ElixirSuite__Integration_Data__c intData;
        if(integrationOrder.size()>0 && integrationOrder != null && integrationOrder[0].ElixirSuite__Last_Response_Id__c != null){
            intData = integrationOrder[0];    
            responseId=integrationOrder[0].ElixirSuite__Last_Response_Id__c;
        }
        String endPoint;
       
        String accKey;
        Integration_Credentials__c custset;        
        custset = [SELECT Id, Integration_Key__c 
        FROM Integration_Credentials__c WHERE Name='ClaimMD' WITH SECURITY_ENFORCED];
        accKey = custset.Integration_Key__c;
        if(String.isBlank(accKey)){
            return;
        }
        if(responseId != Null && responseId == ''){
            endPoint='callout:Claim_MD/services/response/?AccountKey='+ accKey+'&ResponseID='+responseId;
        }
        else{
            endPoint='callout:Claim_MD/services/response/?AccountKey='+ accKey+'&ResponseID=0';
        }
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','text/html; charset=UTF-8');        
        req.setMethod('GET');
        req.setEndPoint(endPoint);
        Http http = new Http();
        HttpResponse response = http.send(req);
        if(response.getStatusCode() == 200){
            PayerJsonResponse pjResponse = new PayerJsonResponse();
            pjResponse.claimUpdation(response.getBody(),integrationOrder);
        }
        
    }
    
    public with sharing  class PayerJsonResponse{
        
        public List<Claim> claim;
       
        public PayerJsonResponse parse(String json) {
            
            return (PayerJsonResponse) System.JSON.deserialize(json, PayerJsonResponse.class);
        }
        public void claimUpdation(String xml,List<ElixirSuite__Integration_Data__c> integrationOrder){
            String orgId = (UserInfo.getOrganizationId()).toUpperCase();
            String jsonContent = XMLResponseParserClaimMD.xmlToJson(xml);
            String jsonParentContent = XMLResponseParserClaimMD.xmlToJsonParent(xml);
            PayerJsonResponse jsonResp = parse(jsonContent);
            List<Claim> claimList=jsonResp.claim;
            if(jsonParentContent != null){
                Map<String, Object> lastResponseIdresults = (Map<String, Object>)JSON.deserializeUntyped(jsonParentContent);
                List<Object> lastResponseIdList = (List<Object>)lastResponseIdresults.get('last_responseid');
                Map<String, Object> lastResponseId;
                for(Object result : lastResponseIdList) {
                    lastResponseId = (Map<String, Object>)result;
                }
                ElixirSuite__Integration_Data__c intParentData;
                intParentData = new ElixirSuite__Integration_Data__c();
                if(lastResponseId.get('last_responseid')!= null){
                    intParentData.ElixirSuite__Last_Response_Id__c = string.valueOf(lastResponseId.get('last_responseid'));
                    intParentData.ElixirSuite__Type__c = 'Payer response';
                }
                if(intParentData!=null &&
                   Schema.sObjectType.ElixirSuite__Integration_Data__c.isCreateable() &&
                   Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__ERA_Id__c.isCreateable() &&
                   Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Last_Response_Id__c.isCreateable() &&
                   Schema.sObjectType.ElixirSuite__Integration_Data__c.fields.ElixirSuite__Type__c.isCreateable()){
                       insert intParentData;
                   }
                if(lastResponseId.get('last_responseid')!= null && integrationOrder.size() > 0 && integrationOrder != null){
                    ElixirSuite__Integration_Data__c intData1;
                    intData1 = integrationOrder[0];
                    intData1.ElixirSuite__Posted__c  = true;
                    if(ElixirSuite__Integration_Data__c.SObjectType.getDescribe().isUpdateable() ) {
                           update intData1;
        }
                 }
            }
            DateTime latestResponse;
            Set<String> claimId = new Set<String>();
            for(Claim c : claimList){
               /* if(String.isNotBlank(c.remote_claimid)){
                    ClaimId.add(c.remote_claimid);
                }*/
                if(String.isNotBlank(c.remote_claimid)){
                    string pcn = c.pcn;
                    if(pcn.containsIgnoreCase(orgId)){
                    string rmtclaimId = c.remote_claimid;
                    String[] parts = rmtclaimId.split(';');
                    if(parts != null && parts[0]!=null){
                        String firstPart = parts[0];
                        claimId.add(firstPart);
                     }
                     }else{
                        claimId.add(c.remote_claimid);  
                     }
                }
                Datetime currentTime = convertDateTime(c.response_time);
                if(latestResponse==null || currentTime>latestResponse){
                    latestResponse  = currentTime;
                }
            }
            List<ElixirSuite__Claim__c> toUpdateClaims = [SELECT Id,Name, ElixirSuite__Claimid__c, ElixirSuite__Claim_Md_Id__c, ElixirSuite__Batch_Id__c, ElixirSuite__bill_taxid__c, ElixirSuite__fdos__c, ElixirSuite__Message__c,
                                             ElixirSuite__Insurance_Number__c, ElixirSuite__Payer_ID__c, ElixirSuite__Pcn__c, ElixirSuite__Sender_Icn__c, ElixirSuite__Sender_Name__c, ElixirSuite__Sender_Id__c,
                                             ElixirSuite__Claim_Status__c from ElixirSuite__Claim__c WHERE Name IN :ClaimId WITH SECURITY_ENFORCED];
            
            Map<String, ElixirSuite__Claim__c> claimsToUpdate = new Map<String,ElixirSuite__Claim__c>();
            for(ElixirSuite__Claim__c claim :toUpdateClaims){
                claimsToUpdate.put(claim.Name.toLowerCase(),claim);
            }
            
            set<ElixirSuite__Claim__c> finalClaims = new Set<ElixirSuite__Claim__c>();
            Map<String,ContentDocumentLink> mapcontdoc = new Map<String,ContentDocumentLink>();
            Map<String,String> mapcontver = new Map<String,String>();
            List<ContentVersion> contentDoc = new List<ContentVersion>();
            for(Claim c : claimList){
                 string rmtclaimId = c.remote_claimid;
                String[] parts = rmtclaimId.split(';');
                String firstPart = parts[0];
                if(String.isNotBlank(firstPart) && claimsToUpdate.containsKey(firstPart.toLowerCase()) && c.remote_claimid.contains(';')){
                    ElixirSuite__Claim__c cu = claimsToUpdate.get(firstPart.toLowerCase());
                  //  DateTime currentTime = convertDateTime(c.response_time);
                    
                    if(c.status == 'A'){
                        cu.ElixirSuite__Claim_Status__c = 'Payer Accepted';
                        cu.ElixirSuite__Message__c = '';
                    }
                    else if(c.status == 'R'){
                        cu.ElixirSuite__Claim_Status__c = 'Payer Rejected';
                        cu.ElixirSuite__Message__c=JSON.Serialize(c.messages);
                    }
                    cu.ElixirSuite__Sender_icn__c = c.sender_icn;
                    finalClaims.add(cu);
                    
                    //Payer Request Insertion 
                       
                        String title = 'ResponsePayer'+firstPart+'.txt';
                        string responseFile = string.valueof(c);    
                        ContentVersion docVer = New ContentVersion();   
                        docVer.ContentLocation = 'S';   
                        docVer.PathOnClient = 'ResponsePayer.txt';
                        docVer.Title = 'ResponsePayer'+firstPart+'.txt';//'Request.txt';                   
                        Blob reqData = Blob.valueof(responseFile);   
                        docVer.VersionData = reqData;   
                        contentDoc.add(docVer);
                        mapcontver.put(title,firstPart.toLowerCase());    
                        ContentDocumentLink doclink = New ContentDocumentLink();  
                        doclink.linkedEntityId = cu.id;    
                        doclink.sharetype = 'I';    
                        doclink.visibility = 'AllUsers'; 
                        mapcontdoc.put(firstPart.toLowerCase(),doclink);
                        
                    
                      
                }
                
            }
            if(contentDoc.size()>0 && contentDoc!=null){
                if(
                   Schema.sObjectType.ContentVersion.isCreateable() ){
                insert contentDoc;
                   }
            }
            List<String> cdIds = new List<String>();
            Map<String,Id> mapcontV = new Map<String,Id>(); 
            for(ContentVersion cd:contentDoc){
                cdIds.add(cd.Id);
            }
            
            List<ContentVersion> cdversion = [Select Title,ContentDocumentid from ContentVersion where id IN: cdIds WITH SECURITY_ENFORCED];
            
            for(ContentVersion cv:cdversion){
                mapcontV.put(mapcontver.get(cv.Title),cv.ContentDocumentid);
            }
            
            List<ContentDocumentLink> contList = new List<ContentDocumentLink>();
            for(String contstr : mapcontdoc.keySet()){
                ContentDocumentLink doclink = mapcontdoc.get(contstr);
                doclink.ContentDocumentId = mapcontV.get(contstr.toLowerCase());
                contList.add(doclink);
            }
            if(contList.size()>0 && contList!=null){
                if(
                   Schema.sObjectType.ContentDocumentLink.isCreateable() ){
                insert contList;
                   }
            }
            List<ElixirSuite__Claim__c> finalClaimsSet = new List<ElixirSuite__Claim__c>(finalClaims);
            
            try{
                if(Schema.sObjectType.ElixirSuite__Claim__c.isUpdateable() &&
                   Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Message__c.isUpdateable() && finalClaimsSet.size()>0 && finalClaimsSet != null) {
                 
                       update finalClaimsSet;
                   }
            }
            catch(Exception ex)
            {
                String exceptionText = ex.getMessage();
                if(String.isNotBlank(exceptionText) && exceptionText.length()>255){
                    exceptionText = exceptionText.substring(0,255);
                }
                ElixirSuite__Exception_Log__c exce = new ElixirSuite__Exception_Log__c();
                exce.ElixirSuite__Line_Number__c = ex.getLineNumber();
                exce.ElixirSuite__Message__c = exceptionText;
                exce.ElixirSuite__Stack_Trace_Long__c = ex.getStackTraceString();
                if(Schema.sObjectType.ElixirSuite__Exception_Log__c.isCreateable() ){
                insert exce;
           }

            }
        }
        
        public DateTime convertDateTime(String respTime)
        {
          //  String finalStr = '';	
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
            return Datetime.newInstanceGMT(year, month, day, hour, minute, second);
        }
        
    }
    public class Messages {
        public String fields;
        public String mesgid;
        public String message;
        public String status;
    }
    public class Claim {
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
   
    
    
}
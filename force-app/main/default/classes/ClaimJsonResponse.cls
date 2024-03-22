public with sharing class ClaimJsonResponse {
    
    public static Boolean eraReceived = false;
    public static Map<Id,Boolean> isDenied = new Map<Id,Boolean>();    
    public class Messages {
        public String fields;
        public String mesgid;
        public String message;
        public String status; 
    }
    
    public List<Claim> claim;
    
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
        public String error_code;
        public String error_mesg;
        public List<Messages> messages;
    }
    
    
    public static ClaimJsonResponse parse(String json) {
        return (ClaimJsonResponse) System.JSON.deserialize(json, ClaimJsonResponse.class);
    }
    
    public static void ClaimUpdation(String xml){
        ClaimJsonResponse JSONCompiledResponse ;
        String jsonContent = XMLResponseParserClaimMD.xmlToJson(xml);
        try{
        
            JSONCompiledResponse = ClaimJsonResponse.parse(jsonContent);  
            String orgId = (UserInfo.getOrganizationId()).toUpperCase();
        List<Claim> claimList=JSONCompiledResponse.claim;
        Set<String> ClaimId = new Set<String>();
        for(Claim c : claimList){
           /* if(String.isNotBlank(c.remote_claimid)){
                ClaimId.add(c.remote_claimid);
            }*/
             if(String.isNotBlank(c.remote_claimid)){
                string pcn = c.pcn.toUpperCase();
                System.debug('pcn '+pcn);
                
                 if(pcn.containsIgnoreCase(orgId)){
                     system.debug('aaaa');
                     string rmtclaimId = c.remote_claimid.toUpperCase();
                     String[] parts = rmtclaimId.split(';');
                     if(parts != null && parts[0]!=null){
                        system.debug('aaaa');
                          String firstPart = parts[0];
                         ClaimId.add(firstPart);
                     }
                 }else{
                    system.debug('aaaa 111111');
                     ClaimId.add(c.remote_claimid);   
                 }
            }
        }
        system.debug('ClaimId '+ClaimId);
        List<ElixirSuite__Claim__c> toUpdateClaims = [SELECT Id,Name, ElixirSuite__Claimid__c, ElixirSuite__Claim_Md_Id__c, ElixirSuite__Batch_Id__c, ElixirSuite__bill_taxid__c, ElixirSuite__fdos__c, ElixirSuite__Message__c,
                                        ElixirSuite__Insurance_Number__c, ElixirSuite__Payer_ID__c, ElixirSuite__Pcn__c, ElixirSuite__Sender_Icn__c, ElixirSuite__Sender_Name__c, ElixirSuite__Sender_Id__c,
                                        ElixirSuite__Claim_Status__c from ElixirSuite__Claim__c WHERE Name IN :ClaimId WITH SECURITY_ENFORCED];
        Map<String, ElixirSuite__Claim__c> claimsToUpdate = new Map<String,ElixirSuite__Claim__c>();
        for(ElixirSuite__Claim__c claim :toUpdateClaims){
            claimsToUpdate.put(claim.Name.toLowerCase(),claim);
        }
        List<ElixirSuite__Claim__c> finalClaims = new List<ElixirSuite__Claim__c>();
            Map<String,ContentDocumentLink> mapcontdoc = new Map<String,ContentDocumentLink>();
            Map<String,String> Mapcontver = new Map<String,String>();
            List<ContentVersion> ContentDoc = new List<ContentVersion>();
        for(Claim c : claimList){
            string rmtclaimId = c.remote_claimid.toLowerCase();
                String[] parts = rmtclaimId.split(';');
                String firstPart = parts[0];
            
            if(String.isNotBlank(firstPart) && claimsToUpdate.containsKey(firstPart)){
                ElixirSuite__Claim__c cu = claimsToUpdate.get(firstPart);
                cu.ElixirSuite__Claimid__c = firstPart;
                cu.ElixirSuite__Claim_Md_Id__c = c.claimmd_id;
                cu.ElixirSuite__Batch_Id__c = c.batchid;
                cu.ElixirSuite__fdos__c = c.fdos;
                cu.ElixirSuite__Insurance_Number__c = c.ins_number;
                cu.ElixirSuite__Payer_ID__c = c.payerid;
                if(String.isNotBlank(c.sender_icn)){
                    cu.ElixirSuite__Sender_Icn__c = c.sender_icn;
                }
                system.debug('sender_icn '+c.sender_icn);
                cu.ElixirSuite__Sender_Name__c = c.sender_name;
                cu.ElixirSuite__Sender_Id__c = c.senderid;
                cu.ElixirSuite__Message__c = JSON.serialize(c.messages);
                if(c.Status == 'A'){
                    cu.ElixirSuite__Claim_Status__c='Clearing house accepted';
                    cu.ElixirSuite__Message__c = '';
                }
                else{
                    cu.ElixirSuite__Claim_Status__c='Clearing house rejected';
                }
                finalClaims.add(cu);
                
                //Post Claim Response Insertion 
                    try{    
                        String title = 'Response'+firstPart.toUpperCase()+'.txt';
                        string responseFile = string.valueof(c); 
                        system.debug('checkbodyGeneratedstring'+responseFile);   
                        ContentVersion docVer = New ContentVersion();   
                        docVer.ContentLocation = 'S';   
                        docVer.PathOnClient = 'RequestPost.txt';
                        docVer.Title =  'Response'+firstPart.toUpperCase()+'.txt';//'Request.txt';                   
                        Blob reqData = Blob.valueof(responseFile);   
                        docVer.VersionData = reqData;   
                        // insert DocVer;  
                        ContentDoc.add(docVer);
                        Mapcontver.put(title,firstPart.toLowerCase());    
                        //String VesId = [Select ContentDocumentid from ContentVersion where id=:DocVer.id].ContentDocumentid;    
                        ContentDocumentLink Doclink = New ContentDocumentLink();    
                        //  Doclink.ContentDocumentId = VesId;  
                        Doclink.linkedEntityId = cu.id;    
                        Doclink.sharetype = 'I';    
                        Doclink.visibility = 'AllUsers';    
                        //insert Doclink; 
                        mapcontdoc.put(firstPart.toLowerCase(),Doclink);
                        
                    }   
                    catch(exception ex) 
                    {   
                        system.debug(ex.getmessage());  
                    }  
            }     
        }
          if(ContentDoc.size()>0 && ContentDoc!=null){
                //DMLManager.insertAsUser(ContentDoc);
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
            
            System.debug('MapcontV '+MapcontV);
            List<ContentDocumentLink> contList = new List<ContentDocumentLink>();
            for(String contstr : mapcontdoc.keySet()){
                ContentDocumentLink Doclink = mapcontdoc.get(contstr);
                System.debug('MapcontV '+MapcontV.get(contstr.toLowerCase()));
                Doclink.ContentDocumentId = MapcontV.get(contstr.toLowerCase());
                contList.add(Doclink);
            }
             if(contList.size()>0 && contList!=null){
                //DMLManager.insertAsUser(contList);
                insert contList;
            }  
            
        if(finalClaims.size() > 0){ 
            if(Schema.sObjectType.ElixirSuite__Claim__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Message__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Claimid__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Claim_Md_Id__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__fdos__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Insurance_Number__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Payer_ID__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Sender_Icn__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Sender_Name__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Claim_Status__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Sender_Id__c.isUpdateable() &&
                Schema.sObjectType.ElixirSuite__Claim__c.fields.ElixirSuite__Batch_Id__c.isUpdateable()){
                
                update finalClaims;
                    }
                }
            }
    
     catch(Exception e){
     //ExceptionLog.logError(e);
        }
}

}
public with sharing class ClaimPostClearingHouseNightlyBatch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts{
    public void execute(SchedulableContext sc) {
        
        List<ElixirSuite__Elixir_Pluggable_Classes__mdt> pluggableClass = new List<ElixirSuite__Elixir_Pluggable_Classes__mdt>();
        String virtualClassName;
        pluggableClass = [SELECT DeveloperName,ElixirSuite__Virtual_Class__c FROM ElixirSuite__Elixir_Pluggable_Classes__mdt WHERE DeveloperName='NewClaimMDIntegration'];
        if(pluggableClass != null && !pluggableClass.isEmpty()){
            
            virtualClassName = pluggableClass[0].ElixirSuite__Virtual_Class__c;
            
        }
        if(virtualClassName != '' && virtualClassName !=null){
        Database.executeBatch(new ClaimPostClearingHouseNightlyBatch(), 100);
        }
       
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        Schema.DescribeSObjectResult result = ElixirSuite__Claim__c.sObjectType.getDescribe();
        List<String> apiNames =  new List<String>(result.fields.getMap().keySet());
        String query = 'SELECT ' + String.join(apiNames,',') + ',ElixirSuite__payor__r.ElixirSuite__Payer_Code__c,ElixirSuite__Claim__r.ElixirSuite__payor__r.Name,ElixirSuite__Claim__r.ElixirSuite__Insured_s_ID_Number__c,ElixirSuite__Account__r.ElixirSuite__First_Name__c,ElixirSuite__Account__r.ElixirSuite__Last_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_First_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Middle_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Last_Name__c' + ' FROM ElixirSuite__Claim__c ';
        if(!Test.isRunningTest()){
            query+= 'WHERE ElixirSuite__Claim_Status__c = ' +'\''+ 'Ready to Submit' + '\' AND ElixirSuite__payor__r.ElixirSuite__Claim_Processing_via__c='+'\''+ 'Clearing House' + '\'';
        }      
        return Database.getQueryLocator(query);
    } 
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        System.debug('scope============'+scope);
        
        List<ElixirSuite__Claim__c> listOfClaims = (List<ElixirSuite__Claim__c>)scope;
        Schema.DescribeSObjectResult result = ElixirSuite__Claim__c.sObjectType.getDescribe();
        List<String> apiNames =  new List<String>(result.fields.getMap().keySet());
        List<ElixirSuite__Claim__c> claimsFromDB = Database.query('SELECT ' + String.join(apiNames,',') + ',ElixirSuite__Account__r.ElixirSuite__First_Name__c,ElixirSuite__Account__r.ElixirSuite__Last_Name__c,ElixirSuite__payor__r.ElixirSuite__Payer_Code__c,ElixirSuite__Claim__r.ElixirSuite__payor__r.Name,ElixirSuite__Claim__r.ElixirSuite__Insured_s_ID_Number__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_First_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Middle_Name__c,ElixirSuite__VOB_lookup__r.ElixirSuite__Insured_Last_Name__c' + ' FROM ElixirSuite__Claim__c  WHERE Id IN : listOfClaims');
        if(claimsFromDB!=null && claimsFromDB.size()>0){
            for(ElixirSuite__Claim__c claim :claimsFromDB){
                claim.ElixirSuite__Claim_Status__c = 'Sent to Clearing house';
            }
            //DMLManager.updateAsUser(claimsFromDB);
            update claimsFromDB;
            if(claimsFromDB.size() > 0){
                Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems = CustomerCalloutClaimMD.lineItems(claimsFromDB);
                List<ElixirSuite__Claim_Line_Items__c> lineItems = new List<ElixirSuite__Claim_Line_Items__c>();
                for(List<ElixirSuite__Claim_Line_Items__c> lineItem :mapOfClaimIdToLineItems.values()){
                    if(lineItem!=null){
                        lineItems.addAll(lineItem);
                    }
                }
            	//DMLManager.updateAsUser(lineItems);
                update lineItems;
                System.enqueueJob(new ClaimPostClearingHouseNightlyHandler(claimsFromDB, mapOfClaimIdToLineItems));
            }
        }
    
    }    
    public void finish(Database.BatchableContext BC){        
    }
}
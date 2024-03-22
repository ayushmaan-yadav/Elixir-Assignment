public with sharing class ClaimPostClearingHouseNightlyHandler implements Queueable, Database.AllowsCallouts {
    
    List<ElixirSuite__Claim__c> claimsFromDB;
    Map<Id,List<ElixirSuite__Claim_Line_Items__c>> mapOfClaimIdToLineItems;
    public ClaimPostClearingHouseNightlyHandler(List<sObject> claimsFromDB, Map<Id,List<sObject>> mapOfClaimIdToLineItems){
        this.claimsFromDB = claimsFromDB;
        this.mapOfClaimIdToLineItems = mapOfClaimIdToLineItems;
    }
    public void execute(QueueableContext context) {
        CustomerCalloutClaimMD.entryPointOfCallOut(claimsFromDB, mapOfClaimIdToLineItems);              
    }

}
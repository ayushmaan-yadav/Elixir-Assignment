public with sharing class GetERABatchHandler implements Queueable, Database.AllowsCallouts{
    
    public void execute(QueueableContext context) {
        CreateERANightlyBatchClaimMD.entryPointCallout();               
    }

}
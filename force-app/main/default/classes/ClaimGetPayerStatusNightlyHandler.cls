public with sharing class ClaimGetPayerStatusNightlyHandler implements Queueable, Database.AllowsCallouts{
    
    public void execute(QueueableContext context) {
        ClaimGetPayerStatusNightlyBatch.entryPointCallout();               
    }

}
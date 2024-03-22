/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_SubsctiptionPaymentStatusBatch implements Database.Batchable<sObject> {

    private Elixir_AuthorizeCallout authCallout = new Elixir_AuthorizeCallout();

    /**
    * @description Start method for the batch
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Database.BatchableContext bc
    * @returns Database.QueryLocator
    **/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select id,ElixirSuite__Account__r.Elixir_Authorize_Customer_Profile_Id__c,ElixirSuite__Payment_Plan__r.ElixirSuite__Status__c,'+
                        'ElixirSuite__Installment_Amount__c, ElixirSuite__Account__c,ElixirSuite__Payment_Plan__r.Elixir_Payment_Method_Id__c ' +
                        'from ElixirSuite__Payment_Plan_Line_Item__c Where ElixirSuite__Due_Date__c = TODAY '+
                        'and ElixirSuite__Payment_Status__c = \'Unpaid\' and ElixirSuite__Payment_Plan__r.ElixirSuite__Status__c = \'Active\' '+
                        'and ElixirSuite__Payment_Plan__r.Elixir_External_Subscription_ID__c != null';
        return Database.getQueryLocator(query);
    }
  
    /**
    * @description Execute method for the batch
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Database.BatchableContext bc, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList
    * @returns None
    **/
    public void execute(Database.BatchableContext bc, List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList){
        
        for(ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine : paymentPlanLineList) {
            Elixir_AuthorizeResponseWrappers resWrapper = createAndSendRequest(paymentPlanLine);
            handleResponse(resWrapper,paymentPlanLine);
        }

    }

    /**
    * @description Create and Send the Api Request
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine
    * @returns Elixir_AuthorizeResponseWrappers
    **/
    public Elixir_AuthorizeResponseWrappers createAndSendRequest(ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine) {

        String requestJson = Elixir_AuthorizeRequestGenerator.generateGetTransactionListForCustomerRequest(authCallout,
                            paymentPlanLine.ElixirSuite__Account__r.Elixir_Authorize_Customer_Profile_Id__c,
                            paymentPlanLine.ElixirSuite__Payment_Plan__r.Elixir_Payment_Method_Id__c);

        HttpResponse result =  authCallout.sendRequest(requestJson);
        // Response Handling 
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = Elixir_AuthorizeCalloutController.deserializeResult(result.getBody());
            return resWrapper;
        }
        return null;

    }

    /**
    * @description Handle the api response
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Elixir_AuthorizeResponseWrappers resWrapper, @param ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine
    * @returns None
    **/
    public void handleResponse(Elixir_AuthorizeResponseWrappers resWrapper,ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine) {
        
        String uniqueKey = Elixir_AuthorizeGatewayController.getUniqueToken();
        Elixir_AuthorizeResponseWrappers.Transactions transactionRec =  (Elixir_AuthorizeResponseWrappers.Transactions) getExternalTransaction(resWrapper,paymentPlanLine);
        String externalTransId = transactionRec.transId;
        Elixir_TransactionUtility.insertOtherTransactionAfterPaymentForPaymentPlan(paymentPlanLine.ElixirSuite__Account__c,
                                paymentPlanLine.ElixirSuite__Installment_Amount__c,
                                uniqueKey,externalTransId,resWrapper,
                                new List<ElixirSuite__Payment_Plan_Line_Item__c>{paymentPlanLine},null);
    }


    /**
    * @description Handle the api response
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Elixir_AuthorizeResponseWrappers resWrapper, @param ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine
    * @returns Elixir_AuthorizeResponseWrappers.Transactions
    **/
    public Elixir_AuthorizeResponseWrappers.Transactions getExternalTransaction(Elixir_AuthorizeResponseWrappers resWrapper,ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine) {
        Map<String,Elixir_AuthorizeResponseWrappers.Transactions> transMap = getTransactionMapFromList(resWrapper.transactions);
        DateTime paymentDateTime = paymentPlanLine.ElixirSuite__Due_Date__c;
        Decimal installmentAmount = paymentPlanLine.ElixirSuite__Installment_Amount__c;
        return transMap.get(generateKey(paymentDateTime,installmentAmount));
    }

    /**
    * @description Returns the Map of Transactions vs the Invoice Number
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param List<Elixir_AuthorizeResponseWrappers.Transaction> transactions
    * @returns Map<Sting,Elixir_AuthorizeResponseWrappers.Transaction>
    **/
    private static String generateKey(DateTime paymentDateTime,Decimal amount){
        String paymentDateString = paymentDateTime.format('yyyy-MM-dd');
        return 'paymentDateString'+ amount;
    }

    /**
    * @description Returns the Map of Transactions vs the Invoice Number
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param List<Elixir_AuthorizeResponseWrappers.Transaction> transactions
    * @returns Map<Sting,Elixir_AuthorizeResponseWrappers.Transaction>
    **/
    private static Map<String,Elixir_AuthorizeResponseWrappers.Transactions> getTransactionMapFromList(List<Elixir_AuthorizeResponseWrappers.Transactions> transactions) {
        Map<String,Elixir_AuthorizeResponseWrappers.Transactions> transMap = new Map<String,Elixir_AuthorizeResponseWrappers.Transactions>();
        for (Elixir_AuthorizeResponseWrappers.Transactions trans : transactions ) {
            transMap.put(generateKey(DateTime.valueOf(trans.submitTimeUTC),trans.settleAmount),trans);
        }
        return transMap;
    }
    
    /**
     * @description Execute at finish of the batch
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Database.BatchableContext bc
    * @returns None
    **/
    public void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        /*mail.setToAddresses(new String[] {});
        mail.setReplyTo('batch@acme.com');
        mail.setSenderDisplayName('Batch Processing');
        mail.setSubject('Batch Process Completed');
        mail.setPlainTextBody('Batch Process has completed');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });*/
    }
    
}
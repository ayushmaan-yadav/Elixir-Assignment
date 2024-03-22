/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthorizeCalloutController {

    private static final String FAILED_TO_GET_TOKEN = 'Failed to get token';
    private static final String SUCCESS = 'Success';
    private static final String FAILED = 'Failed';
    private static Elixir_AuthorizeCallout authCallout = new Elixir_AuthorizeCallout();

    /**
    * @description Register New Customer Payment Profile with Authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc 
    * @returns String
    **/
    public static String registerCustomerProfile(Account acc){
        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateCreateCustomerProfileRequest(authCallout,acc);
        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);
        // Response Handling 
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            return resWrapper.customerProfileId;
        }
        
        return null;
    }

    /**
    * @description API to get the token for the payment page from authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc, @param Decimal amountToCharge, @param String uniquePaymentToken, @param String customerProfileId, @param boolean isAllocated 
    * @returns String
    **/
    public static String getAcceptPageToken(Account acc,Decimal amountToCharge,String uniquePaymentToken,String customerProfileId,boolean isAllocated){
        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateGetHostedPaymentPageRequest(authCallout,acc,amountToCharge,uniquePaymentToken,customerProfileId,isAllocated);
        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);
        // Response Handling 
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            return resWrapper?.token;
        }
        return FAILED_TO_GET_TOKEN;
    }


    /**
    * @description API to create Subscription with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc, @param ElixirSuite__Payment_Plan__c paymentPlanInfo, @param ElixirSuite__Payment_Information__c paymentInfo 
    * @returns None
    **/
    @AuraEnabled
    public static void createSubscription(Account acc,ElixirSuite__Payment_Plan__c paymentPlanInfo,ElixirSuite__Payment_Information__c paymentInfo){
        
        Boolean updateAddressIdOnAccount = false;
        Elixir_AuthorizeResponseWrappers addressResWrapper;
        if (acc.Elixir_Authorize_Customer_Address_Id__c == null) {
            addressResWrapper = registerCustomerAddressProfile(acc);
            acc.Elixir_Authorize_Customer_Address_Id__c = addressResWrapper.customerAddressId;
            System.debug('Create Subscription called  addressResWrapper :: ' + addressResWrapper);
            updateAddressIdOnAccount = true;
        }
        
        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateARBCreateSubscriptionRequest(authCallout,acc,paymentInfo,paymentPlanInfo);

        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);
        
        // Response Handling
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            if (updateAddressIdOnAccount) {
                Elixir_AccountUtility.updateCustomerAddressId(acc.id,addressResWrapper.customerAddressId);
            }
            // Update Subsctiption Id and Subscription Status 
            Elixir_PaymentUtility.updatePaymentPlanAfterCreateSubscription(resWrapper.subscriptionId,paymentPlanInfo.Id,paymentInfo.ElixirSuite__Source_Id__c);
        }

    }

    /**
    * @description API to cancel Subscription with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String subscriptionId, @param String paymentPlanId 
    * @returns String
    **/
    @AuraEnabled
    public static String cancelSubscription(String subscriptionId, String paymentPlanId){
        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateARBCancelSubscriptionRequest(authCallout,subscriptionId);
        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);

        // Response Handling
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            if (resWrapper.messages.resultCode == 'Error') {
                return resWrapper.messages.message[0].text;
            }
            // Update Subscription Status 
            Elixir_PaymentUtility.updatePaymentPlanAfterCancelSubscription(paymentPlanId);

            return Success;
        }

        return Failed;
    }

    /**
    * @description Get Unsettled transaction from authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID,@param String uniqueKey, @param Boolean isAllocated 
    * @returns None
    **/
    @AuraEnabled
    public static void getCustomerProfileTransactionList(String accID,String uniqueKey,Boolean isAllocated){
        try {
            Account acc = Elixir_AccountUtility.getAccount(accID);
            // Create Request JSON String
            String requestJson = Elixir_AuthorizeRequestGenerator.generateGetUnsettledTransactionListRequest(authCallout);
            // API Hit 
            HttpResponse result =  authCallout.sendRequest(requestJson);
            // Response Handling
            if (result.getStatusCode() == 200){
                Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
                Elixir_AuthorizeResponseWrappers.Transactions transactionRec =  (Elixir_AuthorizeResponseWrappers.Transactions) Elixir_TransactionUtility.getExternalTransaction(uniqueKey,resWrapper);
                Elixir_AuthorizeResponseWrappers paymentResWrapper = getCustomerPaymentProfile(acc);
                Elixir_LogUtility.insertLogs();
                // Process Transactions and find our transaction and update record
                if (isAllocated) {
                    Elixir_TransactionUtility.updateTransactionAfterPayment(uniqueKey,transactionRec.transId,resWrapper);
                } else {
                    Elixir_TransactionUtility.updateOtherTransactionAfterPayment(uniqueKey,transactionRec.transId,resWrapper);
                }

                Elixir_PaymentUtility.createPaymentInformation(transactionRec,acc.id,paymentResWrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Get Unsettled Transaction for Payment Plan from authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID,@param String uniqueKey,@param String selectedProcedureRecords, @param String paymentPlanLineListJson 
    * @returns None
    **/
    @AuraEnabled
    public static void getCustomerProfileTransactionListForPaymentPlan(String accID,String uniqueKey,String selectedProcedureRecords,String paymentPlanLineListJson){
        try {
            Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap paymentPlanLineWrapper = (Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap) JSON.deserialize(paymentPlanLineListJson,Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap.class);
            Account acc = Elixir_AccountUtility.getAccount(accID);
            // Create Request JSON String
            String requestJson = Elixir_AuthorizeRequestGenerator.generateGetUnsettledTransactionListRequest(authCallout);
            // API Hit 
            HttpResponse result =  authCallout.sendRequest(requestJson);
            // Response Handling
            if (result.getStatusCode() == 200){
                Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
                Elixir_AuthorizeResponseWrappers.Transactions transactionRec =  (Elixir_AuthorizeResponseWrappers.Transactions) Elixir_TransactionUtility.getExternalTransaction(uniqueKey,resWrapper);
                Elixir_AuthorizeResponseWrappers paymentResWrapper = getCustomerPaymentProfile(acc);
                Elixir_LogUtility.insertLogs();
                // Process Transactions and find our transaction and update record
                Elixir_TransactionUtility.updateTransactionalRecordsForPaymentPlan(accId,uniqueKey,selectedProcedureRecords,paymentPlanLineWrapper.paymentPlanLineList,transactionRec.transId,resWrapper);
                Elixir_PaymentUtility.createPaymentInformation(transactionRec,acc.id,paymentResWrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Charge a saved card with the payment profile 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc, @param Decimal amountToCharge, @param String procedureId, @param ElixirSuite__Payment_Information__c paymentInfo, @param String uniqueKey
    * @returns None
    **/
    public static void chargeCustomerProfile(Account acc,Decimal amountToCharge,String procedureId,ElixirSuite__Payment_Information__c paymentInfo,String uniqueKey){

        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateCreateTransactionRequest(authCallout,acc,paymentInfo,amountToCharge);

        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);

        // Response Handling
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            Elixir_AuthorizeResponseWrappers.TransactionResponse transactionRec =  (Elixir_AuthorizeResponseWrappers.TransactionResponse) Elixir_TransactionUtility.getExternalTransaction(uniqueKey,resWrapper);
            // Do Database Update of for payment made
            if (procedureId != null && procedureId != '') {
                Elixir_TransactionUtility.insertTransactionAfterPayment(acc.id,amountToCharge,procedureId,uniqueKey,transactionRec.transId,resWrapper);
            } else {
                Elixir_TransactionUtility.insertOtherTransactionAfterPayment(acc.id,amountToCharge,uniqueKey,transactionRec.transId,resWrapper);
            }

        }
    }

    /**
    * @description Charge a saved card with the payment profile for Payment Plan
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc,@param Decimal amountToCharge,@param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList 
    * @param String selectedProcedureRecords, @param ElixirSuite__Payment_Information__c paymentInfo, @param String uniqueKey
    * @returns None
    **/
    public static void chargeCustomerProfileForPaymentPlan(Account acc,Decimal amountToCharge,List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList,String selectedProcedureRecords,ElixirSuite__Payment_Information__c paymentInfo,String uniqueKey){

        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateCreateTransactionRequest(authCallout,acc,paymentInfo,amountToCharge);

        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);

        // Response Handling
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            Elixir_AuthorizeResponseWrappers.TransactionResponse transactionRec =  (Elixir_AuthorizeResponseWrappers.TransactionResponse) Elixir_TransactionUtility.getExternalTransaction(uniqueKey,resWrapper);
            // Do Database Update of for payment made
            Elixir_TransactionUtility.insertOtherTransactionAfterPaymentForPaymentPlan(acc.id,amountToCharge,uniqueKey,transactionRec.transId,resWrapper,paymentPlanLineList,selectedProcedureRecords);
            
        }
    }

    /**
    * @description Register New Customer Address Profile with Authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc 
    * @returns Elixir_AuthorizeResponseWrappers
    **/
    public static Elixir_AuthorizeResponseWrappers registerCustomerAddressProfile(Account acc){

        // Create Request JSON String
        String requestJson = Elixir_AuthorizeRequestGenerator.generateCreateCustomerShippingAddressRequest(authCallout,acc);

        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);

        // Response Handling
        if (result.getStatusCode() == 200){
            //Successfully created customer Address profile
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody()); 
            // Update Accout with New Adress Profile Id
            return resWrapper;
        }

        return null;
    }

    /**
    * @description Register New Customer Address Profile with Authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Account acc
    * @returns Elixir_AuthorizeResponseWrappers
    **/
    public static Elixir_AuthorizeResponseWrappers getCustomerPaymentProfile(Account acc){
        String requestJson = Elixir_AuthorizeRequestGenerator.generateGetCustomerProfileRequest(authCallout,acc);
        // API Hit 
        HttpResponse result =  authCallout.sendRequest(requestJson);
        // Response Handling
        if (result.getStatusCode() == 200){
            Elixir_AuthorizeResponseWrappers resWrapper = deserializeResult(result.getBody());
            return resWrapper;
        }

        return null;
    }

    /**
    * @description Deserialize the response json into the Response wrapper
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String responseJson
    * @returns Elixir_AuthorizeResponseWrappers
    **/
    public static Elixir_AuthorizeResponseWrappers deserializeResult(String responseJson){ 
        Elixir_AuthorizeResponseWrappers resWrapper;
        try {
            if(responseJson.substring(0,1) != '{') {
                responseJson = responseJson.substring(1);
            }
            resWrapper = (Elixir_AuthorizeResponseWrappers) JSON.deserialize(responseJson,Elixir_AuthorizeResponseWrappers.class);
        }
        catch(Exception e) {
            system.debug('getStackTraceString :: ' + e.getStackTraceString());
        }
        return resWrapper;
    }

}
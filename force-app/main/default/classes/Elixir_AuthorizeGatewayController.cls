/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthorizeGatewayController {

    private static final String PROCEDURES = 'procedures';
    private static final String URL_KEY = 'URL';
    private static final String ID = 'Id';
    private static final String VFPAGEURL = '/apex/Elixir_AuthorizePaymentTerminal';

    /**
    * @description API to resgister new payment with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Decimal amountPaid, @param String procedureRecordIds, @param String accountId
    * @returns ElixirSuite.PaymentIntegration.MessageWrapper1
    **/
    public static ElixirSuite.PaymentIntegration.MessageWrapper1 authorizeNewPayment(Decimal amountPaid, String procedureRecordIds, String accountId ) {

        // Querry Account Data 
        Account acc = Elixir_AccountUtility.getAccount(accountId);

        String customerProfileId;
        Boolean updateAccount = false;

        if (acc.Elixir_Authorize_Customer_Profile_Id__c == null) {
            customerProfileId = Elixir_AuthorizeCalloutController.registerCustomerProfile(acc);
            updateAccount = true;
        } else {
            customerProfileId = acc.Elixir_Authorize_Customer_Profile_Id__c;
        }

        if (procedureRecordIds != null && procedureRecordIds != ''){
            procedureRecordIds = getIdFromMapString(procedureRecordIds);
        }
        
        String uniquePaymentToken = getUniqueToken();
        
        boolean isAllocated = (procedureRecordIds != null);
        
        String token = Elixir_AuthorizeCalloutController.getAcceptPageToken(acc, amountPaid,uniquePaymentToken,customerProfileId,isAllocated);

        Elixir_LogUtility.insertLogs();

        // Encode original string to Base64
        Blob encodedBlob = Blob.valueOf(token);
        String base64EncodedString = EncodingUtil.base64Encode(encodedBlob);

        if (updateAccount) {
        	Elixir_AccountUtility.updateCustomerProfileId(acc.id,customerProfileId);
        }

        if (procedureRecordIds != null && procedureRecordIds != '' ) {
            Elixir_TransactionUtility.insertTransactionBeforePayment(acc.id,amountPaid,procedureRecordIds,uniquePaymentToken);
        } else {
            Elixir_TransactionUtility.insertOtherTransactionBeforePayment(acc.id,amountPaid,uniquePaymentToken);
        }

        return new ElixirSuite.PaymentIntegration.MessageWrapper1(URL_KEY,VFPAGEURL +'?token='+base64EncodedString); 
        
    }

    /**
    * @description API to resgister new payment for Payment Plan with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Decimal amountPaid, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLine, @param String selectedProcedureRecords, 
    * @param String accountId, @param Boolean createSubscription, @param String PaymentPlanId 
    * @returns ElixirSuite.PaymentIntegration.MessageWrapper1
    **/
    @AuraEnabled
    public static ElixirSuite.PaymentIntegration.MessageWrapper1 authorizeNewPaymentForPaymentPlan(Decimal amountPaid, List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLine,String selectedProcedureRecords, String accountId,Boolean createSubscription,String PaymentPlanId) {

        // Querry Account Data 
        Account acc = Elixir_AccountUtility.getAccount(accountId);

        String customerProfileId;
        Boolean updateAccount = false;

        if (acc.Elixir_Authorize_Customer_Profile_Id__c == null) {
            customerProfileId = Elixir_AuthorizeCalloutController.registerCustomerProfile(acc);
            updateAccount = true;
        } else {
            customerProfileId = acc.Elixir_Authorize_Customer_Profile_Id__c;
        }
        
        String uniquePaymentToken = getUniqueToken();
        
        boolean isAllocated = (paymentPlanLine != null);

        Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap paymentPlanLineWrapper = new Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap();
        paymentPlanLineWrapper.setPaymentPlanLine(paymentPlanLine);

        Elixir_AuthorizeRequestGenerator.setPaymentPlanLine(paymentPlanLineWrapper);

        Elixir_AuthorizeRequestGenerator.setSelectedProcedures(selectedProcedureRecords);

        Elixir_AuthorizeRequestGenerator.setCreateSubscription(createSubscription);
        
        Elixir_AuthorizeRequestGenerator.setPaymentPlanId(paymentPlanId);
        
        String token = Elixir_AuthorizeCalloutController.getAcceptPageToken(acc, amountPaid,uniquePaymentToken,customerProfileId,isAllocated);

        Elixir_LogUtility.insertLogs();

        // Encode original string to Base64
        Blob encodedBlob = Blob.valueOf(token);
        String base64EncodedString = EncodingUtil.base64Encode(encodedBlob);

        if (updateAccount) {
        	Elixir_AccountUtility.updateCustomerProfileId(acc.id,customerProfileId);
        }

        Elixir_TransactionUtility.insertOtherTransactionBeforePayment(acc.id,amountPaid,uniquePaymentToken);

        return new ElixirSuite.PaymentIntegration.MessageWrapper1(URL_KEY,VFPAGEURL +'?token='+base64EncodedString); 
        
    }

    /**
    * @description API to reauthorize a payment with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Decimal amountPaid, @param String procedureRecordIds, @param String paymentInfoId, @param String accountId 
    * @returns ElixirSuite.PaymentIntegration.MessageWrapper1
    **/
    public static ElixirSuite.PaymentIntegration.MessageWrapper1 reauthorizeAndCapturePayment(Decimal amountPaid, String procedureRecordIds,String paymentInfoId, String accountId) {
        
        // Querry Account Data 
        Account acc = Elixir_AccountUtility.getAccount(accountId);

        ElixirSuite__Payment_Information__c paymentInfo = Elixir_PaymentUtility.getPaymentInfo(paymentInfoId);

        if (procedureRecordIds != null && procedureRecordIds != ''){
            procedureRecordIds = getIdFromMapString(procedureRecordIds);
        }

        system.debug('procedureRecordIds : ' + procedureRecordIds);

        String uniquePaymentToken = getUniqueToken();
        
        Elixir_AuthorizeCalloutController.chargeCustomerProfile(acc,amountPaid,procedureRecordIds,paymentInfo,uniquePaymentToken);

        Elixir_LogUtility.insertLogs();

        String instanceUrl = URL.getOrgDomainURL().toExternalForm();

        return new ElixirSuite.PaymentIntegration.MessageWrapper1(URL_KEY, instanceUrl +'/lightning/r/Account/'+acc.id+'/view');

    }

    /**
    * @description API to reauthorize a payment for Payment Plan with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Decimal amountPaid, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLine, @param String selectedProcedureRecords 
    * @param String paymentInfoId, @param String accountId 
    * @returns ElixirSuite.PaymentIntegration.MessageWrapper1
    **/
    public static ElixirSuite.PaymentIntegration.MessageWrapper1 reauthorizeAndCapturePaymentForPaymentPlan(Decimal amountPaid,List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLine,String selectedProcedureRecords,String paymentInfoId, String accountId) {
        
        // Querry Account Data 
        Account acc = Elixir_AccountUtility.getAccount(accountId);

        ElixirSuite__Payment_Information__c paymentInfo = Elixir_PaymentUtility.getPaymentInfo(paymentInfoId);

        String uniquePaymentToken = getUniqueToken();
        
        Elixir_AuthorizeCalloutController.chargeCustomerProfileForPaymentPlan(acc,amountPaid,paymentPlanLine,selectedProcedureRecords,paymentInfo,uniquePaymentToken);

        Elixir_LogUtility.insertLogs();

        String instanceUrl = URL.getOrgDomainURL().toExternalForm();

        return new ElixirSuite.PaymentIntegration.MessageWrapper1(URL_KEY, instanceUrl +'/lightning/r/Account/'+acc.id+'/view');

    }

    /**
    * @description API to create Subscription after first Payment Plan Payment with authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID, @param String paymentPlanId
    * @returns None
    **/
    @AuraEnabled
    public static void createSubsctiptionCall(String accID,String paymentPlanId)
    {
        Account acc = Elixir_AccountUtility.getAccount(accID);

        ElixirSuite__Payment_Plan__c paymentPlanObj = Elixir_PaymentUtility.getPaymentPlan(paymentPlanId);

        ElixirSuite__Payment_Information__c paymentInfo = Elixir_PaymentUtility.getPaymentInfowithAccountId(accID);

        if (paymentInfo != null) {
            Elixir_AuthorizeCalloutController.createSubscription(acc,paymentPlanObj,paymentInfo);
        }
        
    }
    
    /**
    * @description function to fetch procedure from the Stringify JSON
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String procedureMapString 
    * @returns String
    **/
    public static String getIdFromMapString(String procedureMapString) {

        List<String> strList = new List<String>(); 

        Map<String,Object> mapObj = ( Map<String,Object>) JSON.deserializeUntyped(procedureMapString);

        List<Object> procedureList = (List<Object>) mapObj.get(PROCEDURES);

        for(Object  obj: procedureList){ 
            Map<String,Object> procedure = (Map<String,Object>) obj;
            strList.add((String)  procedure.get(ID));
        }

        return String.join(strList,',');
    }

    /**
    * @description This method is used for creating uniqueKey which is for identifying unique URL.
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accountId 
    * @returns String
    **/
    public static String getUniqueToken() {
        // Generate a random number using your desired logic
        // Example logic generating a 15-digit alphanumeric random number:
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randomNumber = '';
        for (Integer i = 0; i < 15; i++) {
            Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomNumber += chars.substring(index, index + 1);
        }
        return randomNumber;
    }

}
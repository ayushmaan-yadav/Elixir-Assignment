/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_PaymentUtility {

    private static final String ACTIVE = 'Active';
    private static final String INACTIVE = 'Inactive';
    private static final String CREDIT_CARD = 'Credit Card';
    
    /**
    * @description Update payment plan after creating a subscription
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String subscriptionId, @param String paymentPlanId 
    * @returns None
    **/
    public static void updatePaymentPlanAfterCreateSubscription(String subscriptionId,String paymentPlanId,String customerPaymentProfileId) {
        // handle the payment plan after creating a subscription.
        ElixirSuite__Payment_Plan__c paymentPlan = new ElixirSuite__Payment_Plan__c(Id = paymentPlanId);
        paymentPlan.Elixir_External_Subscription_ID__c = subscriptionId;
        paymentPlan.ElixirSuite__Status__c = ACTIVE;
        paymentPlan.Elixir_Payment_Method_Id__c = customerPaymentProfileId;
        Elixir_DMLManager.updateAsUser(paymentPlan);
    }

    /**
    * @description Update payment plan after Cancelling a subscription
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String paymentPlanId
    * @returns None
    **/
    public static void updatePaymentPlanAfterCancelSubscription(String paymentPlanId) {
        // handle the payment plan after cancelling a subscription.
        ElixirSuite__Payment_Plan__c paymentPlan = new ElixirSuite__Payment_Plan__c(Id = paymentPlanId);
        paymentPlan.ElixirSuite__Status__c = INACTIVE;
        paymentPlan.Elixir_External_Subscription_ID__c = null;
        paymentPlan.Elixir_Payment_Method_Id__c = null;
        Elixir_DMLManager.updateAsUser(paymentPlan);
    }

    /**
    * @description Get Payment Info Object 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String paymentInfoId
    * @returns ElixirSuite__Payment_Information__c
    **/
    public static ElixirSuite__Payment_Information__c getPaymentInfo(String paymentInfoId) {
        return [SELECT id,Elixir_Original_Authorize_Amount__c,Elixir_Original_Network_Transaction_Id__c,ElixirSuite__Source_Id__c
                    FROM ElixirSuite__Payment_Information__c WHERE Id =: paymentInfoId WITH SECURITY_ENFORCED LIMIT 1];
    }

    /**
    * @description Get Payment Info List
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accountId
    * @returns List<ElixirSuite__Payment_Information__c>
    **/
    public static List<ElixirSuite__Payment_Information__c> getPaymentInfoList(String accountId) {
        return [SELECT id,ElixirSuite__Credit_Card_Number__c,ElixirSuite__Expiration_Month__c,ElixirSuite__Expiration_Year__c,ElixirSuite__Source_Id__c
                    FROM ElixirSuite__Payment_Information__c WHERE ElixirSuite__Account__c =: accountId WITH SECURITY_ENFORCED ];
    }   

    /**
    * @description Get Payment Plan 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String paymentPlanId
    * @returns ElixirSuite__Payment_Plan__c
    **/
    @AuraEnabled(cacheable=true)
    public static ElixirSuite__Payment_Plan__c getPaymentPlan(String paymentPlanId) {
        ElixirSuite__Payment_Plan__c  paymentPlanRecord = [SELECT id,Name,Elixir_External_Subscription_ID__c,ElixirSuite__Patient_Name__c,ElixirSuite__Installment_Amount__c,ElixirSuite__Patient_Responsibility__c,ElixirSuite__Payment_Frequency__c,ElixirSuite__Status__c,ElixirSuite__Total_Balance_Due__c FROM ElixirSuite__Payment_Plan__c WHERE Id =: paymentPlanId WITH SECURITY_ENFORCED LIMIT 1];
        return paymentPlanRecord;
    }
    
    /**
    * @description Get Payment Plan Line
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String paymentPlanId
    * @returns ElixirSuite__Payment_Plan_Line_Item__c
    **/
    public static ElixirSuite__Payment_Plan_Line_Item__c getPaymentPlanLine(String paymentPlanId) {
        ElixirSuite__Payment_Plan_Line_Item__c  paymentPlanLineRecord = [SELECT id,ElixirSuite__Due_Date__c,ElixirSuite__Balance_Due__c FROM ElixirSuite__Payment_Plan_Line_Item__c WHERE ElixirSuite__Payment_Plan__c =: paymentPlanId and ElixirSuite__Payment_Status__c = 'Unpaid' WITH SECURITY_ENFORCED ORDER BY ElixirSuite__Due_Date__c ASC NULLS LAST LIMIT 1];
        return paymentPlanLineRecord;
    }

    /**
    * @description Get Map of Payment Info Already Created key - Payment Method Id.  
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Set<String> customerPaymentProfileIds
    * @returns Map<String,ElixirSuite__Payment_Information__c>
    **/
    private static Map<String,ElixirSuite__Payment_Information__c> getPaymentInfoMap(Set<String> customerPaymentProfileIds) {
        List<ElixirSuite__Payment_Information__c> paymentInfoList = [SELECT id,ElixirSuite__Source_Id__c FROM ElixirSuite__Payment_Information__c WHERE ElixirSuite__Source_Id__c IN : customerPaymentProfileIds WITH SECURITY_ENFORCED];
        Map<String,ElixirSuite__Payment_Information__c> paymentInfoMap = new Map<String,ElixirSuite__Payment_Information__c>();
        for(ElixirSuite__Payment_Information__c paymentInfo : paymentInfoList) {
            paymentInfoMap.put(paymentInfo.ElixirSuite__Source_Id__c,paymentInfo);
        }
        return paymentInfoMap;
    }

    /**
    * @description Get Payment Info Associated with Account.  
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param @param String accId
    * @returns ElixirSuite__Payment_Information__c
    **/
    public static ElixirSuite__Payment_Information__c getPaymentInfowithAccountId(String accId) {
        List<ElixirSuite__Payment_Information__c> paymentInfoList = [SELECT id,ElixirSuite__Source_Id__c FROM ElixirSuite__Payment_Information__c WHERE ElixirSuite__Account__c =: accId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
        if (paymentInfoList.size() > 0) {
            return paymentInfoList[0];
        } else {
            return null;
        }
    }
    
    /**
    * @description Get List of Payment Info Associated with Account.  
    * @author Anmol Saxena | 18th Feburary 2024
    * @param @param String payPlanId
    * @returns list<ElixirSuite__Payment_Information__c>
    **/
    @AuraEnabled
    public static SubscribeInfoWrapper getPaymentInfoLst(String payPlanId) {
        SubscribeInfoWrapper subscribeInfoWrapper = new SubscribeInfoWrapper();
        ElixirSuite__Payment_Plan__c payPlan = getPaymentPlan(payPlanId);
        list<ElixirSuite__Payment_Information__c> paymentInfo = getPaymentInfoList(payPlan.ElixirSuite__Patient_Name__c);
        list<ElixirSuite__Payment_Plan_Line_Item__c> payPlanLineLst = new list<ElixirSuite__Payment_Plan_Line_Item__c>{Elixir_PaymentUtility.getPaymentPlanLine(payPlanId)};
        subscribeInfoWrapper.paymentInfoLst = paymentInfo;
        subscribeInfoWrapper.paymentPlanLineLst = payPlanLineLst;
        subscribeInfoWrapper.amtPaid = payPlanLineLst[0].ElixirSuite__Balance_Due__c;
        subscribeInfoWrapper.accountId = payPlan.ElixirSuite__Patient_Name__c;
        subscribeInfoWrapper.payPlanRec = payPlan;
        subscribeInfoWrapper.accountRec = Elixir_AccountUtility.getAccount(payPlan.ElixirSuite__Patient_Name__c);
        return subscribeInfoWrapper;
    }
    
    public class SubscribeInfoWrapper{
        @AuraEnabled
        public list<ElixirSuite__Payment_Information__c> paymentInfoLst ;
        @AuraEnabled
        public Decimal amtPaid;
        @AuraEnabled
        public list<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineLst;
        @AuraEnabled
        public String accountId;
        @AuraEnabled
        public Account accountRec;
        @AuraEnabled
        public ElixirSuite__Payment_Plan__c payPlanRec;
    }
    
    

    /**
    * @description Create Payment Information After Successful Payment  
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param Elixir_AuthorizeResponseWrappers.Transactions transaction, @param String accId
    * @returns None
    **/
    public static void createPaymentInformation(Elixir_AuthorizeResponseWrappers.Transactions transactionRec,String accId,Elixir_AuthorizeResponseWrappers paymentResWrapper){
        
        Set<String> paymentProfileIds = new Set<String>();
        if (paymentResWrapper == null || paymentResWrapper.profile == null || paymentResWrapper.profile.paymentProfiles == null) {
            return;
        }
        for (Elixir_AuthorizeResponseWrappers.PaymentProfile paymentProfile : paymentResWrapper.profile.paymentProfiles) {
            paymentProfileIds.add(paymentProfile.customerPaymentProfileId);
        } 
        Map<String,ElixirSuite__Payment_Information__c> paymentInfoMap = getPaymentInfoMap(paymentProfileIds);
        List<ElixirSuite__Payment_Information__c> paymentInfoList = new List<ElixirSuite__Payment_Information__c>();
        for (Elixir_AuthorizeResponseWrappers.PaymentProfile paymentProfile : paymentResWrapper.profile.paymentProfiles) {   
            if (!paymentInfoMap.containsKey(paymentProfile.customerPaymentProfileId)) {
                ElixirSuite__Payment_Information__c paymentInfo = new ElixirSuite__Payment_Information__c();
                paymentInfo.ElixirSuite__Account__c = accId;
                paymentInfo.Elixir_Original_Authorize_Amount__c = String.valueOf(transactionRec.settleAmount);
                paymentInfo.Elixir_Original_Network_Transaction_Id__c = transactionRec.transId;
                paymentInfo.ElixirSuite__Credit_Card_Number__c = paymentProfile.payment.creditCard.cardNumber;
                paymentInfo.ElixirSuite__Credit_Card_Company__c = paymentProfile.payment.creditCard.cardType;
                paymentInfo.ElixirSuite__Card_Type__c = paymentProfile.payment.creditCard.cardType;
                paymentInfo.ElixirSuite__Payment_Method__c = CREDIT_CARD;
                List<String> splitString = paymentProfile.payment.creditCard.expirationDate.split('-');
                if (splitString.size() == 2) {
                    Integer monthNumber = Integer.valueOf(splitString[1]); // Example month number
                    String monthAbbreviation = DateTime.newInstanceGmt(2000, monthNumber, 1).format('MMM');
                    paymentInfo.ElixirSuite__Expiration_Month__c = monthAbbreviation;
                    paymentInfo.ElixirSuite__Expiration_Year__c = splitString[0];
                }
                paymentInfo.ElixirSuite__Source_Id__c = paymentProfile.customerPaymentProfileId;
                paymentInfoList.add(paymentInfo);
            }
        }
        Elixir_DMLManager.insertAsUser(paymentInfoList);
    }

}
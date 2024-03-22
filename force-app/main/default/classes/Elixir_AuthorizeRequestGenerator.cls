/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/
public with sharing class Elixir_AuthorizeRequestGenerator {

	private static final String AUTH_CAPTURE_TRANSACTION = 'authCaptureTransaction';
	private static  final String RESUBMISSION = 'resubmission';
    // Define constants for keys
    private static final String GET_TRANSACTION_LIST_FOR_CUSTOMER_REQUEST_KEY = 'getTransactionListForCustomerRequest';
    private static final String GET_UNSETTLED_TRANSACTION_LIST_REQUEST_KEY = 'getUnsettledTransactionListRequest';
    private static final String SORTING_KEY = 'sorting';
    private static final String ORDER_BY_KEY = 'orderBy';
    private static final String ORDER_DESCENDING_KEY = 'orderDescending';
    private static final String PAGING_KEY = 'paging';
    private static final String LIMIT_KEY = 'limit';
    private static final String OFFSET_KEY = 'offset';
    private static final String SUBMIT_TIME_UTC = 'submitTimeUTC';
    private static final String CREATE_CUSTOMER_PROFILE_REQUEST_KEY = 'createCustomerProfileRequest';
    private static final String DESCRIPTION_KEY = 'description';
    private static final String MERCHANT_AUTHENTICATION_KEY = 'merchantAuthentication';
    private static final String REF_ID_KEY = 'refId';
    private static final String TRANSACTION_REQUEST_KEY = 'transactionRequest';
    private static final String HOSTED_PAYMENT_SETTINGS_KEY = 'hostedPaymentSettings';
    private static final String SETTING_KEY = 'setting';
    private static final String SETTING_NAME_KEY = 'settingName';
    private static final String SETTING_VALUE_KEY = 'settingValue';
    private static final String GET_HOSTED_PAYMENT_PAGE_REQUEST_KEY = 'getHostedPaymentPageRequest';
    private static final String NAME_KEY = 'name';
    private static final String TRANSACTION_KEY = 'transactionKey';
    private static final String TRANSACTION_TYPE_KEY = 'transactionType';
    private static final String AMOUNT_KEY = 'amount';
    private static final String PROFILE_KEY = 'profile';
    private static final String CUSTOMER_PROFILE_ID_KEY = 'customerProfileId';
    private static final String ORDER_KEY = 'order';
    private static final String INVOICE_NUMBER_KEY = 'invoiceNumber';
    private static final String CUSTOMER_KEY = 'customer';
    private static final String EMAIL_KEY = 'email';
    private static final String BILL_TO_KEY = 'billTo';
    private static final String FIRST_NAME_KEY = 'firstName';
    private static final String LAST_NAME_KEY = 'lastName';
    private static final String ADDRESS_KEY = 'address';
    private static final String CITY_KEY = 'city';
    private static final String STATE_KEY = 'state';
    private static final String ZIP_KEY = 'zip';
    private static final String COUNTRY_KEY = 'country';
    private static final String ARB_CREATE_SUBSCRIPTION_REQUEST_KEY = 'ARBCreateSubscriptionRequest';
    private static final String SUBSCRIPTION_KEY = 'subscription';
    private static final String PAYMENT_SCHEDULE_KEY = 'paymentSchedule';
    private static final String INTERVAL_KEY = 'interval';
    private static final String LENGTH_KEY = 'length';
    private static final String UNIT_KEY = 'unit';
    private static final String START_DATE_KEY = 'startDate';
    private static final String TOTAL_OCCURRENCES_KEY = 'totalOccurrences';
    private static final String CUSTOMER_PAYMENT_PROFILE_ID_KEY = 'customerPaymentProfileId';
    private static final String CUSTOMER_ADDRESS_ID_KEY = 'customerAddressId';
    private static final String ARB_CANCEL_SUBSCRIPTION_REQUEST_KEY = 'ARBCancelSubscriptionRequest';
    private static final String SUBSCRIPTION_ID_KEY = 'subscriptionId';
    private static final String SUBSEQUENT_AUTH_INFORMATION_KEY = 'subsequentAuthInformation';
    private static final String ORIGINAL_NETWORK_TRANS_ID_KEY = 'originalNetworkTransId';
    private static final String ORIGINAL_AUTH_AMOUNT_KEY = 'originalAuthAmount';
    private static final String REASON_KEY = 'reason';
    private static final String PAYMENT_PROFILE_KEY = 'paymentProfile';
    private static final String PAYMENT_PROFILE_ID_KEY = 'paymentProfileId';
    private static final String CREATE_TRANSACTION_REQUEST_KEY = 'createTransactionRequest';
    private static final String DEFAULT_SHIPPING_ADDRESS_KEY = 'defaultShippingAddress';
    private static final String CREATE_CUSTOMER_SHIPPING_ADDRESS_REQUEST_KEY = 'createCustomerShippingAddressRequest';
    private static final String UNMASK_EXPIRATION_DATE_KEY = 'unmaskExpirationDate';
    private static final String GET_CUSTOMER_PROFILE_REQUEST_KEY = 'getCustomerProfileRequest';
    private static final String AUTHORIZENET_PAYMENT_PAGE_CONFIG = 'AuthorizeNet Payment Page Config';

    private static final String MONTHLY = 'Monthly';
    private static final String DAILY = 'Daily';
    private static final String WEEKLY = 'Weekly';
    private static final String YEARLY = 'Yearly';

    private static Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap selectedPaymentPlanLine;
    private static String selectedProcedureRecords;
    private static Boolean createSubscription;
    private static String paymentPlanId;

    public static void setPaymentPlanLine(Elixir_AuthorizeResponseWrappers.PaymentPlanLineWrap paymentPlanLine) {
        selectedPaymentPlanLine = paymentPlanLine;
    }  
    public static void setSelectedProcedures(String selectedProcedures) {
        selectedProcedureRecords = selectedProcedures;
    }  
    public static void setCreateSubscription(Boolean createSubscriptionValue) {
        createSubscription = createSubscriptionValue;
    }  
    public static void setPaymentPlanId(String paymentPlanIdValue) {
        paymentPlanId = paymentPlanIdValue;
    }  


    public static String generateCreateCustomerProfileRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
        String jsonString = '{';
        jsonString += '\"' + CREATE_CUSTOMER_PROFILE_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyObjectPair(PROFILE_KEY, generateProfile(acc));
        jsonString += '}';
        jsonString += '}';
        return jsonString;
    }

    public static String generateGetHostedPaymentPageRequest(Elixir_AuthorizeCallout authCallout,Account acc,Decimal amountToCharge,String invoiceNumber,String customerProfileId,boolean isAllocated) {
        String jsonString = '{';
        jsonString += '\"' + GET_HOSTED_PAYMENT_PAGE_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyObjectPair(TRANSACTION_REQUEST_KEY, generateTransactionRequest(acc,amountToCharge,invoiceNumber,customerProfileId)) + ', ';
        jsonString += generateKeyObjectPair(HOSTED_PAYMENT_SETTINGS_KEY, generateHostedPaymentSettings(acc.id,invoiceNumber,isAllocated));
        jsonString += '}';
        jsonString += '}';
        return jsonString;
    }

    public static String generateGetTransactionListForCustomerRequest(Elixir_AuthorizeCallout authCallout,String customerProfileId,String customerPaymentProfileId) {
        String jsonString = '{';
        jsonString += '\"' + GET_TRANSACTION_LIST_FOR_CUSTOMER_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY,  customerProfileId) + ', ';
        jsonString += generateKeyValuePair(CUSTOMER_PAYMENT_PROFILE_ID_KEY,  customerPaymentProfileId ) + ', ';
        jsonString += '\"' + SORTING_KEY + '\"' + ' : {';
        jsonString += generateKeyValuePair(ORDER_BY_KEY,  SUBMIT_TIME_UTC ) + ', ';
        jsonString += generateKeyValuePair(ORDER_DESCENDING_KEY, 'true');
        jsonString += '}, ';
        jsonString += '\"' + PAGING_KEY + '\"' + ' : {';
        jsonString += generateKeyValuePair(LIMIT_KEY, '3') + ', ';
        jsonString += generateKeyValuePair(OFFSET_KEY, '1');
        jsonString += '}';
        jsonString += '}';
        return jsonString += '}' ;
    }

    public static String generateGetUnsettledTransactionListRequest(Elixir_AuthorizeCallout authCallout) {
        String jsonString = '{';
        jsonString += '\"' + GET_UNSETTLED_TRANSACTION_LIST_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += '\"' + SORTING_KEY + '\"' + ' : {';
        jsonString += generateKeyValuePair(ORDER_BY_KEY,  SUBMIT_TIME_UTC ) + ', ';
        jsonString += generateKeyValuePair(ORDER_DESCENDING_KEY, 'true');
        jsonString += '}, ';
        jsonString += '\"' + PAGING_KEY + '\"' + ' : {';
        jsonString += generateKeyValuePair(LIMIT_KEY, '10') + ', ';
        jsonString += generateKeyValuePair(OFFSET_KEY, '1');
        jsonString += '}';
        jsonString += '}';
        return jsonString += '}' ;
    }

    public static String generateARBCreateSubscriptionRequest(Elixir_AuthorizeCallout authCallout,Account acc,ElixirSuite__Payment_Information__c paymentInfo,ElixirSuite__Payment_Plan__c paymentPlan) {
        String jsonString = '{';
        jsonString += '\"' + ARB_CREATE_SUBSCRIPTION_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        //jsonString += generateKeyValuePair(REF_ID_KEY, '\"123456\"') + ', ';
        jsonString += generateKeyObjectPair(SUBSCRIPTION_KEY, generateSubscription(acc,paymentInfo,paymentPlan));
        jsonString += '}';
        return jsonString + '}';
    }

    public static String generateARBCancelSubscriptionRequest(Elixir_AuthorizeCallout authCallout,String subscriptionId) {
        String jsonString = '{';
        jsonString += '\"' + ARB_CANCEL_SUBSCRIPTION_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyValuePair(SUBSCRIPTION_ID_KEY, subscriptionId );
        jsonString += '}';
        return jsonString + + '}';
    }

    public static String generateCreateTransactionRequest(Elixir_AuthorizeCallout authCallout,Account acc,ElixirSuite__Payment_Information__c paymentInfo,Decimal amountToCharge) {
        String jsonString = '{';
        jsonString += '\"' + CREATE_TRANSACTION_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        //jsonString += generateKeyValuePair(REF_ID_KEY, '123456') + ', ';
        jsonString += generateKeyObjectPair(TRANSACTION_REQUEST_KEY, generateTransactionRequestWithAddress(acc,paymentInfo,amountToCharge));
        jsonString += '}';
        return jsonString + '}';
    }

    public static String generateCreateCustomerShippingAddressRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
        String jsonString = '{';
        jsonString += '\"' + CREATE_CUSTOMER_SHIPPING_ADDRESS_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY, acc.Elixir_Authorize_Customer_Profile_Id__c) + ', ';
        jsonString += generateKeyObjectPair(ADDRESS_KEY, generateAddress(acc)) + ', ';
        jsonString += generateKeyValuePair(DEFAULT_SHIPPING_ADDRESS_KEY, 'false');
        jsonString += '}';
        return jsonString + '}';
    }
    
    public static String generateGetCustomerProfileRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
        String jsonString = '{';
        jsonString += '\"' + GET_CUSTOMER_PROFILE_REQUEST_KEY + '\"' + ' : {';
        jsonString += generateKeyObjectPair(MERCHANT_AUTHENTICATION_KEY, generateMerchantAuthentication(authCallout)) + ', ';
        jsonString += generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY, acc.Elixir_Authorize_Customer_Profile_Id__c) + ', ';
        jsonString += generateKeyValuePair(UNMASK_EXPIRATION_DATE_KEY, 'true');
        jsonString += '}';
        return jsonString + '}';
    }

    private static String generateTransactionRequestWithAddress(Account acc,ElixirSuite__Payment_Information__c paymentInfo,Decimal amountToCharge) {
        String transactionRequestString = '{';
        transactionRequestString += generateKeyValuePair(TRANSACTION_TYPE_KEY, AUTH_CAPTURE_TRANSACTION) + ', ';
        transactionRequestString += generateKeyValuePair(AMOUNT_KEY, String.valueOf(amountToCharge)) + ', ';
        transactionRequestString += generateKeyObjectPair(PROFILE_KEY, generateProfileTransaction(acc,paymentInfo)) + ', ';
        transactionRequestString += generateKeyObjectPair(SUBSEQUENT_AUTH_INFORMATION_KEY, generateSubsequentAuthInformation(paymentInfo));
        transactionRequestString += '}';
        return transactionRequestString;
    }

    private static String generateProfileTransaction(Account acc,ElixirSuite__Payment_Information__c paymentInfo) {
        String profileString = '{';
        profileString += generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY, String.valueOf(acc.Elixir_Authorize_Customer_Profile_Id__c)) + ', ';
        profileString += generateKeyObjectPair(PAYMENT_PROFILE_KEY, '{' + generateKeyValuePair(PAYMENT_PROFILE_ID_KEY, paymentInfo.ElixirSuite__Source_Id__c) + '}');
        profileString += '}';
        return profileString;
    }

    private static String generateSubsequentAuthInformation(ElixirSuite__Payment_Information__c paymentInfo) {
        String subsequentAuthInformationString = '{';
        subsequentAuthInformationString += generateKeyValuePair(ORIGINAL_NETWORK_TRANS_ID_KEY, paymentInfo.Elixir_Original_Network_Transaction_Id__c) + ', ';
        subsequentAuthInformationString += generateKeyValuePair(ORIGINAL_AUTH_AMOUNT_KEY, paymentInfo.Elixir_Original_Authorize_Amount__c) + ', ';
        subsequentAuthInformationString += generateKeyValuePair(REASON_KEY, RESUBMISSION);
        subsequentAuthInformationString += '}';
        return subsequentAuthInformationString;
    }

    private static String generateSubscription(Account acc,ElixirSuite__Payment_Information__c paymentInfo,ElixirSuite__Payment_Plan__c paymentPlan) {
        String subscriptionString = '{';
        subscriptionString += generateKeyValuePair(NAME_KEY, paymentPlan.Name) + ', ';
        subscriptionString += generateKeyObjectPair(PAYMENT_SCHEDULE_KEY, generatePaymentSchedule(paymentPlan)) + ', ';
        subscriptionString += generateKeyValuePair(AMOUNT_KEY, String.valueOf(paymentPlan.ElixirSuite__Installment_Amount__c)) + ', ';
        subscriptionString += generateKeyObjectPair(PROFILE_KEY, generateProfileForSubscription(acc,paymentInfo));
        subscriptionString += '}';
        return subscriptionString;
    }

    private static String generatePaymentSchedule(ElixirSuite__Payment_Plan__c paymentPlan) {
        String paymentScheduleString = '{';
        paymentScheduleString += generateKeyObjectPair(INTERVAL_KEY, generateInterval(paymentPlan)) + ', ';
        ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLine = Elixir_PaymentUtility.getPaymentPlanLine(paymentPlan.id);
        DateTime startDate = (DateTime) paymentPlanLine.ElixirSuite__Due_Date__c;
        String startDateStr = startDate.format('yyyy-MM-dd');
        paymentScheduleString += generateKeyValuePair(START_DATE_KEY, startDateStr) + ', '; 
        Integer noOfOccurrences = (Integer)(paymentPlan.ElixirSuite__Total_Balance_Due__c / paymentPlan.ElixirSuite__Installment_Amount__c);
        paymentScheduleString += generateKeyValuePair(TOTAL_OCCURRENCES_KEY, String.valueOf(noOfOccurrences)) ;
        paymentScheduleString += '}';
        return paymentScheduleString;
    }

    private static String generateInterval(ElixirSuite__Payment_Plan__c paymentPlan) {
        String unitValue;
        String lengthValue;
        if (paymentPlan.ElixirSuite__Payment_Frequency__c == YEARLY)  {		
            unitValue = 'months';
            lengthValue = '12';
        }
        else if (paymentPlan.ElixirSuite__Payment_Frequency__c == MONTHLY) {		
            unitValue = 'months';
            lengthValue = '1';
        }
        else if (paymentPlan.ElixirSuite__Payment_Frequency__c == WEEKLY) {		
            unitValue = 'days';
            lengthValue = '7';
        }
        /*when DAILY {		  
            unitValue = 'days';
            lengthValue = '1';
        }*/
        return '{' + generateKeyValuePair(LENGTH_KEY, lengthValue) + ', ' + generateKeyValuePair(UNIT_KEY, unitValue) + '}';
    }

    private static String generateProfileForSubscription(Account acc,ElixirSuite__Payment_Information__c paymentInfo) {
        return '{' + generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY, String.valueOf(acc.Elixir_Authorize_Customer_Profile_Id__c)) + ', ' + 
                      generateKeyValuePair(CUSTOMER_PAYMENT_PROFILE_ID_KEY, paymentInfo.ElixirSuite__Source_Id__c ) + ', ' +  
                      generateKeyValuePair(CUSTOMER_ADDRESS_ID_KEY, String.valueOf(acc.Elixir_Authorize_Customer_Address_Id__c)) + '}';
    }

    private static String generateProfile(Account acc) {
        String profileString = '{';
        profileString += generateKeyValuePair(DESCRIPTION_KEY, acc.Name) + ',';
        profileString += generateKeyValuePair(EMAIL_KEY , acc.ElixirSuite__Email_Id__c);
        return profileString + '}';
    }

    private static String generateMerchantAuthentication(Elixir_AuthorizeCallout authCallout) {
        return '{' + generateKeyValuePair(NAME_KEY, authCallout.getAPIKey()) + ', ' + generateKeyValuePair(TRANSACTION_KEY, authCallout.getTransactionKey()) + '}';
    }

    private static String generateTransactionRequest(Account acc,Decimal amountToCharge,String invoiceNumber,String customerProfileId) {
        String email = (acc.ElixirSuite__Email_Id__c != null ? acc.ElixirSuite__Email_Id__c : '');
        String transactionString = '{';
        transactionString += generateKeyValuePair(TRANSACTION_TYPE_KEY, AUTH_CAPTURE_TRANSACTION) + ', ';
        transactionString += generateKeyValuePair(AMOUNT_KEY, String.ValueOf(amountToCharge)) + ', ';
        transactionString += generateKeyObjectPair(PROFILE_KEY, '{' + generateKeyValuePair(CUSTOMER_PROFILE_ID_KEY, customerProfileId) + '}') + ', ';
        transactionString += generateKeyObjectPair(ORDER_KEY, '{' + generateKeyValuePair(INVOICE_NUMBER_KEY, invoiceNumber) + '}') + ', ';
        transactionString += generateKeyObjectPair(CUSTOMER_KEY, '{' + generateKeyValuePair(EMAIL_KEY, email ) + '}') + ', ';
        transactionString += generateKeyObjectPair(BILL_TO_KEY, generateAddress(acc));
        transactionString += '}';
        return transactionString;
    }

    private static String generateAddress(Account acc) {
        String billToString = '{';
        billToString += generateKeyValuePair(FIRST_NAME_KEY, acc.ElixirSuite__First_Name__c ) + ', ';
        billToString += generateKeyValuePair(LAST_NAME_KEY, acc.ElixirSuite__Last_Name__c) + ', ';
        billToString += generateKeyValuePair(ADDRESS_KEY, acc.BillingStreet) + ', ';
        billToString += generateKeyValuePair(CITY_KEY, acc.BillingCity) + ', ';
        billToString += generateKeyValuePair(STATE_KEY, acc.BillingState) + ', ';
        billToString += generateKeyValuePair(ZIP_KEY, acc.BillingPostalCode) + ', ';
        billToString += generateKeyValuePair(COUNTRY_KEY, acc.BillingCountry);
        billToString += '}';
        return billToString;
    }

    private static String generateHostedPaymentSettings(ID accId,String uniqueKey,Boolean isAllocated) {
        String settingString = '{';
        settingString += generateKeyObjectPair(SETTING_KEY, generateSettingList(accId,uniqueKey,isAllocated));
        settingString += '}';
        return settingString;
    }

    private static String generateSettingList(ID accId,String uniqueKey,Boolean isAllocated) {
        
        Elixir_Authorize_Config__mdt authCofig = getMetaDataConfig();

        // fetch instance URL for this org
        String instanceUrl = URL.getOrgDomainURL().toExternalForm();

        String selectedPaymentPlanLineJson = JSON.serialize(selectedPaymentPlanLine);

        if (selectedProcedureRecords != '' && selectedProcedureRecords != null){
            selectedProcedureRecords = selectedProcedureRecords.replace('"', '\\"');
        }

        if (selectedPaymentPlanLineJson != '' && selectedPaymentPlanLineJson != null){
            selectedPaymentPlanLineJson = selectedPaymentPlanLineJson.replace('"', '\\"');
        }

        // Converting componentDef to Base 64
        String componentDefString = '{"componentDef":"c:elixirRedirectToHome","attributes":{"accId": "'+ accId + '","uniqueKey":"'+uniqueKey+'","isAllocated":' +isAllocated +',"selectedProcedureRecords":"'+ selectedProcedureRecords +'","selectedPaymentPlanLine":"'+ selectedPaymentPlanLineJson +'","createSubscription":' + createSubscription+',"paymentPlanId":"' + paymentPlanId + '"}}';
        
        Blob blobData = Blob.valueOf(componentDefString);
        String encodedString = EncodingUtil.base64Encode(blobData);

        // Continue Url Creation
        String continueUrl = instanceUrl + '/one/one.app#' + encodedString;

        system.debug('componentDefString : ' + componentDefString);
        system.debug('continueUrl : ' + continueUrl);

        // Cancel Url Creation 
        String cancelUrl = instanceUrl + '/lightning/r/Account/' + accId + '/view';

        String settingListString = '[';
        settingListString += generateSetting('hostedPaymentReturnOptions', '{\\\"showReceipt\\\": true, \\\"url\\\": \\\"'+ continueUrl +'\\\", \\\"urlText\\\": \\\"'+ authCofig.Elixir_Continue_Button_Label__c + '\\\", \\\"cancelUrl\\\": \\\"'+ cancelUrl + '\\\", \\\"cancelUrlText\\\": \\\"'+ authCofig.Elixir_Cancel_Button_Label__c + '\\\"}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentButtonOptions', '{\\\"text\\\": \\\"'+ authCofig.Elixir_Pay_Button_Label__c + '\\\"}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentStyleOptions', '{\\\"bgColor\\\": \\\"blue\\\"}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentPaymentOptions', '{\\\"cardCodeRequired\\\": true, \\\"showCreditCard\\\": true, \\\"showBankAccount\\\": false}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentSecurityOptions', '{\\\"captcha\\\": false}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentShippingAddressOptions', '{\\\"show\\\": false, \\\"required\\\": false}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentBillingAddressOptions', '{\\\"show\\\": true, \\\"required\\\": false}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentCustomerOptions', '{\\\"showEmail\\\": true, \\\"requiredEmail\\\": false, \\\"addPaymentProfile\\\": true}');
        settingListString += ', ';
        settingListString += generateSetting('hostedPaymentOrderOptions', '{\\\"show\\\": true, \\\"merchantName\\\": \\\"'+ authCofig.Elixir_Merchant_Name__c + '\\\"}');
        settingListString += ']';
        
        return settingListString;
    }

    private static Elixir_Authorize_Config__mdt getMetaDataConfig(){
        return [SELECT id,Elixir_Cancel_Button_Label__c, Elixir_Continue_Button_Label__c, Elixir_Merchant_Name__c, Elixir_Pay_Button_Label__c FROM Elixir_Authorize_Config__mdt WHERE Label =: AUTHORIZENET_PAYMENT_PAGE_CONFIG WITH SECURITY_ENFORCED ];
    }
    private static String generateSetting(String name, String value) {
        return '{' + generateKeyValuePair(SETTING_NAME_KEY, name) + ', ' + generateKeyValuePair(SETTING_VALUE_KEY, value) + '}';
    }

    private static String generateKeyValuePair(String key, String value) {
        return '\"' + key + '\"' + ' : ' + '\"' + value + '\"';
    }

    private static String generateKeyObjectPair(String key, String value) {
        return '\"' + key + '\"' + ' : '  + value + ' ';
    }
    
}
@isTest
public class Elixir_AuthorizeRequestGenerator_Test {

    @TestSetup
    static void datasetup() {
        Account acc = new Account();
        acc.Name = 'Test First Name Test Last Name';
        acc.ElixirSuite__First_Name__c = 'Test First Name';
        acc.ElixirSuite__Last_Name__c = 'Test Last Name';
        acc.ElixirSuite__Email_Id__c = 'TestName@elixir.com';
        acc.Elixir_Authorize_Customer_Profile_Id__c = '123456789';
        acc.Elixir_Authorize_Customer_Address_Id__c = '987654321';
        acc.BillingCity = 'Huntington Beach';
        acc.BillingCountry = 'USA';
        acc.BillingPostalCode = '92646'; 
        acc.BillingState = 'CA';
        acc.BillingStreet = 'E-11 Newland';
        insert acc;
        
        Integration_Credentials__c integrationCreds = new Integration_Credentials__c(
            Name = 'Authorization Dot Net Test',
            Integration_Key__c = 'TestIntegrationKey',
            Elixir_Transaction_Key__c = 'TestTransactionKey',
            EndPointURL__c = 'TestEndpointURL',
            Elixir_Active__c = true
        );
        insert integrationCreds;
    
    }
    
    @isTest
    static void TestGenerateCreateCustomerProfileRequest() {
    	Account acc = getAccount(); 
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateCreateCustomerProfileRequest(authCallout,acc);
        Test.stopTest();
        String expectedString = '{"createCustomerProfileRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "profile" : {"description" : "Test First Name Test Last Name","email" : "testname@elixir.com"} }}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestMisc() {
    	Elixir_AuthorizeRequestGenerator.setPaymentPlanLine(null);
        Elixir_AuthorizeRequestGenerator.setSelectedProcedures(null);
        Elixir_AuthorizeRequestGenerator.setPaymentPlanId(null);
        Elixir_AuthorizeRequestGenerator.setCreateSubscription(null);
    }
    
    @isTest
    static void TestGenerateGetHostedPaymentPageRequest() {
    	Account acc = getAccount();
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateGetHostedPaymentPageRequest(authCallout,acc,10.0,'INV000023','123456789',true);
        Test.stopTest();
        //String expectedString;
        //Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateGetTransactionListForCustomerRequest() {
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateGetUnsettledTransactionListRequest(authCallout);
        Test.stopTest();
        String expectedString = '{"getUnsettledTransactionListRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "sorting" : {"orderBy" : "submitTimeUTC", "orderDescending" : "true"}, "paging" : {"limit" : "10", "offset" : "1"}}}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateARBCreateSubscriptionRequest() {
    	Account acc = getAccount(); 
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        ElixirSuite__Payment_Information__c paymentInfo = new ElixirSuite__Payment_Information__c();
        paymentInfo.Elixir_Original_Authorize_Amount__c = '10.0';
        paymentInfo.Elixir_Original_Network_Transaction_Id__c = '456123789';
        paymentInfo.ElixirSuite__Source_Id__c = '85412637';
        ElixirSuite__Payment_Plan__c  paymentPlanRecord = new ElixirSuite__Payment_Plan__c();
        paymentPlanRecord.ElixirSuite__Patient_Name__c = acc.id;
        paymentPlanRecord.ElixirSuite__Installment_Amount__c = 100;
        paymentPlanRecord.ElixirSuite__Patient_Responsibility__c = 1000;
        paymentPlanRecord.ElixirSuite__Status__c = 'Active';
        paymentPlanRecord.ElixirSuite__Payment_Frequency__c = 'Monthly';
        insert paymentPlanRecord;
        ElixirSuite__Payment_Plan__c  paymentPlanNew = Elixir_PaymentUtility.getPaymentPlan(paymentPlanRecord.id);
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateARBCreateSubscriptionRequest(authCallout,acc,paymentInfo,paymentPlanNew);
        Test.stopTest();
        String expectedString = '{"ARBCreateSubscriptionRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "subscription" : {"name" : "PP-100001", "paymentSchedule" : {"interval" : {"length" : "1", "unit" : "months"} , "startDate" : "2024-04-12", "totalOccurrences" : "10"} , "amount" : "100.00", "profile" : {"customerProfileId" : "123456789", "customerPaymentProfileId" : "85412637", "customerAddressId" : "987654321"} } }}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateARBCancelSubscriptionRequest() {
    	Account acc = getAccount();
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateARBCancelSubscriptionRequest(authCallout,'subId');
        Test.stopTest();
        String expectedString = '{"ARBCancelSubscriptionRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "subscriptionId" : "subId"}}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateCreateTransactionRequest() {
    	Account acc = getAccount(); 
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        ElixirSuite__Payment_Information__c paymentInfo = new ElixirSuite__Payment_Information__c();
        paymentInfo.Elixir_Original_Authorize_Amount__c = '10.0';
        paymentInfo.Elixir_Original_Network_Transaction_Id__c = '456123789';
        paymentInfo.ElixirSuite__Source_Id__c = '85412637';
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateCreateTransactionRequest(authCallout,acc,paymentInfo,10.0);
        Test.stopTest();
        String expectedString = '{"createTransactionRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "transactionRequest" : {"transactionType" : "authCaptureTransaction", "amount" : "10.0", "profile" : {"customerProfileId" : "123456789", "paymentProfile" : {"paymentProfileId" : "85412637"} } , "subsequentAuthInformation" : {"originalNetworkTransId" : "456123789", "originalAuthAmount" : "10.0", "reason" : "resubmission"} } }}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateCreateCustomerShippingAddressRequest() {
    	Account acc = getAccount(); 
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateCreateCustomerShippingAddressRequest(authCallout,acc);
        Test.stopTest();
        String expectedString = '{"createCustomerShippingAddressRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "customerProfileId" : "123456789", "address" : {"firstName" : "Test First Name", "lastName" : "Test Last Name", "address" : "E-11 Newland", "city" : "Huntington Beach", "state" : "CA", "zip" : "92646", "country" : "USA"} , "defaultShippingAddress" : "false"}}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    @isTest
    static void TestGenerateGetCustomerPaymentProfileRequest() {
    	Account acc = getAccount(); 
        Elixir_AuthorizeCallout authCallout; authCallout = new Elixir_AuthorizeCallout();
        Test.startTest();
        String jsonString = Elixir_AuthorizeRequestGenerator.generateGetCustomerProfileRequest(authCallout,acc);
        Test.stopTest();
        String expectedString = '{"getCustomerProfileRequest" : {"merchantAuthentication" : {"name" : "TestIntegrationKey", "transactionKey" : "TestTransactionKey"} , "customerProfileId" : "123456789", "unmaskExpirationDate" : "true"}}';
        Assert.areEqual(expectedString,jsonString,'Generated Json does not match');
    }
    
    
    static Account getAccount() {
        return [SELECT id,Name,Elixir_Authorize_Customer_Address_Id__c,Elixir_Authorize_Customer_Profile_Id__c,ElixirSuite__First_Name__c,ElixirSuite__Last_Name__c,
                BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,ElixirSuite__Email_Id__c FROM Account WITH SECURITY_ENFORCED LIMIT 1];
    }
    
}
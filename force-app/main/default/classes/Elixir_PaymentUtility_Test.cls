@isTest
private class Elixir_PaymentUtility_Test {
    
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
        
        ElixirSuite__Payment_Information__c paymentInfo = new ElixirSuite__Payment_Information__c();
        paymentInfo.ElixirSuite__Account__c = acc.id;
        paymentInfo.ElixirSuite__Source_Id__c = '123456789';
        insert paymentInfo;
    }
    
    @isTest
    static void testGetterMethods(){
        Account acc = [Select id from Account];
        
        ElixirSuite__Payment_Plan__c paymentPlan = new ElixirSuite__Payment_Plan__c();
        insert paymentPlan;
        
        ElixirSuite__Payment_Plan_Line_Item__c paymentPlanLineItem = new ElixirSuite__Payment_Plan_Line_Item__c(); 
        paymentPlanLineItem.ElixirSuite__Payment_Plan__c = paymentPlan.id;
        insert paymentPlanLineItem;
        
        Elixir_PaymentUtility.getPaymentInfowithAccountId(acc.id);
        Elixir_PaymentUtility.getPaymentPlan(paymentPlan.id);
        Elixir_PaymentUtility.getPaymentPlanLine(paymentPlan.id);
    }

    @isTest
    static void testUpdatePaymentPlanAfterCreateSubscription() {
        // Test data setup
        ElixirSuite__Payment_Plan__c paymentPlan = new ElixirSuite__Payment_Plan__c();
        insert paymentPlan;

        // Call the updatePaymentPlanAfterCreateSubscription method
        Test.startTest();
        Elixir_PaymentUtility.updatePaymentPlanAfterCreateSubscription('TestSubscriptionId', paymentPlan.Id,'5456456');
        Test.stopTest();

        // Verify payment plan is updated
        paymentPlan = [SELECT Id, Elixir_External_Subscription_ID__c, ElixirSuite__Status__c FROM ElixirSuite__Payment_Plan__c WHERE Id = :paymentPlan.Id];
        System.assertEquals('TestSubscriptionId', paymentPlan.Elixir_External_Subscription_ID__c, 'Elixir_External_Subscription_ID__c is incorrect.');
        System.assertEquals('Active', paymentPlan.ElixirSuite__Status__c, 'Payment plan status is incorrect.');
    }

    @isTest
    static void testUpdatePaymentPlanAfterCancelSubscription() {
        // Test data setup
        ElixirSuite__Payment_Plan__c paymentPlan = new ElixirSuite__Payment_Plan__c(ElixirSuite__Status__c = 'Active');
        insert paymentPlan;

        // Call the updatePaymentPlanAfterCancelSubscription method
        Test.startTest();
        Elixir_PaymentUtility.updatePaymentPlanAfterCancelSubscription(paymentPlan.Id);
        Test.stopTest();

        // Verify payment plan is updated
        paymentPlan = [SELECT Id, ElixirSuite__Status__c FROM ElixirSuite__Payment_Plan__c WHERE Id = :paymentPlan.Id];
        System.assertEquals('Inactive', paymentPlan.ElixirSuite__Status__c, 'Payment plan status is incorrect.');
    }

    @isTest
    static void testGetPaymentInfo() {
        // Test data setup
        ElixirSuite__Payment_Information__c paymentInfo = new ElixirSuite__Payment_Information__c();
        insert paymentInfo;

        // Call the getPaymentInfo method
        Test.startTest();
        ElixirSuite__Payment_Information__c result = Elixir_PaymentUtility.getPaymentInfo(paymentInfo.Id);
        Test.stopTest();

        // Verify payment info is retrieved
        System.assertNotEquals(null, result, 'Payment information not retrieved.');
    }

    @isTest
    static void testCreatePaymentInformation() {
        Account acc = [Select id from Account];
        // Test data setup
        Elixir_AuthorizeResponseWrappers.Transactions transactionRec = new Elixir_AuthorizeResponseWrappers.Transactions();
        transactionRec.profile = new Elixir_AuthorizeResponseWrappers.Profile();
        transactionRec.profile.customerPaymentProfileId = 'TestPaymentProfileId';
        transactionRec.settleAmount = 100;
        transactionRec.transId = 'TestTransId';
        transactionRec.accountNumber = 'TestAccountNumber';
        transactionRec.accountType = 'Visa';
        String jsonString = '{"profile":{"paymentProfiles":[{"customerPaymentProfileId":"917976729","payment":{"creditCard":{"cardNumber":"XXXX1111","expirationDate":"2030-03","cardType":"Visa"}},"billTo":{"firstName":"Test Api","lastName":"Test","address":"E-11 Newland","city":"Huntington Beach","state":"CA","zip":"92646","country":"US"}}],"profileType":"regular","customerProfileId":"918490719","description":"Faisal Test Patient 2","email":"faisal1sdas@mirketa.com"},"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}';
        Elixir_AuthorizeResponseWrappers paymentResWrapper = (Elixir_AuthorizeResponseWrappers) JSON.deserialize(jsonString,Elixir_AuthorizeResponseWrappers.class);
        paymentResWrapper.paymentProfile = new Elixir_AuthorizeResponseWrappers.PaymentProfile();
        paymentResWrapper.paymentProfile.payment = new Elixir_AuthorizeResponseWrappers.Payment();
        paymentResWrapper.paymentProfile.payment.creditCard = new Elixir_AuthorizeResponseWrappers.CreditCard();
        paymentResWrapper.paymentProfile.payment.creditCard.expirationDate = '2024-12';

        // Call the createPaymentInformation method
        Test.startTest();
        Elixir_PaymentUtility.createPaymentInformation(transactionRec,acc.id, paymentResWrapper);
        Test.stopTest();

        // Verify payment information is created
        List<ElixirSuite__Payment_Information__c> paymentInfos = [SELECT Id FROM ElixirSuite__Payment_Information__c];
        System.assertEquals(2, paymentInfos.size(), 'Payment information not created.');
    }
    
}
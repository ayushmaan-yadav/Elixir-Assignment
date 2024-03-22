@isTest
private class Elixir_TransactionUtility_Test {

    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test First Name Test Last Name';
        acc.ElixirSuite__First_Name__c = 'Test First Name';
        acc.ElixirSuite__Last_Name__c = 'Test Last Name';
        acc.ElixirSuite__Email_Id__c = 'TestName@elixir.com';
        acc.BillingCity = 'Huntington Beach';
        acc.BillingCountry = 'USA';
        acc.BillingPostalCode = '92646'; 
        acc.BillingState = 'CA';
        acc.BillingStreet = 'E-11 Newland';
        insert acc;
    }

    @isTest
    static void testInsertTransactionBeforePayment() {
        // Test data setup
        String accId = [SELECT Id FROM Account WITH SECURITY_ENFORCED].id;
        Decimal amountToCharge = 100;
        String procedureId = 'TestProcedureId';
        String uniqueKey = 'TestUniqueKey';
        String externalTransId = 'TestExternalTransId';
        Elixir_AuthorizeResponseWrappers resWrapper = new Elixir_AuthorizeResponseWrappers();
        resWrapper.messages = new Elixir_AuthorizeResponseWrappers.Messages();
        resWrapper.messages.resultCode = 'Ok';

        // Call the insertTransactionBeforePayment and updateTransactionAfterPayment method 
        Test.startTest();
        Elixir_TransactionUtility.insertTransactionBeforePayment(accId, amountToCharge, procedureId, uniqueKey);
        Elixir_TransactionUtility.updateTransactionAfterPayment(uniqueKey, externalTransId, resWrapper);
        Test.stopTest();

        // Verify transactions are inserted
        List<ElixirSuite__Transactions__c> transactions = [SELECT Id FROM ElixirSuite__Transactions__c];
        System.assertNotEquals(0, transactions.size(), 'Transactions not inserted.');
        for (ElixirSuite__Transactions__c transactionRec : transactions) {
            System.assertEquals('Successful', transactionRec.ElixirSuite__Payment_Status__c, 'Transaction status is incorrect.');
        }
    }

    @isTest
    static void testInsertTransactionAfterPayment() {
        // Test data setup
        String accId = [SELECT Id FROM Account WITH SECURITY_ENFORCED].id;
        Decimal amountToCharge = 100;
        String procedureId = 'TestProcedureId';
        String uniqueKey = 'TestUniqueKey';
        String externalTransId = 'TestExternalTransId';
        Elixir_AuthorizeResponseWrappers resWrapper = new Elixir_AuthorizeResponseWrappers();
        resWrapper.messages = new Elixir_AuthorizeResponseWrappers.Messages();
        resWrapper.messages.resultCode = 'Ok';

        // Call the insertTransactionAfterPayment method
        Test.startTest();
        Elixir_TransactionUtility.insertTransactionAfterPayment(accId, amountToCharge, procedureId, uniqueKey, externalTransId, resWrapper);
        Test.stopTest();

        // Verify transactions are inserted
        List<ElixirSuite__Transactions__c> transactions = [SELECT Id FROM ElixirSuite__Transactions__c];
        System.assertNotEquals(0, transactions.size(), 'Transactions not inserted.');
    }

    @isTest
    static void testInsertOtherTransactionBeforePayment() {
        // Test data setup
        String accId = [SELECT Id FROM Account WITH SECURITY_ENFORCED].id;
        Decimal amountToCharge = 100;
        String uniqueKey = 'TestUniqueKey';

        // Call the insertOtherTransactionBeforePayment method
        Test.startTest();
        Elixir_TransactionUtility.insertOtherTransactionBeforePayment(accId, amountToCharge, uniqueKey);
        Test.stopTest();

        // Verify other transaction is inserted
        List<ElixirSuite__Master_Transaction__c> otherTransactions = [SELECT Id FROM ElixirSuite__Master_Transaction__c];
        System.assertNotEquals(0, otherTransactions.size(), 'Other transaction not inserted.');
    }

    @isTest
    static void testInsertOtherTransactionAfterPayment() {
        // Test data setup
        String accId = [SELECT Id FROM Account WITH SECURITY_ENFORCED].id;
        Decimal amountToCharge = 100;
        String uniqueKey = 'TestUniqueKey';
        String externalTransId = 'TestExternalTransId';
        Elixir_AuthorizeResponseWrappers resWrapper = new Elixir_AuthorizeResponseWrappers();
        resWrapper.messages = new Elixir_AuthorizeResponseWrappers.Messages();
        resWrapper.messages.resultCode = 'Ok';

        // Call the insertOtherTransactionAfterPayment method
        Test.startTest();
        Elixir_TransactionUtility.insertOtherTransactionAfterPayment(accId, amountToCharge, uniqueKey, externalTransId, resWrapper);
        Test.stopTest();

        // Verify other transaction is inserted
        List<ElixirSuite__Master_Transaction__c> otherTransactions = [SELECT Id FROM ElixirSuite__Master_Transaction__c];
        System.assertNotEquals(0, otherTransactions.size(), 'Other transaction not inserted.');
    }

    // Add more test methods as needed for other methods in Elixir_TransactionUtility class
}
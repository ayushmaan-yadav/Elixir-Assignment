@isTest
public with sharing class Elixir_AccountUtility_Test {

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
    static void updateCustomerProfileIdTest() {
        Account acc = [SELECT ID,Elixir_Authorize_Customer_Profile_Id__c FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        String customerProfileId = '102456978';
        Test.startTest();
        Elixir_AccountUtility.updateCustomerProfileId(acc.id,customerProfileId);
        Test.stopTest();
        Account updatedAcc = [SELECT ID,Elixir_Authorize_Customer_Profile_Id__c FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        Assert.areEqual(customerProfileId, updatedAcc.Elixir_Authorize_Customer_Profile_Id__c, 'Customer Profile Id was not set correctly');
    }

    @isTest
    static void updateCustomerAddressIdTest() {
        Account acc = [SELECT ID,Elixir_Authorize_Customer_Address_Id__c FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        String customerAddressId = '102456978';
        Test.startTest();
        Elixir_AccountUtility.updateCustomerAddressId(acc.id,customerAddressId);
        Test.stopTest();
        Account updatedAcc = [SELECT ID,Elixir_Authorize_Customer_Address_Id__c FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        Assert.areEqual(customerAddressId, updatedAcc.Elixir_Authorize_Customer_Address_Id__c, 'Customer Address Id was not set correctly');
    }

    @isTest
    static void getAccountTest() {
        Account acc = [SELECT ID FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        Test.startTest();
        Account retrivedAccout = Elixir_AccountUtility.getAccount(acc.id);
        Test.stopTest();
        Assert.isNotNull(retrivedAccout, 'Account is null');
    }

}
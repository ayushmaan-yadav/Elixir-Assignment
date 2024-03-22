/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AccountUtility {
    
    /**
    * @description Updates the Account with CustomerProfileId
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID, @param String customerProfileId 
    * @returns None
    **/
    public static void updateCustomerProfileId(String accID,String customerProfileId) {
        Account acc = new Account(Id = accID);
        acc.Elixir_Authorize_Customer_Profile_Id__c = customerProfileId;
        Elixir_DMLManager.updateAsUser(acc);
    }

    /**
    * @description Updates the Account with customerAddressId
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID, @param String customerAddressId 
    * @returns None
    **/
    public static void updateCustomerAddressId(String accID,String customerAddressId) {
        Account acc = new Account(Id = accID);
        acc.Elixir_Authorize_Customer_Address_Id__c = customerAddressId;
        Elixir_DMLManager.updateAsUser(acc);
    }

    /**
    * @description Updates the Account with customerAddressId
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID 
    * @returns Account
    **/
    public static Account getAccount(String accID) {
        return [SELECT id,Name,Elixir_Authorize_Customer_Address_Id__c,Elixir_Authorize_Customer_Profile_Id__c,ElixirSuite__First_Name__c,ElixirSuite__Last_Name__c,
                BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,ElixirSuite__Email_Id__c FROM Account WHERE Id=:accID WITH SECURITY_ENFORCED LIMIT 1];
    }

}
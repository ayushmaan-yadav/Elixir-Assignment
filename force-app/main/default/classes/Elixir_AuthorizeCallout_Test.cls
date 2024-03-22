@isTest
public with sharing class Elixir_AuthorizeCallout_Test {

    @isTest
    static void testConstructor() {
        // Test data setup - Integration Credentials record
        Integration_Credentials__c integrationCreds = new Integration_Credentials__c(
            Name = 'Authorization Dot Net Test',
            Integration_Key__c = 'TestIntegrationKey',
            Elixir_Transaction_Key__c = 'TestTransactionKey',
            EndPointURL__c = 'TestEndpointURL',
            Elixir_Active__c = true
        );
        insert integrationCreds;

        // Call the constructor
        Test.startTest();
        Elixir_AuthorizeCallout authorizeCallout = new Elixir_AuthorizeCallout();
        Test.stopTest();

        // Verify integration credentials are set correctly
        System.assertEquals('TestIntegrationKey', authorizeCallout.getAPIKey(),'Intergration Key is Wrong');
        System.assertEquals('TestTransactionKey', authorizeCallout.getTransactionKey(),'Transaction Key is Wrong');
    }

    @isTest
    static void testSendRequest() {
        // Test data setup - Integration Credentials record
        Integration_Credentials__c integrationCreds = new Integration_Credentials__c(
            Name = 'Authorization Dot Net Test',
            Integration_Key__c = 'TestIntegrationKey',
            Elixir_Transaction_Key__c = 'TestTransactionKey',
            EndPointURL__c = 'TestEndpointURL',
            Elixir_Active__c = true
        );
        insert integrationCreds;

        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new Elixir_HttpMock());

        // Call the sendRequest method
        Test.startTest();
        Elixir_AuthorizeCallout authorizeCallout = new Elixir_AuthorizeCallout();
        HttpResponse res = authorizeCallout.sendRequest('TestRequestJson');
        Test.stopTest();

        // Verify response
        System.assertNotEquals(null, res, 'HTTP Response was null');
        System.assertEquals(200, res.getStatusCode(), 'Incorrect Status Code');
    }
}
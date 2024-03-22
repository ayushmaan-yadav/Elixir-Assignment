@isTest
public with sharing class Elixir_AuthPaymentTerminalCont_Test {
    @isTest
    static void testConstructor() {
        // Create test data - Integration Credential record
        Integration_Credentials__c credential = new Integration_Credentials__c(
            Name = 'Authorization Dot Net Test',
            Elixir_VFPAGE_EndPointURL__c = 'TestEndpointURL',
            Elixir_Active__c = true
        );
        insert credential;

        // Prepare test page reference with parameters
        PageReference pageRef = Page.Elixir_AuthorizePaymentTerminal; 
        Test.setCurrentPage(pageRef);
        Blob encodedBlob = Blob.valueOf('yourDecodedTokenHere');
        String base64EncodedString = EncodingUtil.base64Encode(encodedBlob);
        pageRef.getParameters().put('token', base64EncodedString);

        // Call the controller constructor
        Test.startTest();
        Elixir_AuthPaymentTerminalController controller = new Elixir_AuthPaymentTerminalController();
        Test.stopTest();

        // Verify the controller properties are set correctly
        System.assertEquals('yourDecodedTokenHere', controller.token,'Token  is not decoded and assigned to the property');
        System.assertEquals(Label.ElixirRedirectingToPaymentPage, controller.navigationText,'Navigation Text is incorrect'); 
        System.assertEquals('TestEndpointURL', controller.endpointURL,'Test Endpoint URL is wrong');
    }
    
}
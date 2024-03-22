/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthPaymentTerminalController {
    
    public String token { get; set; }
    public String navigationText { get; set; }
    public String endpointURL { get; set; }

     /**
    * @description Constructor for the Controller.
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None
    * @returns None
    **/
    public Elixir_AuthPaymentTerminalController() {
        // Retrieve the token from the URL parameters
        Integration_Credentials__c cred= [SELECT Elixir_VFPAGE_EndPointURL__c FROM Integration_Credentials__c WHERE Name LIKE 'Authorization Dot Net%' AND Elixir_Active__c = true WITH SECURITY_ENFORCED LIMIT 1];
        token = ApexPages.currentPage().getParameters().get('token');
        Blob decodedBlob;
        try {
            decodedBlob = EncodingUtil.base64Decode(token);
        } catch(Exception e) { 
            system.debug('Error while Decoding the token');
        }
        
		token = decodedBlob.toString();
        navigationText = Label.ElixirRedirectingToPaymentPage;
        endpointURL = cred.Elixir_VFPAGE_EndPointURL__c;
    }

}
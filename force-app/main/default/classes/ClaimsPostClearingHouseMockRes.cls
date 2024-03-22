@isTest
global class ClaimsPostClearingHouseMockRes implements HttpCalloutMock{
    
     public String ClaimName;
    public String chgId;
    public ClaimsPostClearingHouseMockRes(String ClaimName)
    {
        this.ClaimName = ClaimName;
        
    }
     global HTTPResponse respond(HTTPRequest request) {
         String body = '<claims><claim remote_claimid="'+ClaimName+'" pcn="Claim0576" pat_name_l="David" pat_name_f="Beckam" bill_npi="null" payerid="null" payer_name="LIC" ins_number="null" pat_dob="05-10-1981" pat_sex="M" ins_name_f="Beckam" ins_name_l="Beckam" payer_order="Primary" pat_addr_1="Noida"/></claims>';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        response.setStatusCode(200);
        return response;
    }

}
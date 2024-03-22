@isTest
global class CreateERAMockRes implements HttpCalloutMock{
    
     global HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String xml= '<result last_eraid="13982442"><era check_number="275575322-1595017362" check_type="eft" claimmd_prov_name="ATHENA DIAGNOSTICS, INC." download_time="12-07-2020 02:11" eraid="12950739" paid_amount="3795.00" paid_date="2020-07-17" payer_name="1199 NATIONAL BENEFIT FUND" payerid="13162" prov_name="ATHENA" prov_npi="1831234939" prov_taxid="123456789" received_time="07-17-2020 16:22" /></result>';
            response.setBody(xml);
            response.setStatusCode(200);
            return response;
        }

}
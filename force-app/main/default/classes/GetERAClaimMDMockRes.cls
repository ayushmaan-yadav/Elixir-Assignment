@isTest
global class GetERAClaimMDMockRes implements HttpCalloutMock{
    
    public String pcn;
    public String chgId;
    public GetERAClaimMDMockRes(String pcn, String chgId)
    {
        this.pcn = pcn;
        this.chgId = chgId;
    }
        global HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            	String xml = '<result check_number="285615367-1603098030" eraid="13982442" paid_amount="725.00" paid_date="2020-10-19" payer_account="700000000" payer_addr_1="" payer_city="" payer_companyid="" payer_name="1199 NATIONAL BENEFIT FUND" payer_routing="111111111" payer_state="" payer_zip="" payerid="13162" payment_format="CCP"><claim crossover_carrier="" crossover_id="" from_dos="20200528" ins_name_f="BOB567" ins_name_l="DEADMAN" ins_number="1232" pat_name_f="BOB567" pat_name_l="DEADMAN" payer_icn="285615367" pcn="'+pcn+'" prov_npi="0" status_code="1" thru_dos="" total_charge="200" total_paid="145"><charge allowed="160" charge="200" chgid="'+chgId+'" from_dos="20200528" mod1="" mod2="" mod3="" mod4="" paid="145" proc_code="G0001" thru_dos="" units="1"><adjustment amount="40" code="45" group="CO"/></charge></claim></result>';
            response.setBody(xml);
            response.setStatusCode(200);
            return response;
        }

}
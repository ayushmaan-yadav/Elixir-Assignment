public class ElixirOEM_BenifitTypeResponseDomain1 {
    public class cls_benefit {
        public String benefit_code {get; set;}	//30
        public String benefit_coverage_code {get; set;}	//1
        public String benefit_coverage_description {get; set;}	//Active Coverage
        public String benefit_description {get; set;}	//Health Benefit Plan Coverage 
        public String benefit_period_description {get; set;}
        public String benefit_amount {get; set;}
        public String benefit_level_description{get; set;} // Individual
        public String benefit_notes {get; set;}	//FUNDING TYPE = FULLY INSURED
        public String  benefit_level_code{get; set;}
        public String date_of_last_update {get; set;}	//20160702
        public String insurance_plan {get; set;}	//AETNA CHOICE PLUS
        public String insurance_type_code {get; set;}	//C1
        public String insurance_type_description{get; set;}	//Commercial
        public String entity_addr_1{get; set;}	//P.O. BOX 30555
        public String entity_city{get; set;}	//SALT LAKE CITY
        public String entity_code{get; set;}	//PR
        public String entity_description{get; set;}	//Payer
        public String entity_name{get; set;}	//AETNA
        public String entity_state{get; set;}	//UT
        public String entity_zip{get; set;}	//841300555
        public String inplan_network{get; set;} 
        public String benefit_percent{get; set;} 
        /****CUSTOM KEYS FOR ITERATION****/
        public String in_out_planNetwork{get; set;}
        public String benefit_period_code_toText {get;set;}
    }
    public class ParentDomain {
        public String benefit_description{get; set;}
        public String code{get; set;}
        public List<cls_benefit> benifitLst{get; set;}
    }
    public class root {
        public String code{get; set;} // CHORPRACTER ETC
        public String benefit_description{get; set;}
        public List<SubRoot> lst_benefit_level_code{get; set;} // IND,FAM,ETC
        
    }
    public class SubRoot {
        public String benefit_level_code{get;set;}// IND,FAM,ETC
        public String benefit_coverage_description{get;set;}
        public Map<String,List<cls_benefit>> mapOfCodeAndData {get;set;}
        public List<cls_benefit> lst_inplan_network {get;set;} // y,n
    }
    public class Sub_Sub_Root {
        public List<cls_benefit> inplan_network{get;set;}
    }
    
}
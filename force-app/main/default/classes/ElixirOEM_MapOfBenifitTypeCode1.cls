public class ElixirOEM_MapOfBenifitTypeCode1 {
    public static Map<String,String> benifitTypeCodeMap = new Map<String,String> {
        '33'  => 'Chiropractic',
        '30' =>'Health Benefit Plan Coverage'
        };
            
            
            
            public static Map<String,String> benefitLevelCodeMap = new Map<String,String> { 
                'IND'  => 'Individual',
                'FAM' => 'Family'
                };
                    
                    public static Map<String,String> benefitPeriodCode = new Map<String,String> { 
                        '6'=>'Hour',
                            '7'=>'Day',
                            '13'=>'24 Hours',
                            '21'=>'Years', 
                            '22'=>'Service Year',
                            '23'=>'Calendar Year',
                            '24'=>'Year To Date',
                            '25'=>'Contract',
                            '26'=>'Episode',
                            '27'=>'Visit',
                            '28'=>'Outlier',
                            '29'=>'Remaining',
                            '30'=>'Exceeded'
                            };
                                public static List<String> inPlanNetworkValues = new List<String>{'Y','N'};
                                    public static Map<String,String> planNetworkMap = new Map<String,String> {
                                        'Y'=>'In-Plan-Network',
                                            'N'=>'Out-Of-Plan-Network',
                                            'W' =>''
                                            };
}
public with sharing class XMLResponseParserClaimMD {
    
    public static string xmlToJson(String xml) {
        System.debug('xml===='+xml);
        //JsonClaimResponse jsonResp = new JsonClaimResponse();
        //System.debug('jsonRespjsonResp=='+jsonResp);
        Dom.Document doc = new Dom.Document();
        System.debug('doc==='+doc);
        doc.load(xml);
        Dom.XMLNode root = doc.getRootElement();
        system.debug('#### Root  ' + root);
        String finalJson = '{';
        List<String> mainJson = new List<String>();
        try{
        if ( root.getNodeType() == Dom.XmlNodeType.ELEMENT ){
            List<Dom.XMLNode> children = root.getChildElements();
            finalJson += '"' + 'claim' + '": ' + '[';
            for(Dom.XMLNode child :children){
                String claimJson = '';
                system.debug(child.getName());//claim
                //Adding to show duplicacy
                claimJson += '{';
                List<String> firstAttributes = new List<String>();
                for(Integer i=0;i<child.getAttributeCount();i++){ 
                    String key = child.getAttributeKeyAt(i);
                    String value = child.getAttribute( key, '' );
                    firstAttributes.add( '"' + key + '": "' + value + '"' ); 
                }
                if(firstAttributes.size()>0){
                    claimJson += String.join(firstAttributes,',');
                }
                claimJson += ',';
                claimJson += '"' + 'messages' + '": ' + '[';
                List<String> allMessages = new List<String>();
                for(Dom.XMLNode secondChild :child.getChildElements()){ 
                    system.debug(secondChild.getName());//messages
                    List<String> lstAttributes = new List<String>();                    
                    for(Integer i=0;i<secondChild.getAttributeCount();i++){
                        String key = secondChild.getAttributeKeyAt(i);
                         System.debug('key '+key);
                        String value = secondChild.getAttribute( key, '' );
                        value = value.replaceAll('["]', '');
                        System.debug('value '+value);
                        if(i == 0){
                            lstAttributes.add('{' + '"' + key + '": "' + value + '"' );
                        }else{
                            lstAttributes.add( '"' + key + '": "' + value + '"' );
                        }
                        if(i == secondChild.getAttributeCount()-1){
                            lstAttributes[i] += '}';
                        }
                    }
                    if(lstAttributes.size()>0){
                        allMessages.add(String.join(lstAttributes,','));
                    }          
                }  
                claimJson += String.join(allMessages,',') +']}';
                mainJson.add(claimJson);
            }      
            finalJson += String.join(mainJson,',') + ']}'; 
            system.debug('#### finalJson : '+finalJson);     
            
        }
        }
        catch(Exception e){
           // ExceptionLog.logError(e);
        }
        return finalJson;
    }
    
    public static string xmlToJsonParent(String xml) {
        System.debug('xml===='+xml);
        //JsonClaimResponse jsonResp = new JsonClaimResponse();
        //System.debug('jsonRespjsonResp=='+jsonResp);
        Dom.Document doc = new Dom.Document();
        System.debug('doc==='+doc);
        doc.load(xml);
        Dom.XMLNode root = doc.getRootElement();
        system.debug('#### Root  ' + root);
        system.debug('root.getNodeType() '+root.getNodeType());
        system.debug('Dom.XmlNodeType.ELEMENT '+Dom.XmlNodeType.ELEMENT);
        system.debug('root.getChildElements() '+root.getChildElements());
        system.debug('getAttributeCount() '+root.getAttributeCount());
        
        String ParentJson = '{';
        List<String> mainERAJson = new List<String>();
        List<String> mainJson = new List<String>();
        List<String> ERAAttributes = new List<String>(); 
        
        try{
            if ( root.getNodeType() == Dom.XmlNodeType.ELEMENT ){
                
                
                if(root.getAttributeCount() != 0){
                String keyval = root.getAttributeKeyAt(0);
                String ParentElement = root.getAttribute( keyval, '');
                List<Dom.XMLNode> children = root.getChildElements();
                ParentJson += '"' + keyval + '": ' + '[';
                String ERAJson = '';
                ERAJson += '{';
                ERAAttributes.add( '"' + keyval + '": "' + ParentElement + '"' );
                ERAJson += String.join(ERAAttributes,',');
                mainERAJson.add(ERAJson);  
                ParentJson += String.join(mainERAJson,',') + '}]}'; 
                }else{
                 ParentJson = null;   
                }
                
                system.debug('#### ParentJson : '+ParentJson);     
                
            }
        }
        catch(Exception e){
           //ExceptionLog.logError(e);
        }
        return ParentJson;
    }

}
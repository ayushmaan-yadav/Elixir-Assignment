public class VobXMLParserClass {
	public static String generateBodyUsingRecursion(String finalJson, Dom.XMLNode root){
        try{
        if ( root.getNodeType() == Dom.XmlNodeType.ELEMENT ){     
            finalJson += '"' + root.getName() + '":{' ;
            system.debug('A - '+finalJson);
            List<String> resultAttributes = new List<String>();
            boolean rootHasAttributes = false;
            for(Integer i=0;i<root.getAttributeCount();i++){ 
                String key = root.getAttributeKeyAt(i);
                String value = root.getAttribute( key, '' );
                resultAttributes.add( '"' + key + '": "' + value + '"' ); 
            }
            if(resultAttributes.size()>0){
                finalJson += String.join(resultAttributes,',');
                rootHasAttributes = true;
            }
            system.debug('B - '+finalJson);
            if(root.getChildElements()!=null && root.getChildElements().size()>0){
                if(rootHasAttributes)
                {
                    finalJson +=','; 
                }
                String secondLevel = '';
                Integer count = 0;
                for(Dom.XMLNode child :root.getChildElements()){
                    finalJson += '"' + child.getName() + '":';  
                    system.debug('C - '+finalJson);
                    //system.debug('root.getChildElements() : ' + root.getChildElements());
                    count++;
                    secondLevel += '{';
                    List<String> secondLevelAttributes = new List<String>();
                    boolean childHasAttributes = false;
                    for(Integer i=0;i<child.getAttributeCount();i++){ 
                        String key = child.getAttributeKeyAt(i);
                        System.debug('Child key : ' + child.getAttributeKeyAt(i));
                        String value = child.getAttribute(key,'');
                        System.debug('value : ' + value);
                        secondLevelAttributes.add( '"' + key + '": "' + value + '"' ); 
                    }
                    if(secondLevelAttributes.size()>0){
                        secondLevel += String.join(secondLevelAttributes,',');
                        childHasAttributes = true;
                    }
                    
                    if(child.getChildElements()!=null && child.getChildElements().size()>0){
                        if(childHasAttributes)
                        {
                            secondLevel += ',';
                        }
                        secondLevel += '"' + child.getChildElements()[0].getName() + '":' + '[' ;  
                        String thirdLevel = '';
                        Integer thirdCount = 0;
                        for(Dom.XMLNode thirdChild :child.getChildElements()){
                            thirdCount++;
                            thirdLevel += '{';
                            List<String> thirdLevelAttributes = new List<String>();
                            for(Integer i=0;i<thirdChild.getAttributeCount();i++){ 
                                String key = thirdChild.getAttributeKeyAt(i);
                                String value = thirdChild.getAttribute( key, '' );
                                thirdLevelAttributes.add( '"' + key + '": "' + value + '"' ); 
                            }
                            if(thirdLevelAttributes.size()>0){
                                thirdLevel += String.join(thirdLevelAttributes,',');   
                            }                            
                            if(thirdChild.getChildElements()!=null && thirdChild.getChildElements().size()>0){
                                for(Integer i=0;i<thirdChild.getChildElements().size();i++){
                          
                              thirdLevel += ',"' + thirdChild.getChildElements()[i].getName() + '":';  
                                String fourthLevel = '';
                                Integer fourthCount = 0;
                                    Integer counter= 0;
                                    List<String> fourthLevelAttributes = new List<String>();
                                for(Dom.XMLNode fourthChild :thirdChild.getChildElements()){
                                    fourthCount++;
                                  //  fourthLevel += '{';
                                  
                                    
                                    if(i==counter){
                                  String value = thirdChild.getChildElements()[i].getText();
                                        system.debug('line86value'+value);
                                    
                                        fourthLevelAttributes.add( '"' + value + '"' );
                                        
                                }
                                    counter++;
                                   
                                }
                                     if(fourthLevelAttributes.size()>0){
                                        fourthLevel += String.join(fourthLevelAttributes,',');                                    
                                    }
                                   // fourthLevel += '}';
                                    if(thirdChild.getChildElements().size() != fourthCount){
                                        fourthLevel += ',';
                                    }
                                thirdLevel += fourthLevel;
                              //  thirdLevel += ']';
                            
                            }
                            }
                            thirdLevel += '}';
                            if(child.getChildElements().size() != thirdCount){
                                thirdLevel += ',';
                            }
                        }
                       
                        secondLevel += thirdLevel;
                        secondLevel += ']';
                    }
                    secondLevel += '}';
                    if(root.getChildElements().size() != count){
                        secondLevel += ',';
                    }
                }
                finalJson += secondLevel;
            }
            finalJson += '}';            
        }
        }
        catch(Exception e){
           // ExceptionLog.logError(e);
        }
        return finalJson;
    }

}
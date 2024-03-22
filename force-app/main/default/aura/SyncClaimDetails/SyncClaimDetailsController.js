({  
    
    onInit : function( component, event, helper ) {    
        
        let action = component.get( "c.updateClaim");  
        action.setParams({  
            recId: component.get( "v.recordId" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();  
            if ( state === "SUCCESS") {  

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": 'SUCCESS',
                    "type": 'SUCCESS',
                    "duration":' 1000',
                    "message": 'The Claim has been synced successfully'
                });
                toastEvent.fire();
                
                $A.get("e.force:closeQuickAction").fire();  
                $A.get('e.force:refreshView').fire();   
                
            }  else {
                
                let showToast = $A.get( "e.force:showToast" );
                showToast.setParams({
                    title : 'Error!!!',
                    message : 'Record Not Saved due to error.',
                    type : 'error',
                    mode : 'sticky',
                    message : 'Some error occured'
                });
                showToast.fire();
                
            }
        });  
        $A.enqueueAction( action );         
        
    }
    
})
({
    myAction : function(component, event, helper) {
        var action = component.get("c.DataInit");
        action.setParams({
            claimId : component.get("v.recordId")
        });      
        action.setCallback(this, function(response){  
            component.set("v.showSpinner",false);
            var res = response.getReturnValue();
            if(res == null){
                component.set("v.visible",false);
                return;
            }
            var allErrors = res.allErrors;
            var claim = res.claim;
            var lineItems = res.lineItems;
            var allFinalErrors = [];
            if(!$A.util.isUndefinedOrNull(allErrors)){
                component.set("v.visible",true);
                Object.keys(allErrors).forEach(function(key){
                    if(lineItems.hasOwnProperty(key)){
                        allFinalErrors.push({'value':allErrors[key], 'key':lineItems[key].Id});
                    }else if(key == 'CLAIM'){
                        allFinalErrors.push({'value':allErrors[key], 'key':claim.Id});
                    }
                });
            }else{
                component.set("v.visible",false);
            }
            component.set("v.lineItems", lineItems);
            component.set("v.claim", claim);
            component.set("v.allErrors", allFinalErrors);
        });
            $A.enqueueAction(action);
    },
    toggle  : function(component, event, helper) {
        var id = event.target.id;
        var acc = component.find(id);
        for(var cmp in acc) {
        $A.util.toggleClass(acc[cmp], 'slds-show');  
        $A.util.toggleClass(acc[cmp], 'slds-hide');  
        }
    },
    handleSuccess  : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");    
        toastEvent.setParams({
            "title": "Success!",
            "type":"SUCCESS",
            "message": "Updated successfully"
        });
        toastEvent.fire();
    }
})
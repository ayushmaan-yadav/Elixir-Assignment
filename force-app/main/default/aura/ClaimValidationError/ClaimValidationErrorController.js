({
    myAction : function(component, event, helper) {
        var action = component.get("c.claimValidationErrors");
        component.set('v.visible',true);
        action.setParams({
            claimId : component.get("v.recordId")
        });      
        action.setCallback(this, function(response){  
            component.set("v.showSpinner",false);
            var res = response.getReturnValue();
            if(res=='NO ERRORS FOUND'){
                component.set('v.message',res);
                component.set('v.visible',false);
                return;
            }
            var resObj =JSON.parse(res);
            console.log('errorsresObj=>'+JSON.stringify(resObj));
            component.set('v.allErrors',resObj);
        });
        $A.enqueueAction(action);
    },
    handleSuccess  : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");    
        toastEvent.setParams({
            "title": "Success!",
            "type":"SUCCESS",
            "message": "Updated successfully"
        });
        toastEvent.fire();
    },
    toggle  : function(component, event, helper) {
        var id = event.target.id;
        var acc = component.find(id);
        for(var cmp in acc) {
        $A.util.toggleClass(acc[cmp], 'slds-show');  
        $A.util.toggleClass(acc[cmp], 'slds-hide');  
        }
    },
})
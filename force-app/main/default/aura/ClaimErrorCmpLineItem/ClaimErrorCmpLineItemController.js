({
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
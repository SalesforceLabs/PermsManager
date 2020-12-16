({
    handleCancel : function(component, event, helper){
        
    },
    
    handleClick : function(component, event, helper){
        var validInput = component.find('FLS_Assignment').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        if(validInput){
            component.set("v.Spinner","true");
            helper.AssignFls(component, event, helper);
        }
    }
})
({
    AssignFls : function(component, event, helper) {
        component.set("v.isExcep", false);
        component.set("v.isSucc", false);
        var t0 = performance.now();
        var perms = component.get("v.value");        
        var permsParam = perms.toString();
        var action = component.get("c.updateFLS");
        
        action.setParams({            
            objectName : component.get("v.objectName"),
            profileNames: component.get("v.listOfProfiles"),
            fieldNames: component.get("v.listOfFields"),
            permissions: permsParam,
            isProfile : component.get("v.isProfile")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retString = response.getReturnValue();
                var retStrList = retString.split('\n');
                if(response.getReturnValue() != 'true'){
                    component.set("v.isExcep", 'true');
                    component.set("v.retProfiles", retStrList);
                    component.set("v.loaded", false);   
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({                        
                        "type": "error",
                        "mode":"sticky",
                        "message": "Oops! There are some errors!"
                    });               
                    toastEvent.fire();  
                }
                else{
                    component.set("v.isSucc", true);
                    component.set("v.loaded", false);
                    component.set("v.timeTaken", (performance.now() - t0)/1000);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": "The permissions are updated successfully."                        
                    });
                    toastEvent.fire();
                }                            
            }
            else{                
                component.set("v.loaded", false);
                component.set("v.isExcep", 'true');
                console.log('@@@ failed @@@@', response.getError());                           
                component.set("v.retProfiles", response.getError()[0].message.split('\n'));
                var errorMsg = response.getError()[0].message.split('\n');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({                    
                    "type": "error",
                    "mode":"sticky",
                    "message": "Oops! There are some errors!"
                });
                toastEvent.fire();
            }
            component.set("v.Spinner","false");
        });        
        $A.enqueueAction(action);
    }
})
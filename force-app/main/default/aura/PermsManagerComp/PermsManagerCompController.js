({   
    isProfile : function(component, event, helper){        
        var upd = component.get("v.isProfile");        
        component.set("v.isProfile", !upd);
    },
    
    fetchCriteria : function(component, event, helper){  
        var whichOne = component.find("panelGroup").get("v.value");        
        var typeDefs;
        switch(whichOne) {
            case 'FLS':
                typeDefs = 'FLS';
                break;
            case 'CRUDVM':
                typeDefs = 'CRUDVM';
                break;
            case 'Apex Class':
                typeDefs = 'Apex Class';
                break;
            case 'VF Page':
                typeDefs = 'VF Page';
                break;
            default:
                typeDefs = 'FLS';
        }
        component.set("v.selectPanel", typeDefs);
    },

    doInit : function(component, event, helper) {
        var action = component.get("c.isAdmin");                
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isAdmin", response.getReturnValue());
                if(!response.getReturnValue()){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Oops!",
                        "type": "error",
                        "mode":"sticky",
                        "message": "Only Admins are allowed to access this app"
                    });
                    toastEvent.fire();
                }
            }
            else{                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Oops!",
                    "type": "error",
                    "mode":"sticky",
                    "message": "Something went wrong, please try again!"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})
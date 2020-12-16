public with sharing class PermsManager{
    public static Map<Id,PermissionSet> profileValidationList = new Map<Id,PermissionSet>();
    public static Boolean isAdmin = false;
    @AuraEnabled
    public static String updateFLS(String objectName, String profileNames, String fieldNames, String permissions, Boolean isProfile){      
        if(!isAdmin()){
            throw new AuraHandledException('Only Admins are allowed to access this app');
        }          
        System.debug('@@@ CPU TIME @@@'+ Limits.getCpuTime());    
        Set<String> listOfProfiles = new Set<String>();
        for(String proRec :  profileNames.split('\n')){
            if(String.isNotBlank(proRec)){
                listOfProfiles.add(proRec.toLowerCase());
            }
        }
        Set<String> listOfFields = new Set<String>();
        for(String fieldName : fieldNames.split('\n')){
            if(String.isNotBlank(fieldName)){
                listOfFields.add(fieldName.trim());
            }
        }
        objectName = (objectName.toLowerCase()).trim();
        SObjectType objToken = Schema.getGlobalDescribe().get(objectName);
        if(objToken == NULL){
            return 'Incorrect Object Name: ' + objectName;
        }
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap(); 
        String errorFields = 'Incorrect Field Names: \n';
        Boolean fieldErrors = false;
        for(String eachField : listOfFields){
            if(String.isBlank(eachField)){
                continue;
            }
            if(!fields.containsKey(eachField.toLowerCase())){                
                errorFields += eachField + '\n';
                fieldErrors = true;
            }
        }
        if(fieldErrors){
            return errorFields;
        }
        Set<String> listOfObjectFields = new Set<String>();        
        String retProfiles = isProfile ? validateProfiles(profileNames) : validatePermissionSets(profileNames);
        if(retProfiles != null){
            return retProfiles;
        }
        for (String variable : listOfFields){
            listOfObjectFields.add((objectName.trim()+'.' + variable.trim()).toLowerCase());
        }
        Boolean readPermission = permissions.contains('read');
        Boolean editPermission = permissions.contains('edit');
        List<PermissionSet> profilePermissionsSetIds;

        List<String> fieldsToCheck = new List<String>{'Id', 'SObjectType', 'Field', 'ParentId', 'PermissionsRead', 'PermissionsEdit'}; 
        if(!(Schema.sObjectType.FieldPermissions.isQueryable() && isFieldsAccessible('FieldPermissions', fieldsToCheck))){
            return null;
        }
        List<String> fieldsToCheck1 = new List<String>{'Id', 'IsOwnedByProfile'};
        if(!(PermissionSet.sObjectType.getDescribe().isQueryable() && isFieldsAccessible('PermissionSet', fieldsToCheck1))){
            return null;
        }
        /**
         * FALSE POSITIVE
         * The object accessibility is already checked with FieldPermissions Object
         * FieldPerms is alias name for the same object
         * This is FALSE POSITIVE
         */
        if(isProfile){
            profilePermissionsSetIds = [select Id, (
                SELECT Id, SObjectType, Field, ParentId, PermissionsRead, PermissionsEdit
                FROM FieldPerms
                where SObjectType = :objectName AND Field = :listOfObjectFields)
                                        from PermissionSet
                                        where IsOwnedByProfile = true and Profile.Name = :listOfProfiles];
        }
        else{
            profilePermissionsSetIds = [select Id, (
                SELECT Id, SObjectType, Field, ParentId, PermissionsRead, PermissionsEdit
                FROM FieldPerms
                where SObjectType = :objectName AND Field = :listOfObjectFields)
                                        from PermissionSet
                                        where Label = :listOfProfiles];
        }
        List<FieldPermissions> fieldPermissionsList = new List<FieldPermissions>();
        Set<String> setOfPerms = new Set<String>();
        for (PermissionSet pId : profilePermissionsSetIds){            
            for (SObject extRec : pId.FieldPerms){                
                FieldPermissions permRec = (FieldPermissions)extRec;                
                if (listOfObjectFields.contains((permRec.Field).toLowerCase()) && (permRec.PermissionsRead != readPermission || permRec.PermissionsEdit != editPermission)){
                    setOfPerms.add((permRec.Field).toLowerCase());
                    // add if condition for read-only fields
                    fieldPermissionsList.add(new FieldPermissions(Id = permRec.Id, Field = permRec.Field, SObjectType = objectName, ParentId = permRec.ParentId, PermissionsRead = readPermission, PermissionsEdit = editPermission));
                } else{
                    setOfPerms.add((permRec.Field).toLowerCase());
                }
            }
            for (String fieldname : listOfObjectFields){
                if (!setOfPerms.contains(fieldname)){
                    setOfPerms.add(fieldname);
                    // add if condition for read-only fields
                    fieldPermissionsList.add(new FieldPermissions(Field = fieldname, SObjectType = objectName, ParentId = pId.Id, PermissionsRead = readPermission, PermissionsEdit = editPermission));
                }
            }
            setOfPerms.clear();
        }
        String succ = 'true';        
        try{
            if (Schema.sObjectType.FieldPermissions.isCreateable() && Schema.sObjectType.FieldPermissions.isUpdateable()) {
                if (!fieldPermissionsList.isEmpty() && isAdmin){
                    upsert fieldPermissionsList;
                }
            }
        }
        catch(Exception e){
            throw new AuraHandledException('Something went wrong! \n Maybe you giving edit access to read only field? \n Error Message: '+ e.getMessage());    
        }
        System.debug('@@@ CPU TIME @@@'+ Limits.getCpuTime());
        return succ;
    }
    
    @AuraEnabled
    public static string validateProfiles(String profileNames){
        Set<String> listOfProfiles = new Set<String>();
        for(String pro : profileNames.split('\n')){
            if(pro.trim()!=''){
                listOfProfiles.add((pro.trim()).toLowerCase());
            }
        }
        profileValidationList = new Map<Id,PermissionSet>([select Id, Name, Profile.Name, Profile.PermissionsModifyAllData from PermissionSet where Profile.Name in: listOfProfiles]);
        List<String> profilesValidString = new List<String>();
        for(PermissionSet proRec : profileValidationList.values()){
            profilesValidString.add(proRec.Profile.Name.toLowerCase());
        }
        List<String> profileIncorrectList = new List<String>();
        String retProfiles = 'Incorrect Profiles: \n';
        if(profileValidationList.size() != listOfProfiles.size()){
            for(String proRec : listOfProfiles){
                if(!profilesValidString.contains(proRec)){
                    retProfiles += proRec + '\n';
                }
            }
            return retProfiles;
        }
        return null;
    }
    
    @AuraEnabled
    public static string validatePermissionSets(String permSetNames){        
        Set<String> listOfPermSets = new Set<String>();
        for(String pro : permSetNames.split('\n')){
            if(pro.trim()!=''){
                listOfPermSets.add((pro.trim()).toLowerCase());
            }
        }
        profileValidationList = new Map<Id,PermissionSet>([select id, Label from PermissionSet where Label in: listOfPermSets]);
        List<String> permSetValidString = new List<String>();
        for(PermissionSet proRec : profileValidationList.values()){
            permSetValidString.add(proRec.Label.toLowerCase());
        }
        List<String> profileIncorrectList = new List<String>();
        String retPermsSets = 'Incorrect PermissionSets: \n';
        if(profileValidationList.size() != listOfPermSets.size()){
            for(String proRec : listOfPermSets){
                if(!permSetValidString.contains(proRec)){
                    retPermsSets += proRec + '\n';
                }
            }
            return retPermsSets;
        }
        return null;
    }

    @AuraEnabled
    public static Boolean isAdmin(){
        List<String> fieldsToCheck1 = new List<String>{'Id'};
        if(!(Profile.sObjectType.getDescribe().isQueryable() && isFieldsAccessible('Profile', fieldsToCheck1))){
            return false;
        }
        Profile adminProfile = [Select Id from Profile where Name = 'System Administrator'];
        isAdmin = UserInfo.getProfileId() != adminProfile.Id ? false : true;                
        return isAdmin;
    }

    /**
    * Purpose : To check field level access for each field specified in the list
    */
    public static Boolean isFieldsAccessible(String objectName, List<String> listFields)
    {        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();     
        Schema.sObjectType objectType = globalDescribe.get(objectName);  
        
        if(objectType != null){
            Map <String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            Map <String, Schema.SObjectField> lowerCaseFieldMap = convertTolowerAllkeys(fieldMap);
            String namespacePrefix = '';
            for(String field: listFields){
                field = namespacePrefix+field;
                if(lowerCaseFieldMap.containsKey(field.toLowerCase())){
                    if(!fieldMap.get(field).getDescribe().isAccessible()){
                        System.debug(LoggingLevel.ERROR,'Name of the User: '+UserInfo.getName() +'(' + Userinfo.getUserId() +') does not have access to the field: '+field+' of the object '+objectName);
                        return false;
                    }
                }
            }
            return true;
        }
        return false;
    }    

    public static Map<string,Schema.SObjectField> convertTolowerAllkeys(Map<string,Schema.SObjectField> mapToConvert){
        Map<string,Schema.SObjectField> newMap = new  map<string,Schema.SObjectField> ();
        for(string key : mapToConvert.keySet()){
            newMap.put(key.toLowerCase(),mapToConvert.get(key));
        }
        return newMap;
    }
}
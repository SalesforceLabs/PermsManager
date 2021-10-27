@isTest
private class PermsManagerTest {
    private static testmethod void testUpdateFLS() {
        PermsManager.updateFLS('Account', 'System Administrator\nStandard User', 'Industry\nDescription', 'read;edit', true);
        List<FieldPermissions> fieldPerms = [SELECT Id from FieldPermissions where Field= 'Account.Industry'];
        System.assertNotEquals(fieldPerms.size(), 0);
    }

    private static testmethod void testUpdateFLS3() {
        PermsManager.updateFLS('Accou_nt', 'System Administrator\nStandard User', 'Industry\nDescription', 'read;edit', true);
        List<FieldPermissions> fieldPerms = [SELECT Id from FieldPermissions where Field= 'Account.Industry'];
        System.assertNotEquals(fieldPerms.size(), 0);
    }

    private static testmethod void testUpdateFLS4() {
        PermsManager.updateFLS('Account', 'System Administrato\nStandard User', 'Industr\nDescription', 'read;edit', true);
        List<FieldPermissions> fieldPerms = [SELECT Id from FieldPermissions where Field= 'Account.Industry'];
        System.assertNotEquals(fieldPerms.size(), 0);
    }

    private static testmethod void testUpdateFLS2() {
        PermsManager.updateFLS('Account', 'System Administrato\nStandard User', 'Industry\nDescription', 'read;edit', true);    
        List<FieldPermissions> fieldPerms = [SELECT Id from FieldPermissions where Field= 'Account.Industry'];
        System.assertNotEquals(fieldPerms.size(), 1);
    }

    private static testmethod void testUpdateFLS5() {
        PermissionSet ps = new PermissionSet(Label = 'mockPs', Name = 'mockPs');
        insert ps;
        ps = new PermissionSet(Label = 'mockPs1', Name = 'mockPs1');
        insert ps;
        PermsManager.updateFLS('Account', 'mockPs\nmockPs1', 'Industry\nDescription', 'read;edit', false);
        List<FieldPermissions> fieldPerms = [SELECT Id from FieldPermissions where Field= 'Account.Industry'];
        System.assertNotEquals(fieldPerms.size(), 1);
    }
}
public class ContactTriggerHandler extends TriggerHandler {
  private List<Contact> newContactList;
  private List<Contact> oldContactList;
  private Map<Id, Contact> newContactMap;
  private Map<Id, Contact> oldContactMap;

  public ContactTriggerHandler() {
    this.newContactList = (List<Contact>) Trigger.new;
    this.oldContactList = (List<Contact>) Trigger.old;
    this.newContactMap = (Map<Id, Contact>) Trigger.newMap;
    this.oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
  }

  public override void afterInsert() {
    ContactHelper.updatePrimaryContact(newContactList);
  }

  public override void afterDelete() {
    ContactHelper.updatePrimaryContact(oldContactList);
  }
}

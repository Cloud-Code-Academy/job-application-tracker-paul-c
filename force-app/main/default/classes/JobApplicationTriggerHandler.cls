public class JobApplicationTriggerHandler extends TriggerHandler {
  private List<Job_Application__c> newJobAppList;
  private List<Job_Application__c> oldJobAppList;
  private Map<Id, Job_Application__c> newJobAppMap;
  private Map<Id, Job_Application__c> oldJobAppMap;

  public JobApplicationTriggerHandler() {
    this.newJobAppList = (List<Job_Application__c>) Trigger.new;
    this.oldJobAppList = (List<Job_Application__c>) Trigger.old;
    this.newJobAppMap = (Map<Id, Job_Application__c>) Trigger.newMap;
    this.oldJobAppMap = (Map<Id, Job_Application__c>) Trigger.oldMap;
  }

  public override void beforeInsert() {
    JobApplicationHelper.convertSalaries(newJobAppList);
    JobApplicationHelper.calculateTaxes(newJobAppList, oldJobAppMap);
  }

  public override void afterInsert() {
    JobApplicationHelper.createTasks(newJobAppList, oldJobAppMap);
  }

  public override void beforeUpdate() {
    JobApplicationHelper.createTasks(newJobAppList, oldJobAppMap);
    JobApplicationHelper.calculateTaxes(newJobAppList, oldJobAppMap);
  }
}

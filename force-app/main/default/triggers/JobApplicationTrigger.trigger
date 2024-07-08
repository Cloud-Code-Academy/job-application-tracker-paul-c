trigger JobApplicationTrigger on Job_Application__c(
  before insert,
  before update,
  after insert,
  after update
) {
  JobApplicationTriggerHandler handler = new JobApplicationTriggerHandler();
  handler.run();
}

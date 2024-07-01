public with sharing class CleanUpStaleJobsAppSchedule implements Schedulable {
  // This method is executed when the scheduled job runs.
  public void execute(SchedulableContext sc) {
    Date thirtyDaysOldOrMore = Date.today() - 30; // Calculate the date 30 days ago.

    // Query job applications with follow-up dates older than 30 days and not accepted or closed.
    List<Job_Application__c> jobApps = [
      SELECT Id, Status__c, Follow_up_date__c
      FROM Job_Application__c
      WHERE Follow_up_date__c <= :thirtyDaysOldOrMore AND (Status__c != 'Accepted' OR Status__c != 'Closed')
    ];

    // List to collect job applications to update.
    List<Job_Application__c> jobAppsToUpdate = new List<Job_Application__c>();

    // Check if there are any stale job applications.
    if (!jobApps.IsEmpty()) {
      for (Job_Application__c jobApp : jobApps) {
        jobApp.Status__c = 'Closed';
        jobApp.Notes__c = 'Your job application was closed automatically because it has been 30 days or more since the follow-up date.';
        jobAppsToUpdate.add(jobApp);
      }
      update jobAppsToUpdate;
    }
  }

  // This method schedules the cleanup job to run daily at midnight.
  public static void scheduleJob() {
    String cronExpression = '0 0 0 * * ?'; // Cron expression to run the job at midnight every day.
    CleanUpStaleJobsAppSchedule reminderJob = new CleanUpStaleJobsAppSchedule(); // Instantiate the job.

    System.schedule('Clean Up Stale Job Applications', cronExpression, reminderJob); // Schedule the job.
  }
}

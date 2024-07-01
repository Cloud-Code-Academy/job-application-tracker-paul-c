@IsTest
private class CleanUpStaleJobsAppScheduleTest {
  @IsTest
  static void testCleanupStaleJobApplications() {
    // Prepare stale job applications (more than 30 days old)
    List<Job_Application__c> staleJobApplications = createStaleJobApplications();
    // Prepare non-stale job applications (less than 30 days old)
    List<Job_Application__c> nonStaleJobApplications = createNonStaleJobApplications();

    Test.startTest();
    // Schedule the job
    CleanUpStaleJobsAppSchedule.scheduleJob();
    Test.stopTest();

    // Verify stale job applications were updated
    List<Job_Application__c> updatedStaleJobApplications = [
      SELECT Id, Status__c, Notes__c
      FROM Job_Application__c
      WHERE Id IN :staleJobApplications
    ];
    System.assertEquals(
      staleJobApplications.size(),
      updatedStaleJobApplications.size(),
      'All stale job applications should have been updated.'
    );

    for (Job_Application__c jobApp : updatedStaleJobApplications) {
      System.assertEquals('Closed', jobApp.Status__c, 'Job application status should be Closed.');
      System.assertEquals(
        'Your job application was closed automatically because it has been 30 days or more since the follow-up date.',
        jobApp.Notes__c,
        'Incorrect closure notes.'
      );
    }

    // Verify non-stale job applications were not updated
    List<Job_Application__c> nonUpdatedNonStaleJobApplications = [
      SELECT Id, Status__c, Notes__c
      FROM Job_Application__c
      WHERE Id IN :nonStaleJobApplications
    ];
    for (Job_Application__c jobApp : nonUpdatedNonStaleJobApplications) {
      System.assertEquals('Applied', jobApp.Status__c, 'Job application status should be Applied.');
    }
  }

  // Helper method to create stale job applications (more than 30 days old)
  private static List<Job_Application__c> createStaleJobApplications() {
    List<Job_Application__c> jobApplications = new List<Job_Application__c>();
    for (Integer i = 0; i < 3; i++) {
      Job_Application__c jobApp = new Job_Application__c(
        Status__c = 'Applied',
        Follow_up_date__c = Date.today().addDays(-31) // More than 30 days old
      );
      jobApplications.add(jobApp);
    }
    insert jobApplications;
    return jobApplications;
  }

  // Helper method to create non-stale job applications (less than 30 days old)
  private static List<Job_Application__c> createNonStaleJobApplications() {
    List<Job_Application__c> jobApplications = new List<Job_Application__c>();
    for (Integer i = 0; i < 2; i++) {
      Job_Application__c jobApp = new Job_Application__c(
        Status__c = 'Applied',
        Follow_up_date__c = Date.today().addDays(-29) // Less than 30 days old
      );
      jobApplications.add(jobApp);
    }
    insert jobApplications;
    return jobApplications;
  }
}

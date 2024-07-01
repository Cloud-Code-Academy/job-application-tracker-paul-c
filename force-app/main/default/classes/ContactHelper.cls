public with sharing class ContactHelper {
  // The updatePrimaryContact method assigns or reassigns a Primary Contact from the related contacts to a Job Application
  // based on the provided list of Contacts.
  public static void updatePrimaryContact(List<Contact> contList) {
    List<Id> jobAppIds = new List<Id>();

    // Collect Job Application Ids from the Contacts.
    for (Contact cont : contList) {
      jobAppIds.add(cont.Job_Application__c);
    }

    // Return if there are no Job Application Ids.
    if (jobAppIds.isEmpty()) {
      return;
    }

    // Query related Contacts for the collected Job Application Ids.
    List<Contact> contSet = [
      SELECT Id, Job_Application__c
      FROM Contact
      WHERE Job_Application__c = :jobAppIds
    ];

    // Map Contacts by Job Application Ids for easy access.
    Map<Id, Contact> contactByJobAppId = new Map<Id, Contact>();
    for (Contact cont : contSet) {
      contactByJobAppId.put(cont.Job_Application__c, cont);
    }

    // Query unique Job Applications related to the collected Job Application Ids.
    Set<Job_Application__c> jobAppList = new Set<Job_Application__c>(
      [
        SELECT Id, Primary_Contact__c
        FROM Job_Application__c
        WHERE Id = :jobAppIds
      ]
    );

    // Prepare a list of Job Applications to update.
    List<Job_Application__c> jobAppToListUpdate = new List<Job_Application__c>();
    for (Job_Application__c jobApp : jobAppList) {
      // If a related Contact exists, assign or reassign the Primary Contact to the Job Application.
      if (contactByJobAppId.get(jobApp.Id) != null && jobApp.Primary_Contact__c == null) {
        jobApp.Primary_Contact__c = contactByJobAppId.get(jobApp.Id).Id;
        jobAppToListUpdate.add(jobApp);
      }
    }

    // Try to update the Job Applications, and if it fails, log an error message.
    try {
      if (!jobAppToListUpdate.isEmpty()) {
        update jobAppToListUpdate;
      }
    } catch (Exception e) {
      System.debug('Error occurred while updating Job Applications: ' + e.getMessage());
    }
  }
}

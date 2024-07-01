@isTest
public with sharing class ContactHelperTest {
  // Utility method to create a Job Application record
  private static Job_Application__c createJobApplication() {
    Job_Application__c jobApp = new Job_Application__c(Position_Title__c = 'Test Job Application');
    insert jobApp;
    return jobApp;
  }

  // Utility method to create and insert a Contact record
  private static Contact createAndInsertContact(Id jobAppId) {
    Contact contact = new Contact(LastName = 'Test Contact', Job_Application__c = jobAppId);
    insert contact;
    return contact;
  }

  @isTest
  static void testupdatePrimaryContact() {
    // Create a Job Application
    Job_Application__c jobApp = createJobApplication();

    // Create and insert Contacts
    Contact contact1 = createAndInsertContact(jobApp.Id);
    Contact contact2 = createAndInsertContact(jobApp.Id);

    // List of Contacts to track them for deletion
    List<Contact> contactList = new List<Contact>{ contact1, contact2 };

    // Fetch the updated Job Application
    jobApp = [SELECT Id, Primary_Contact__c FROM Job_Application__c WHERE Id = :jobApp.Id];

    // Assert the Primary Contact is set
    System.assertNotEquals(null, jobApp.Primary_Contact__c, 'Primary Contact should be set');
    Id initialPrimaryContactId = jobApp.Primary_Contact__c;

    // Fetch the Primary Contact record to delete
    Contact primaryContact = [SELECT Id FROM Contact WHERE Id = :initialPrimaryContactId LIMIT 1];

    // Delete the Primary Contact
    delete primaryContact;

    // Fetch the updated Job Application
    jobApp = [SELECT Id, Primary_Contact__c FROM Job_Application__c WHERE Id = :jobApp.Id];

    // Assert that Primary Contact has been reassigned or is null if no other contacts exist
    if (contactList.size() > 1) {
      System.assertNotEquals(
        initialPrimaryContactId,
        jobApp.Primary_Contact__c,
        'Primary Contact should be reassigned'
      );
    } else {
      System.assertEquals(null, jobApp.Primary_Contact__c, 'Primary Contact should be null if no other contacts exist');
    }
  }
}

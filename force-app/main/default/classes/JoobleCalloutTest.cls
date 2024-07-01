@isTest
public with sharing class JoobleCalloutTest {
  @isTest
  static void testPostCallout() {
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new JoobleHttpCalloutMock());

    // Setup test data
    String keywords = 'Salesforce';
    String location = 'Florida';
    Integer page = 1;
    String salary = '100000';
    String datecreatedfrom = '2024-05-30';

    // Call the method
    Map<String, Object> results = JoobleCallout.postCallout(keywords, location, page, salary, datecreatedfrom);

    // Validate the results
    System.assertEquals(2, results.get('totalCount'), 'Total count should be 2');
    List<Job_Application__c> jobApps = (List<Job_Application__c>) results.get('jobs');
    System.assertEquals(2, jobApps.size(), 'Number of job applications should be 2');

    // Validate the first job
    Job_Application__c jobApp = jobApps[0];
    System.assertEquals('Salesforce Developer', jobApp.Position_Title__c, 'Job title should be Salesforce Developer');
    System.assertEquals('Florida', jobApp.Location__c, 'Location should be Florida');
    System.assertEquals('Test Job', jobApp.Description__c, 'Description should match');
    System.assertEquals('https://jooble.org/', jobApp.URL__c, 'URL should match');
    System.assertEquals('Test', jobApp.Company_Name__c, 'Company name should match');
    System.assertEquals('$105k - $125k', jobApp.Salary__c, 'Salary should match');
    System.assertEquals(Date.valueOf('2024-05-30'), jobApp.Posted_Date__c, 'Posted date should match');
  }

  @isTest
  static void testInsertJobApplications() {
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new JoobleHttpCalloutMock());

    // Setup test data
    String keywords = 'Salesforce';
    String location = 'Florida';
    Integer page = 1;
    String salary = '100000';
    String datecreatedfrom = '2024-05-30';

    // Call the method
    Map<String, Object> results = JoobleCallout.postCallout(keywords, location, page, salary, datecreatedfrom);

    // Get Job Applications
    List<Job_Application__c> jobApps = (List<Job_Application__c>) results.get('jobs');

    Test.startTest();
    JoobleCallout.insertJobApplications(jobApps);
    Test.stopTest();

    // Validate inserted job applications
    List<Job_Application__c> insertedJobApps = [
      SELECT Id, Company_Name__c
      FROM Job_Application__c
      WHERE Company_Name__c = 'Test'
    ];

    System.assertEquals(2, insertedJobApps.size(), 'Two job applications should have been inserted');
  }
}

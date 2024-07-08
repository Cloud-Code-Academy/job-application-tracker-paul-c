@isTest
public with sharing class JobApplicationHelperTest {
  @isTest
  static void testCreateTasksOnInsert() {
    // Insert new job applications with different statuses
    List<Job_Application__c> newJobApps = new List<Job_Application__c>{
      new Job_Application__c(
        Status__c = 'Saved',
        Yearly_Salary__c = 50000,
        File_Status__c = 'Single',
        Pay_Frequency__c = 'Monthly'
      ),
      new Job_Application__c(
        Status__c = 'Applying',
        Yearly_Salary__c = 50000,
        File_Status__c = 'Single',
        Pay_Frequency__c = 'Monthly'
      )
    };

    Test.startTest();
    insert newJobApps; // This should trigger the logic that creates tasks
    Test.stopTest();

    // Verify that tasks were created
    List<Task> tasks = [SELECT WhatId, Subject, Priority, ActivityDate FROM Task WHERE WhatId IN :newJobApps];
    System.assertEquals(8, tasks.size(), 'Two tasks should have been created.');
    System.assertEquals(
      '✅ Check if the job description aligns with your interests and values.',
      tasks[0].Subject,
      'Incorrect Subject'
    );
    System.assertEquals(
      '📤 Submit your application on the company website if possible.',
      tasks[7].Subject,
      'Incorrect Subject'
    );
  }

  @isTest
  static void testCreateTasksOnUpdate() {
    // Insert new job applications with different statuses
    List<Job_Application__c> newJobApps = new List<Job_Application__c>{
      new Job_Application__c(
        Status__c = 'Saved',
        Yearly_Salary__c = 50000,
        File_Status__c = 'Single',
        Pay_Frequency__c = 'Monthly'
      ),
      new Job_Application__c(
        Status__c = 'Applying',
        Yearly_Salary__c = 50000,
        File_Status__c = 'Single',
        Pay_Frequency__c = 'Monthly'
      )
    };
    insert newJobApps; // This should trigger the logic that creates tasks

    // Retrieve existing job applications and update their statuses
    List<Job_Application__c> jobApps = [
      SELECT Id, Status__c
      FROM Job_Application__c
      WHERE Id IN :newJobApps
    ];

    // Update status to trigger task creation
    jobApps[0].Status__c = 'Applying';
    jobApps[1].Status__c = 'Applied';

    Test.startTest();
    update jobApps; // This should trigger the logic that creates tasks
    Test.stopTest();

    // Verify that tasks were created
    List<Task> tasks = [SELECT WhatId, Subject, Priority, ActivityDate FROM Task WHERE WhatId = :jobApps];
    System.assertEquals(17, tasks.size(), 'One task should have been created.');
    System.assertEquals(
      '✅ Check if the job description aligns with your interests and values.',
      tasks[0].Subject,
      'Incorrect Subject'
    );
    System.assertEquals(
      '📞 Set up weekly networking calls to explore similar companies/roles.',
      tasks[16].Subject,
      'Incorrect Subject'
    );
  }

  @isTest
  static void testConvertSalaries() {
    // Setup job applications with different salary formats
    List<Job_Application__c> jobApps = new List<Job_Application__c>{
      new Job_Application__c(Salary__c = '$50k'),
      new Job_Application__c(Salary__c = '$80 - $85 per hour'),
      new Job_Application__c(Salary__c = '50000')
    };

    Test.startTest();
    List<Job_Application__c> updatedJobApps = JobApplicationHelper.convertSalaries(jobApps);
    Test.stopTest();

    System.assertEquals(50000, updatedJobApps[0].Yearly_Salary__c, 'Yearly salary should be 50,000.');
    System.assertEquals(171600, updatedJobApps[1].Yearly_Salary__c, 'Yearly salary should be 171,600.');
    System.assertEquals(50000, updatedJobApps[2].Yearly_Salary__c, 'Yearly salary should be 50,000.');
  }

  @isTest
  static void testCalculateTaxesOnInsert() {
    // Insert new job applications
    List<Job_Application__c> newJobApps = new List<Job_Application__c>{
      new Job_Application__c(Yearly_Salary__c = 50000, File_Status__c = 'Single', Pay_Frequency__c = 'Monthly'),
      new Job_Application__c(
        Yearly_Salary__c = 75000,
        File_Status__c = 'Head of household',
        Pay_Frequency__c = 'Bi-weekly'
      )
    };

    Test.startTest();
    insert newJobApps;
    Test.stopTest();

    // Verify tax calculations
    List<Job_Application__c> insertedApps = [
      SELECT Id, Gross_Pay__c, Income_Tax__c, Medicare_Tax__c, Social_Security_Tax__c, Final_Pay_Check__c
      FROM Job_Application__c
      WHERE Id IN :newJobApps
    ];
    System.assertEquals(4166.67, insertedApps[0].Gross_Pay__c.setScale(2), 'Wrong Gross Pay');
    System.assertEquals(334.67, insertedApps[0].Income_Tax__c.setScale(2), 'Wrong Income Tax');
    System.assertEquals(60.42, insertedApps[0].Medicare_Tax__c.setScale(2), 'Wrong Medicare Tax');
    System.assertEquals(258.33, insertedApps[0].Social_Security_Tax__c.setScale(2), 'Wrong Social Security Tax');
    System.assertEquals(3513.25, insertedApps[0].Final_Pay_Check__c.setScale(2), 'Wrong Final Pay Check');
    System.assertEquals(2884.62, insertedApps[1].Gross_Pay__c.setScale(2), 'Wrong Gross Pay');
    System.assertEquals(232.35, insertedApps[1].Income_Tax__c.setScale(2), 'Wrong Income Tax');
    System.assertEquals(41.83, insertedApps[1].Medicare_Tax__c.setScale(2), 'Wrong Medicare Tax');
    System.assertEquals(178.85, insertedApps[1].Social_Security_Tax__c.setScale(2), 'Wrong Social Security Tax');
    System.assertEquals(2431.60, insertedApps[1].Final_Pay_Check__c.setScale(2), 'Wrong Final Pay Check');
  }

  @isTest
  static void testCalculateTaxesOnUpdate() {
    // Insert initial job applications
    List<Job_Application__c> jobApps = new List<Job_Application__c>{
      new Job_Application__c(Yearly_Salary__c = 50000, File_Status__c = 'Single', Pay_Frequency__c = 'Monthly'),
      new Job_Application__c(Yearly_Salary__c = 75000, File_Status__c = 'Single', Pay_Frequency__c = 'Bi-weekly')
    };
    insert jobApps;

    // Retrieve the inserted job applications
    List<Job_Application__c> retrievedApps = [
      SELECT
        Id,
        Yearly_Salary__c,
        File_Status__c,
        Pay_Frequency__c,
        Gross_Pay__c,
        Income_Tax__c,
        Medicare_Tax__c,
        Social_Security_Tax__c,
        Final_Pay_Check__c
      FROM Job_Application__c
      WHERE Id IN :jobApps
    ];

    retrievedApps[0].File_Status__c = 'Head of household';
    retrievedApps[1].Pay_Frequency__c = 'Quarterly';

    Test.startTest();
    update retrievedApps;
    System.debug(retrievedApps);
    Test.stopTest();

    // Verify tax calculations
    List<Job_Application__c> updatedJobApps = [
      SELECT Gross_Pay__c, Income_Tax__c, Medicare_Tax__c, Social_Security_Tax__c, Final_Pay_Check__c
      FROM Job_Application__c
    ];
    System.assertEquals(4166.67, updatedJobApps[0].Gross_Pay__c.setScale(2), 'Wrong Gross Pay');
    System.assertEquals(253.42, updatedJobApps[0].Income_Tax__c.setScale(2), 'Wrong Income Tax');
    System.assertEquals(60.42, updatedJobApps[0].Medicare_Tax__c.setScale(2), 'Wrong Medicare Tax');
    System.assertEquals(258.33, updatedJobApps[0].Social_Security_Tax__c.setScale(2), 'Wrong Social Security Tax');
    System.assertEquals(3594.50, updatedJobApps[0].Final_Pay_Check__c.setScale(2), 'Wrong Final pay check');
    System.assertEquals(18750.00, updatedJobApps[1].Gross_Pay__c.setScale(2), 'Wrong Gross Pay');
    System.assertEquals(2085.25, updatedJobApps[1].Income_Tax__c.setScale(2), 'Wrong Income Tax');
    System.assertEquals(271.88, updatedJobApps[1].Medicare_Tax__c.setScale(2), 'Wrong Medicare Tax');
    System.assertEquals(1162.50, updatedJobApps[1].Social_Security_Tax__c.setScale(2), 'Wrong Social Security Tax');
    System.assertEquals(15230.38, updatedJobApps[1].Final_Pay_Check__c.setScale(2), 'Wrong Final Pay Check');
  }
}

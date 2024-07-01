public with sharing class JobApplicationHelper {
  //The CreateTasks method will be used on the JobApplicationHandler to create tasks when the record is inserted or updated.
  public static void createTasks(List<Job_Application__c> jobAppList, Map<Id, Job_Application__c> oldJobAppMap) {
    //Tasks to Insert
    List<Task> taskListToInsert = new List<Task>();
    //Query Metadata that contains the Job Application Tasks records.
    List<Job_Application_Task__mdt> jobAppTaskMDList = [
      SELECT Job_Application_Status__c, Priority__c, Subject__c, Cumulative_Days__c
      FROM Job_Application_Task__mdt
    ];
    //Loop through Job Application and Metadata records.
    for (Job_Application__c jobApp : jobAppList) {
      Job_Application__c oldJobApp = new Job_Application__c();
      if (oldJobAppMap != null) {
        oldJobApp = oldJobAppMap.get(jobApp.Id);
      }
      for (Job_Application_Task__mdt jobAppTask : jobAppTaskMDList) {
        //If Job Application and Metadata Status match create a task.
        if ((jobApp.Status__c == jobAppTask.Job_Application_Status__c) && (jobApp.Status__c != oldJobApp.Status__c)) {
          Task newJobAppTask = new Task(
            WhatId = jobApp.Id,
            Subject = jobAppTask.Subject__c,
            Priority = jobAppTask.Priority__c,
            ActivityDate = Date.today().addDays(Integer.valueOf(jobAppTask.Cumulative_Days__c))
          );
          //Add new task to a list.
          taskListToInsert.add(newJobAppTask);
        }
      }
    }
    try {
      // Insert all tasks in a single DML operation
      insert taskListToInsert;
    } catch (Exception e) {
      // Handle the exception, such as logging the error or displaying a message
      System.debug('Error occurred while inserting tasks: ' + e.getMessage());
    }
  }

  // Standard working hours per week and weeks per year
  private static final Integer HOURS_PER_WEEK = 40;
  private static final Integer WEEKS_PER_YEAR = 52;

  // Function to process a list of records and convert the Salary__c field
  public static List<Job_Application__c> convertSalaries(List<Job_Application__c> jobAppList) {
    List<Job_Application__c> jobAppListToUpdate = new List<Job_Application__c>();
    for (Job_Application__c jobApp : jobAppList) {
      if (jobApp.Salary__c != null && jobApp.Yearly_Salary__c == null) {
        Decimal yearlySalary = convertToYearlySalary(jobApp.Salary__c);
        jobApp.Yearly_Salary__c = yearlySalary;
        jobAppListToUpdate.add(jobApp);
      }
    }
    return jobAppListToUpdate;
  }

  // Function to convert a salary string to a yearly salary
  private static Decimal convertToYearlySalary(String salary) {
    salary = salary.replace('$', '').replace(',', '').trim().toLowerCase();

    Boolean isHourly = salary.contains('hour');
    salary = salary.replace('per hour', '').replace('hour', '').trim();

    if (salary.contains('-')) {
      String[] parts = salary.split('-');
      Decimal low = parseSalary(parts[0].trim());
      Decimal high = parseSalary(parts[1].trim());
      Decimal average = (low + high) / 2;
      return isHourly ? hourlyToYearly(average) : average;
    } else {
      Decimal singleSalary = parseSalary(salary);
      return isHourly ? hourlyToYearly(singleSalary) : singleSalary;
    }
  }

  // Helper function to parse salary and handle 'k' notation
  private static Decimal parseSalary(String salary) {
    if (salary.endsWith('k')) {
      return Decimal.valueOf(salary.replace('k', '').trim()) * 1000;
    } else {
      return Decimal.valueOf(salary);
    }
  }

  // Helper function to convert hourly rate to yearly salary
  private static Decimal hourlyToYearly(Decimal hourlyRate) {
    return hourlyRate * HOURS_PER_WEEK * WEEKS_PER_YEAR;
  }
  @AuraEnabled
  public static List<Job_Application__c> calculateTaxes(
    List<Job_Application__c> jobAppList,
    Map<Id, Job_Application__c> oldJobAppMap
  ) {
    List<Job_Application__c> jobAppListToUpdate = new List<Job_Application__c>();
    List<Income_Tax_Bracket__mdt> taxBracketList = [
      SELECT Id, Filling_Status__c, Tax_Rate__c, High_Tax_Bracket__c, Low_Tax_Bracket__c, Standard_Deduction__c
      FROM Income_Tax_Bracket__mdt
    ];
    Social_Security_Medicare_Tax_Rate__mdt socialAndMedicare = [
      SELECT Id, Social_Security__c, Medicare__c
      FROM Social_Security_Medicare_Tax_Rate__mdt
      LIMIT 1
    ];
    for (Job_Application__c jobApp : jobAppList) {
      Job_Application__c oldJobApp = new Job_Application__c();
      if (oldJobAppMap != null) {
        oldJobApp = oldJobAppMap.get(jobApp.Id);
      }
      if (
        jobApp.Yearly_Salary__c != null &&
        jobApp.File_Status__c != null &&
        (jobApp.File_Status__c != oldJobApp.File_Status__c ||
        jobApp.Pay_Frequency__c != oldJobApp.Pay_Frequency__c)
      ) {
        Decimal incomeTaxCalculation = 0;
        for (Income_Tax_Bracket__mdt taxBracket : taxBracketList) {
          Decimal taxableIncome = jobApp.Yearly_Salary__c - taxBracket.Standard_Deduction__c;
          if (taxBracket.Filling_Status__c == jobApp.File_Status__c && taxBracket.Low_Tax_Bracket__c <= taxableIncome) {
            if (taxBracket.High_Tax_Bracket__c <= taxableIncome) {
              incomeTaxCalculation +=
                (taxBracket.High_Tax_Bracket__c - taxBracket.Low_Tax_Bracket__c) *
                taxBracket.Tax_Rate__c *
                0.01;
            } else {
              incomeTaxCalculation += (taxableIncome - taxBracket.Low_Tax_Bracket__c) * taxBracket.Tax_Rate__c * 0.01;
            }
          }
        }
        jobApp.Income_Tax__c = incomeTaxCalculation;
        jobApp.Gross_Pay__c = jobApp.Yearly_Salary__c / jobApp.Pay_Frequency_Value__c;
        jobApp.Income_Tax__c = jobApp.Income_Tax__c / jobApp.Pay_Frequency_Value__c;
        jobApp.Social_Security_Tax__c =
          (jobApp.Yearly_Salary__c * socialAndMedicare.Social_Security__c * 0.01) / jobApp.Pay_Frequency_Value__c;
        jobApp.Medicare_Tax__c =
          (jobApp.Yearly_Salary__c * socialAndMedicare.Medicare__c * 0.01) / jobApp.Pay_Frequency_Value__c;
        jobApp.Final_Pay_Check__c =
          jobApp.Gross_Pay__c -
          jobApp.Income_Tax__c -
          jobApp.Social_Security_Tax__c -
          jobApp.Medicare_Tax__c;
        jobAppListToUpdate.add(jobApp);
      }
    }
    return jobAppListToUpdate;
  }
}

@IsTest
private class EmailReminderScheduleTest {
  @IsTest
  static void testEmailReminderScheduledForTomorrow() {
    // Prepare a user with interviews scheduled for tomorrow
    User testUserWithInterviewsForTomorrow = createUserWithInterviewsForTomorrow();

    Test.startTest();
    EmailReminderSchedule.scheduleJob();
    Test.stopTest();

    // Verify that an email message was sent
    List<EmailMessage> emailMessages = [SELECT Id, Subject FROM EmailMessage];
    System.assertEquals(1, emailMessages.size(), 'Expected one Email message to be sent.');
    System.assertEquals('Interview Reminder', emailMessages[0].Subject, 'Unexpected Email Subject.');
  }

  @IsTest
  static void testEmailReminderNotScheduledForTomorrow() {
    // Prepare a user without interviews scheduled for tomorrow
    User testUserWithoutInterviews = createUserWithoutInterviews();

    Test.startTest();
    EmailReminderSchedule.scheduleJob();
    Test.stopTest();

    // Verify that no email message was sent
    List<EmailMessage> emailMessages = [SELECT Id, Subject FROM EmailMessage];
    System.assertEquals(0, emailMessages.size(), 'No Email should be sent when no interviews are scheduled.');
  }

  // Helper method to create a user with interviews scheduled for tomorrow
  private static User createUserWithInterviewsForTomorrow() {
    Id standardUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    User testUser = new User(
      FirstName = 'John',
      LastName = 'Test',
      Username = 'jtest@cca.com',
      Email = 'jtest@cca.com',
      Alias = 'jtest',
      ProfileId = standardUserProfileId,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );

    insert testUser;

    // Create interviews scheduled for tomorrow
    createInterviewsForTomorrow(testUser);

    return testUser;
  }

  // Helper method to create a user without interviews scheduled for tomorrow
  private static User createUserWithoutInterviews() {
    Id standardUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    User testUser = new User(
      FirstName = 'Pedro',
      LastName = 'test',
      Username = 'ptest@cca.com',
      Email = 'ptest@cca.com',
      Alias = 'ptest',
      ProfileId = standardUserProfileId,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );

    insert testUser;

    // Create interviews not scheduled for tomorrow
    createInterviews(testUser);

    return testUser;
  }

  // Helper method to create interviews scheduled for tomorrow
  private static void createInterviewsForTomorrow(User testUser) {
    List<Event> interviews = new List<Event>{
      new Event(
        OwnerId = testUser.Id,
        Subject = 'Interview',
        StartDateTime = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(9, 0, 0, 0)),
        EndDateTime = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(10, 0, 0, 0))
      ),
      new Event(
        OwnerId = testUser.Id,
        Subject = 'Interview 2',
        StartDateTime = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(11, 0, 0, 0)),
        EndDateTime = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(12, 0, 0, 0))
      )
    };
    insert interviews;
  }

  // Helper method to create interviews not scheduled for tomorrow
  private static void createInterviews(User testUser) {
    List<Event> interviews = new List<Event>{
      new Event(
        OwnerId = testUser.Id,
        Subject = 'Interview',
        StartDateTime = Datetime.newInstance(Date.today().addDays(3), Time.newInstance(9, 0, 0, 0)),
        EndDateTime = Datetime.newInstance(Date.today().addDays(3), Time.newInstance(10, 0, 0, 0))
      ),
      new Event(
        OwnerId = testUser.Id,
        Subject = 'Interview 2',
        StartDateTime = Datetime.newInstance(Date.today().addDays(5), Time.newInstance(11, 0, 0, 0)),
        EndDateTime = Datetime.newInstance(Date.today().addDays(5), Time.newInstance(12, 0, 0, 0))
      )
    };
    insert interviews;
  }
}

public with sharing class EmailReminderSchedule implements Schedulable {
  // This method is executed when the scheduled job runs.
  public void execute(SchedulableContext sc) {
    // Query for events (interviews) scheduled for the next day.
    List<Event> interviews = [
      SELECT Id, ActivityDate, OwnerId, Owner.Email, Subject
      FROM Event
      WHERE ActivityDate = NEXT_N_DAYS:1
    ];

    // Check if there are any interviews found.
    if (!interviews.IsEmpty()) {
      Set<Id> applicantIds = new Set<Id>(); // Set to store unique applicant IDs.
      Map<Id, List<Event>> applicantIdByInterviews = new Map<Id, List<Event>>(); // Map to group interviews by applicant ID.

      // Iterate through each interview to populate the set and map.
      for (Event interview : interviews) {
        applicantIds.add(interview.OwnerId); // Add applicant ID to the set.

        // If applicant ID is not already in the map, initialize a new list for interviews.
        if (!applicantIdByInterviews.containsKey(interview.OwnerId)) {
          List<Event> interviewPlaceholder = new List<Event>();
          applicantIdByInterviews.put(interview.OwnerId, interviewPlaceholder);
        }
        // Add the interview to the list associated with the applicant ID.
        applicantIdByInterviews.get(interview.OwnerId).add(interview);
      }

      // Iterate over each applicant and send an email with their scheduled interviews.
      for (Id applicantId : applicantIds) {
        sendEmail(applicantIdByInterviews.get(applicantId)); // Call the email sending method.
      }
    }
  }

  // This method sends an email reminder with the details of upcoming interviews.
  public void sendEmail(List<Event> interviews) {
    String toAddress = interviews[0].Owner.Email;
    String subject = 'Interview Reminder';

    // Construct the email body with interview details.
    String body = 'You have the following interviews scheduled for tomorrow:<br/><br/>';

    // Add each interview as a link in the email body.
    for (Event interview : interviews) {
      String recordLink = url.getOrgDomainUrl().toExternalForm() + '/' + interview.Id; // Create a link to the interview record.
      body += '• <a href="' + recordLink + '">' + interview.Subject + '</a><br/>'; // Append the link to the email body.
    }

    // Create the email message.
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new List<String>{ toAddress });
    email.setSubject(subject);
    email.setHtmlBody(body);
    System.debug(email);
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }); // Send the email.
  }

  // This method schedules the job to run daily using a cron expression.
  public static void scheduleJob() {
    String cronExpression = '0 0 0 * * ?'; // Cron expression to run the job at midnight every day.
    EmailReminderSchedule reminderJob = new EmailReminderSchedule(); // Instantiate the job.

    System.schedule('Email Reminder Job', cronExpression, reminderJob); // Schedule the job with the given cron expression.
  }
}

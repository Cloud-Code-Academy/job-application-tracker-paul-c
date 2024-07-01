public with sharing class EventHelper {
  // This method checks a list of events to prevent overlap with existing events.
  public static void preventOverlabEvents(List<Event> events) {
    // Query to fetch existing events excluding the current list of events.
    List<Event> existingEvents = [
      SELECT Id, Subject, StartDateTime, EndDateTime
      FROM Event
      WHERE Id NOT IN :events
    ];

    // Iterate over each new event to check for overlaps with existing events.
    for (Event evnt : events) {
      for (Event existingEvent : existingEvents) {
        // Check if the start time of the new event overlaps with the existing event.
        if (
          (evnt.StartDateTime.getTime() >= existingEvent.StartDateTime.getTime() &&
          evnt.StartDateTime.getTime() < existingEvent.EndDateTime.getTime()) ||
          // Check if the end time of the new event overlaps with the existing event.
          (evnt.EndDateTime.getTime() <= existingEvent.EndDateTime.getTime() &&
          evnt.EndDateTime.getTime() > existingEvent.StartDateTime.getTime())
        ) {
          // Add an error to the event if there is an overlap with an existing event.
          evnt.addError(
            'The Time of this Event overlaps with the following Event: ' +
              existingEvent.Subject +
              ' (' +
              existingEvent.StartDateTime.format() +
              ' - ' +
              existingEvent.EndDateTime.format() +
              ')'
          );
        }
      }
    }
  }
}

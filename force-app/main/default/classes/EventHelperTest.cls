@isTest
public with sharing class EventHelperTest {
  @testSetup
  static void setupTestData() {
    // Create existing events
    List<Event> existingEvents = new List<Event>{
      new Event(
        Subject = 'Existing Event 1',
        StartDateTime = DateTime.now().addDays(-1),
        EndDateTime = DateTime.now().addDays(-1).addHours(1)
      ),
      new Event(
        Subject = 'Existing Event 2',
        StartDateTime = DateTime.now().addHours(1),
        EndDateTime = DateTime.now().addHours(2)
      )
    };
    System.debug(existingEvents);
    insert existingEvents;
  }

  @isTest
  static void testNoOverlap() {
    List<Event> newEvents = new List<Event>{
      new Event(
        Subject = 'Test Event',
        StartDateTime = DateTime.now().addHours(3),
        EndDateTime = DateTime.now().addHours(4)
      )
    };

    Test.startTest();
    EventHelper.preventOverlabEvents(newEvents);
    Test.stopTest();

    // Assert no error messages were added
    for (Event evnt : newEvents) {
      System.assertEquals(0, evnt.getErrors().size(), 'There should be no errors for non-overlapping events.');
    }
  }

  @isTest
  static void testStartTimeOverlap() {
    List<Event> newEvents = new List<Event>{
      new Event(
        Subject = 'Test Event Overlap Start',
        StartDateTime = DateTime.now().addMinutes(30),
        EndDateTime = DateTime.now().addHours(1).addMinutes(30)
      )
    };

    Test.startTest();
    EventHelper.preventOverlabEvents(newEvents);
    Test.stopTest();

    // Assert error messages were added for overlap
    for (Event evnt : newEvents) {
      System.assertEquals(1, evnt.getErrors().size(), 'There should be one error for overlapping events.');
    }
  }

  @isTest
  static void testEndTimeOverlap() {
    List<Event> newEvents = new List<Event>{
      new Event(
        Subject = 'Test Event Overlap End',
        StartDateTime = DateTime.now().addMinutes(-30),
        EndDateTime = DateTime.now().addMinutes(70)
      )
    };

    Test.startTest();
    EventHelper.preventOverlabEvents(newEvents);
    System.debug(newEvents);
    Test.stopTest();

    // Assert error messages were added for overlap
    for (Event evnt : newEvents) {
      System.assertEquals(1, evnt.getErrors().size(), 'There should be one error for overlapping events.');
    }
  }

  @isTest
  static void testFullOverlap() {
    List<Event> newEvents = new List<Event>{
      new Event(
        Subject = 'Test Event Full Overlap',
        StartDateTime = DateTime.now().addMinutes(30),
        EndDateTime = DateTime.now().addMinutes(90)
      )
    };

    Test.startTest();
    EventHelper.preventOverlabEvents(newEvents);
    Test.stopTest();

    // Assert error messages were added for overlap
    for (Event evnt : newEvents) {
      System.assertEquals(1, evnt.getErrors().size(), 'There should be one error for fully overlapping events.');
    }
  }

  @isTest
  static void testAllDayEventNoOverlap() {
    List<Event> newEvents = new List<Event>{
      new Event(
        Subject = 'Test All Day Event',
        StartDateTime = Date.today(),
        EndDateTime = Date.today().addDays(1),
        IsAllDayEvent = true
      )
    };

    Test.startTest();
    EventHelper.preventOverlabEvents(newEvents);
    Test.stopTest();

    // Assert no error messages were added for non-overlapping all-day event
    for (Event evnt : newEvents) {
      System.assertEquals(0, evnt.getErrors().size(), 'There should be no errors for non-overlapping all-day events.');
    }
  }
}

public with sharing class EventTriggerHandler extends TriggerHandler {
  private List<Event> newEventList;
  private List<Event> oldEventList;
  private Map<Id, Event> newEventMap;
  private Map<Id, Event> oldEventMap;

  public EventTriggerHandler() {
    this.newEventList = (List<Event>) Trigger.new;
    this.oldEventList = (List<Event>) Trigger.old;
    this.newEventMap = (Map<Id, Event>) Trigger.newMap;
    this.oldEventMap = (Map<Id, Event>) Trigger.oldMap;
  }

  public override void beforeInsert() {
    EventHelper.preventOverlabEvents(newEventList);
  }

  public override void beforeUpdate() {
    EventHelper.preventOverlabEvents(newEventList);
  }
}

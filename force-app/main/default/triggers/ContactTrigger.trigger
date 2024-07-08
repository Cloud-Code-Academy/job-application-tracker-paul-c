trigger ContactTrigger on Contact(after insert, after delete) {
  ContactTriggerHandler handler = new ContactTriggerHandler();
  handler.run();
}

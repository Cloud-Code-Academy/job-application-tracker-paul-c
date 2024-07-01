@isTest
public with sharing class JoobleHttpCalloutMock implements HttpCalloutMock {
  public HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(
      '{"totalCount": 2, "jobs": [' +
        '{"title": "Salesforce Developer", "location": "Florida", "snippet": "Test Job",' +
        '"salary": "$105k - $125k", "source": "applicantpro.com", "type": "Full-time", "link": "https://jooble.org/",' +
        '"company": "Test", "updated": "2024-05-30T10:10:00.5800000", "id": 8356467325371559890},' +
        '{"title": "Lead Salesforce Developer", "location": "West Palm Beach, FL", "snippet": "Test Job",' +
        '"salary": "$55 - $65 per hour", "source": "kforce.com", "type": "Temporary", "link": "https://jooble.org/",' +
        '"company": "Test", "updated": "2024-06-06T23:42:38.5966232+00:00", "id": -4952732130844116104}' +
        ']}'
    );
    res.setStatusCode(200);
    return res;
  }
}

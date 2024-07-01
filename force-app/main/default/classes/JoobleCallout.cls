public with sharing class JoobleCallout {
  // Expose this method to Lightning components with client-side caching enabled.
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> postCallout(
    String keywords,
    String location,
    Integer page,
    String salary,
    String datecreatedfrom
  ) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();

    // Fetch the API key from custom metadata.
    String apiKey = [SELECT API_Key__c FROM Jooble_API__mdt LIMIT 1].API_Key__c;

    // Set API endpoint and request method.
    request.setEndpoint('callout:JoobleAPI' + '/' + apiKey);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json;charset=UTF-8');

    // Construct request body with dynamic parameters.
    String requestBody = '"keywords":"' + keywords + '", "location":"' + location + '", "page":"' + page + '"';
    if (salary != '') {
      requestBody += ', "salary":' + salary;
    }
    if (datecreatedfrom != '') {
      requestBody += ', "datecreatedfrom":"' + datecreatedfrom + '"';
    }
    request.setBody('{' + requestBody + '}');

    // Send HTTP request and handle response.
    HttpResponse response = http.send(request);
    Map<String, Object> jobApps = new Map<String, Object>();
    if (response.getStatusCode() >= 200 && response.getStatusCode() <= 299) {
      jobApps = createJobApplicationsFromJSON(response.getBody());
    } else {
      System.debug('Unexpected status code: ' + response.getStatusCode());
    }
    return jobApps;
  }

  // Convert JSON response to a map of job applications.
  public static Map<String, Object> createJobApplicationsFromJSON(String jsonResponse) {
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
    Map<String, Object> jobAppsMap = new Map<String, Object>();

    // Extract total job count and job list.
    jobAppsMap.put('totalCount', (Integer) jsonMap.get('totalCount'));
    List<Object> jobs = (List<Object>) jsonMap.get('jobs');

    // Map each job to a Job_Application__c record.
    List<Job_Application__c> jobApps = new List<Job_Application__c>();
    for (Object jobObj : jobs) {
      Map<String, Object> job = (Map<String, Object>) jobObj;
      Job_Application__c jobApp = new Job_Application__c();
      jobApp.Position_Title__c = (String) job.get('title');
      jobApp.Location__c = (String) job.get('location');
      jobApp.Description__c = (String) job.get('snippet');
      jobApp.URL__c = (String) job.get('link');
      jobApp.Company_Name__c = (String) job.get('company');
      jobApp.Salary__c = (String) job.get('salary');
      jobApp.Posted_Date__c = job.get('updated') == ''
        ? null
        : date.valueOf(String.valueOf(job.get('updated')).left(10));
      jobApps.add(jobApp);
    }
    jobAppsMap.put('jobs', jobApps);
    return jobAppsMap;
  }

  // Insert job applications into the database.
  @AuraEnabled
  public static void insertJobApplications(List<Job_Application__c> jobs) {
    try {
      insert jobs;
    } catch (Exception e) {
      System.debug('Insertion error: ' + e.getMessage());
    }
  }
}

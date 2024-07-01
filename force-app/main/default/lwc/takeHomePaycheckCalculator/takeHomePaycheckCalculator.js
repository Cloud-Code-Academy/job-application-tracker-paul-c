import { LightningElement, wire, api, track } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import calculateTaxes from "@salesforce/apex/JobApplicationHelper.calculateTaxes";
//Job Application Fields
const FIELDS = [
  "Job_Application__c.Yearly_Salary__c",
  "Job_Application__c.File_Status__c",
  "Job_Application__c.Pay_Frequency__c",
  "Job_Application__c.Pay_Frequency_Value__c",
  "Job_Application__c.Final_Pay_Check__c",
  "Job_Application__c.Gross_Pay__c",
  "Job_Application__c.Income_Tax__c",
  "Job_Application__c.Medicare_Tax__c",
  "Job_Application__c.Social_Security_Tax__c"
];
// Pay Frequency Values
const payFrequencyMap = {
  Daily: 260,
  Weekly: 52,
  "Bi-weekly": 26,
  "Semi-monthly": 24,
  Monthly: 12,
  Quarterly: 4,
  "Semi-annually": 2,
  Annually: 1
};
// Format Number (2 Decimal Places)
let formatNumber = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

export default class TakeHomePaycheckCalculator extends LightningElement {
  // Properties
  @api recordId;
  @track jobAppData;
  @track fileStatusValue;
  @track payFrequencyValue;
  @track jobApp;
  // Returns the options for the File Status combobox
  get fileStatusOptions() {
    return [
      { label: "Single", value: "Single" },
      { label: "Married filing jointly", value: "Married filing jointly" },
      { label: "Married filing separately", value: "Married filing separately" },
      { label: "Head of household", value: "Head of household" }
    ];
  }
  // Returns the options for the Pay Frequency combobox
  get payFrequencyOptions() {
    return [
      { label: "Daily", value: "Daily" },
      { label: "Weekly", value: "Weekly" },
      { label: "Bi-weekly", value: "Bi-weekly" },
      { label: "Semi-monthly", value: "Semi-monthly" },
      { label: "Monthly", value: "Monthly" },
      { label: "Quarterly", value: "Quarterly" },
      { label: "Semi-annually", value: "Semi-annually" },
      { label: "Annually", value: "Annually" }
    ];
  }
  // Handle Change File Status
  // Sets the fileStatusOptions value into the fileStatusValue property
  // Sets the fileStatusOptions value into the File_Status__c field
  handleChangeFileStatus(event) {
    this.fileStatusValue = event.detail.value;
    this.jobApp.File_Status__c = event.detail.value;
  }
  // Handle Change Pay Frequency
  // Sets the payFrequencyOptions value into the payFrequencyValue property
  // Sets the payFrequencyOptions value into the Pay_Frequency__c field
  // Sets the result of getPayPeriodsPerYear into the Pay_Frequency_Value__c field
  handleChangePayFrequency(event) {
    this.payFrequencyValue = event.detail.value;
    this.jobApp.Pay_Frequency__c = event.detail.value;
    this.jobApp.Pay_Frequency_Value__c = this.getPayPeriodsPerYear(event.detail.value);
  }
  // Return the payFrequencyMap value that matches the payFrequency
  getPayPeriodsPerYear(payFrequency) {
    return payFrequencyMap[payFrequency] || 0;
  }

  // Fetch the record data
  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredJobApp({ error, data }) {
    if (data) {
      this.jobAppData = data;
      // Prepare the job application data for the Apex method
      this.fileStatusValue = this.jobAppData.fields.File_Status__c.value;
      this.payFrequencyValue = this.jobAppData.fields.Pay_Frequency__c.value;
      this.jobApp = {
        Id: this.recordId,
        Yearly_Salary__c: this.jobAppData.fields.Yearly_Salary__c.value,
        File_Status__c: this.fileStatusValue,
        Pay_Frequency__c: this.payFrequencyValue,
        Pay_Frequency_Value__c: this.jobAppData.fields.Pay_Frequency_Value__c.value,
        Final_Pay_Check__c: formatNumber.format(this.jobAppData.fields.Final_Pay_Check__c.value),
        Gross_Pay__c: formatNumber.format(this.jobAppData.fields.Gross_Pay__c.value),
        Income_Tax__c: formatNumber.format(this.jobAppData.fields.Income_Tax__c.value),
        Medicare_Tax__c: formatNumber.format(this.jobAppData.fields.Medicare_Tax__c.value),
        Social_Security_Tax__c: formatNumber.format(this.jobAppData.fields.Social_Security_Tax__c.value)
      };
    } else if (error) {
      this.jobAppData = undefined;
      this.showToast("Error", error.body.message, "error");
    }
  }

  // Call Apex method to calculate taxes and update the record
  handleCalculate() {
    if (!this.jobAppData) {
      this.showToast("Error", "Job Application data not available", "error");
      return;
    }

    // Create a map with only the required fields (empty File_Status__c and Pay_Frequency__c)
    const jobAppMap = {};
    jobAppMap[this.recordId] = {
      Id: this.recordId,
      File_Status__c: null,
      Pay_Frequency__c: null
    };

    // Call Apex method with the job application and an empty map
    calculateTaxes({ jobAppList: [this.jobApp], oldJobAppMap: jobAppMap })
      .then((result) => {
        console.log(result[0]);
        this.jobApp = result[0];
        this.jobApp.Gross_Pay__c = formatNumber.format(this.jobApp.Gross_Pay__c);
        this.jobApp.Income_Tax__c = formatNumber.format(this.jobApp.Income_Tax__c);
        this.jobApp.Medicare_Tax__c = formatNumber.format(this.jobApp.Medicare_Tax__c);
        this.jobApp.Social_Security_Tax__c = formatNumber.format(this.jobApp.Social_Security_Tax__c);
        this.jobApp.Final_Pay_Check__c = formatNumber.format(this.jobApp.Final_Pay_Check__c);
        this.showToast("Success", "Take-Home-Paycheck Calculated Successfully!", "success");
      })
      .catch((error) => {
        this.showToast("Error", error.body.message, "error");
      });
  }

  // Utility function to show toast notifications
  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}

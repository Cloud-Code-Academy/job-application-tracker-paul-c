import { LightningElement, track } from "lwc";
import postCallout from "@salesforce/apex/JoobleCallout.postCallout";
import insertJobApplications from "@salesforce/apex/JoobleCallout.insertJobApplications";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class JobSearch extends LightningElement {
  // Properties
  @track records;
  @track selectedRecords = new Set();
  jobCount;
  job = "";
  location = "";
  page = 1;
  salaryValue = "";
  datePostedValue = "";
  formattedDatePosted = "";
  // Handle Title Input
  // Sets the input value into the job property
  handleTitleInput(event) {
    this.job = event.target.value;
  }
  // Handle Location Input
  // Sets the input value into the location property
  handleLocationInput(event) {
    this.location = event.target.value;
  }
  // Handle Search Click
  // Sets page to 1
  // Calls postCallout method:
  // - Creates a new array of jobs with the IsSelected property and sets it into the records property
  // - Sets the totalcount of jobs into the jobCount property
  // Logs an error if the call of the postCallout method fails
  handleSearchClick() {
    this.page = 1;
    postCallout({
      keywords: this.job,
      location: this.location,
      page: this.page,
      salary: this.salaryValue,
      datecreatedfrom: this.formattedDatePosted
    })
      .then((result) => {
        this.records = result.jobs.map((job) => ({
          ...job,
          isSelected: false
        }));
        this.jobCount = result.totalCount.toLocaleString();
      })
      .catch((error) => {
        console.error("Error:", error);
        this.records = [];
      });
  }
  // Handle Page Change
  // Calls postCallout method:
  // - Creates a new array of jobs with the IsSelected property and sets it into the records property
  // Logs an error if the call of the postCallout method fails
  handlePageChange() {
    postCallout({
      keywords: this.job,
      location: this.location,
      page: this.page,
      salary: this.salaryValue,
      datecreatedfrom: this.formattedDatePosted
    })
      .then((result) => {
        this.records = result.jobs.map((job) => ({
          ...job,
          isSelected: false
        }));
      })
      .catch((error) => {
        console.error("Error:", error);
        this.records = [];
      });
  }
  // Handle Next Page Click
  // Increases the number of the page by 1
  // Calls the handlePageChange function
  handleNextPageClick() {
    this.page += 1;
    this.handlePageChange();
  }
  // Handle Next Page Click
  // Decreases the number of the page by 1
  // Calls the handlePageChange function
  handlePrevioustPageClick() {
    this.page -= 1;
    this.handlePageChange();
  }
  // Returns false if the page number is less or equals than 2 which makes the Previous Page Button disabled
  get disableButton() {
    return this.page >= 2;
  }
  // Returns the options for the Salary combobox
  get salaryOptions() {
    return [
      { label: "Any", value: "" },
      { label: "Higher than $30,000", value: "30000" },
      { label: "Higher than $60,000", value: "60000" },
      { label: "Higher than $90,000", value: "90000" },
      { label: "Higher than $120,000", value: "120000" },
      { label: "Higher than $150,000", value: "150000" },
      { label: "Higher than $180,000", value: "180000" }
    ];
  }
  // Handle Salary Change
  // Sets the salaryOptions value into the salaryValue property
  handleSalaryChange(event) {
    this.salaryValue = event.detail.value;
  }
  // Returns the options for the datePosted combobox
  get datePostedOptions() {
    return [
      { label: "Any", value: "" },
      { label: "Past 24 hours", value: "1" },
      { label: "Past week", value: "7" },
      { label: "Past month", value: "30" }
    ];
  }
  // Handle Date Posted Change
  // Sets the datePostedOptions value into the datePostedValue property
  handleDatePostedChange(event) {
    this.datePostedValue = event.detail.value;
    if (this.datePostedValue !== "") {
      this.formattedDatePosted = this.addDays(event.detail.value);
    } else {
      this.formattedDatePosted = "";
    }
  }
  // Calculates a date by subtracting the given number of days from the current date and returns it in a formatted string
  addDays(days) {
    let currentDate = new Date();
    days = parseInt(days, 10);
    currentDate.setDate(currentDate.getDate() - days);
    return currentDate.toJSON().slice(0, 10);
  }
  // Handle Record Selection
  // Updates isSelected property of the record and adds or deletes the record in the selectedRecords set
  handleRecordSelection(event) {
    const recordIndex = event.target.dataset.index;
    const isChecked = event.target.checked;

    this.records[recordIndex].isSelected = isChecked;

    if (isChecked) {
      this.selectedRecords.add(recordIndex.toString());
    } else {
      this.selectedRecords.delete(recordIndex.toString());
    }
  }
  // Handle Select All
  // Clear previous selectedRecords
  // Updates isSelected property of all selected records and adds the records in the selectedRecords set
  handleSelectAll(event) {
    const isChecked = event.target.checked;
    this.selectedRecords.clear();

    this.records.forEach((record, index) => {
      record.isSelected = isChecked;
      if (isChecked) {
        this.selectedRecords.add(index.toString());
      }
    });
  }
  // Handle Save
  // Calls insertJobApplications to insert the selectedRecords
  // Clears selectedRecords after the insert
  // Shows a Toast if the insertion was successfull
  // Logs an error if the call of the insertJobApplications method fails
  handleSave() {
    if (this.selectedRecords.size > 0) {
      const recordsToInsert = Array.from(this.selectedRecords).map((index) => this.records[index]);
      insertJobApplications({ jobs: recordsToInsert })
        .then(() => {
          this.selectedRecords.clear();
          this.showToast();
        })
        .catch((error) => {
          console.error("Error inserting selected records:", error);
        });
    }
  }
  // Shows a success Toast
  showToast() {
    const event = new ShowToastEvent({
      title: "Success",
      variant: "success",
      message: "The selected Jobs were inserted."
    });
    this.dispatchEvent(event);
  }
}

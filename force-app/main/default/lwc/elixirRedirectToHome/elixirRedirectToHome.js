import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomerProfileTransactionList from '@salesforce/apex/Elixir_AuthorizeCalloutController.getCustomerProfileTransactionList';
import getCustomerProfileTransactionListForPaymentPlan from '@salesforce/apex/Elixir_AuthorizeCalloutController.getCustomerProfileTransactionListForPaymentPlan';
import createSubsctiptionCall from '@salesforce/apex/Elixir_AuthorizeGatewayController.createSubsctiptionCall';
import ElixirNavigateToRecordPage from '@salesforce/label/c.ElixirNavigateToRecordPage';
import subsCreatedMsg from '@salesforce/label/c.Elixir_Subscription_Created_Toast';
import subsNotCreatedMsg from '@salesforce/label/c.Elixir_Subscription_Not_Created_Toast';

export default class ElixirRedirectToHome extends LightningElement {
    @api accId; // Account Id parameter
    @api uniqueKey; // Unique key parameter
    @api isAllocated; // IsAllocated parameter
    @api selectedProcedureRecords; // procedure Selected
    @api selectedPaymentPlanLine; // Selected Payment Plan Line record
    @api createSubscription; // boolean create subscription
    @api paymentPlanId;
    message = ElixirNavigateToRecordPage;
    navigationCalled = false;

    renderedCallback() {
        this.handleCallout();
    }

    handleCallout() {
        console.log('this.isAllocated : ',this.isAllocated);
        console.log('selectedPaymentPlanLine ', this.selectedPaymentPlanLine);
        if (this.selectedPaymentPlanLine == null ||this.selectedPaymentPlanLine == "" || this.selectedPaymentPlanLine.trim() == 'null' ) {
            getCustomerProfileTransactionList({ 
                accID: this.accId, 
                uniqueKey: this.uniqueKey, 
                isAllocated: this.isAllocated 
            })
            .then(result => {
                // Handle the result of the Apex method call
                console.log('Result from Apex: ', result);
                this.navigateToAccountRecord();
            })
            .catch(error => {
                // Handle any errors that occur during the Apex method call
                console.error('Error from Apex: ', error);
                this.navigateToAccountRecord();
            });
        } else {
            getCustomerProfileTransactionListForPaymentPlan({
                accID: this.accId, 
                uniqueKey: this.uniqueKey, 
                selectedProcedureRecords: this.selectedProcedureRecords,
                paymentPlanLineListJson: this.selectedPaymentPlanLine
            }).then(result => {
                // Handle the result of the Apex method call
                //console.log('Result from Apex: ', result);
                if (this.createSubscription) {
                    createSubsctiptionCall({
                        "accID" : this.accId,
                        "paymentPlanId" : this.paymentPlanId
                    }).then(result => {
                        // Handle the result of the Apex method call
                        console.log('Result from Apex: ', result);
                        // Success Toast 
                        const event = new ShowToastEvent({
                            title: subsCreatedMsg,
                            message: ' ',
                            variant: 'Success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);
                        this.navigateToAccountRecord();
                    })
                    .catch(error => {
                        // Handle any errors that occur during the Apex method call
                        console.error('Error from Apex: ', error);
                        // Failure Toast 
                        const event = new ShowToastEvent({
                            title: subsNotCreatedMsg,
                            message: ' ',
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.navigateToAccountRecord();
                    });;
                } else {
                    this.navigateToAccountRecord();
                }

            })
            .catch(error => {
                // Handle any errors that occur during the Apex method call
                console.error('Error from Apex: ', error);
                this.navigateToAccountRecord();
            });
        }
    }

    navigateToAccountRecord() {
        // Navigate to the Account record page
        if (!this.navigationCalled) {
            this.navigationCalled = true;
            window.location.href = window.location.origin + '/lightning/r/Account/' + this.accId + '/view';
        }
        
    }
}
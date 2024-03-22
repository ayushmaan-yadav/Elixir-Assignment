import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getPaymentPlan from '@salesforce/apex/Elixir_PaymentUtility.getPaymentPlan';
import cancelSubscription from '@salesforce/apex/Elixir_AuthorizeCalloutController.cancelSubscription';

export default class ElixirUnsubscribeCmp extends LightningElement {
    @api recordId;
    subscriptionId;
    paymentPlan;
    outputText;
    isLoading = false;
    showButtonGroup = false;
    showOkay = false;
    showButtons = false;

    @wire(getPaymentPlan, { paymentPlanId: '$recordId' })
    wiredSubscriptionId({ error, data }) {
        try {
            console.log('data : upd1 ', data);
            if (data != null) {
                this.paymentPlan = data;
                this.updateText();
            } else if (error) {
                console.error('Error retrieving subscription ID:', error);
            }
        } catch (error) {
            console.log('error : ', error);
        }
    }

    updateText() {
        this.subscriptionId = this.paymentPlan.Elixir_External_Subscription_ID__c;
        console.log(this.subscriptionId);
        if (this.subscriptionId !== '' && this.subscriptionId != undefined ) {
            this.outputText = 'Are you sure that you want to unsubscribe';
            this.showButtons = true;
            this.showButtonGroup = true;
        } else {
            this.outputText = 'You dont have an active subscription';
            this.showButtons = true;
            this.showOkay = true;
        }
    }

    handleSure() {
        this.calloutForUnsubscribe();
    }

    handleCancel() {
        // Close the quick action
        this.dispatchEvent(new CloseActionScreenEvent());
        eval("$A.get('e.force:refreshView').fire();");
    }

    handleOkay() {
        // Close the quick action
        this.dispatchEvent(new CloseActionScreenEvent());
        eval("$A.get('e.force:refreshView').fire();");
    }

    calloutForUnsubscribe() {
        this.isLoading = true;
        this.showButtonGroup = false;
        this.showOkay = false;
        cancelSubscription({
            subscriptionId: this.subscriptionId,
            paymentPlanId: this.paymentPlan.Id
        }).then((result) => {
            this.isLoading = false;
            if (result === 'Success') {
                this.showButtons = true;
                console.log('Subscription cancellation was successful');
                this.outputText = 'Subscription cancellation was successful'; 
                this.showOkay = true;
            } else {
                this.showButtons = true;
                this.outputText = result;
                console.log(result);
                this.showOkay = true;
            }
        }).catch((errors) => {
            this.showButtons = true;
            console.log(errors);
            this.isLoading = false;
            this.showOkay = true;
        });
    }
}
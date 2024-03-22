import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPaymentInfo from '@salesforce/apex/Elixir_PaymentUtility.getPaymentInfoLst';
import newPaymentPlan from '@salesforce/apex/Elixir_AuthorizeGatewayController.authorizeNewPaymentForPaymentPlan';
import existingPaymentPlan from '@salesforce/apex/Elixir_AuthorizeCalloutController.createSubscription';
import validationScreenContent from '@salesforce/label/c.Elixir_Subscription_Validation_Screen';
import mainScreenContent from '@salesforce/label/c.Elixir_Subscription_Main_Screen';
import subsAlreadyCreated from '@salesforce/label/c.Elixir_Subscription_Already_Created';
import subsCreatedMsg from '@salesforce/label/c.Elixir_Subscription_Created_Toast';
import subsNotCreatedMsg from '@salesforce/label/c.Elixir_Subscription_Not_Created_Toast';

export default class ElixirCreateSubscriptionCmp extends LightningElement {
    @api content;
    @api recordId; 
    isShowModal = true;
    @api payInfOpt;
    @api extSubsId = false;
    @api validationScreen = false;
    @api mainScreen = false;
    @track paymentOptions;
    @track paymentInfoMap = new Map();
    @api amountPd;
    @api paymentPlanLineLst;
    @api patientId;
    @api patientRec;
    @api paymentPlanRec;
    @api selectedPaymentInfo;
    @api isLoaded = false;

    @wire(CurrentPageReference)
 getStateParameters(currentPageReference) {
     if (currentPageReference) {
         this.recordId = currentPageReference.state.recordId;
     }
 }

 getPaymentInf(obj)
    {
        this.isLoaded = true;
        getPaymentInfo({ payPlanId : obj})
        .then(result => {
            console.log('result***',result);
            var payInfo = result.paymentInfoLst;
            this.amountPd = result.amtPaid;
            this.paymentPlanLineLst = result.paymentPlanLineLst;
            this.patientId = result.accountId;
            this.patientRec = result.accountRec;
            this.paymentPlanRec = result.payPlanRec;
            var payPlan = result.payPlanRec;
            if(payPlan.Elixir_External_Subscription_ID__c != '' && payPlan.Elixir_External_Subscription_ID__c != null){
                this.extSubsId = true;
            }
            this.isLoaded = false;
           if(payInfo.length>0)
           {
            this.content = mainScreenContent ;
            this.payInfOpt = true;
            this.mainScreen = true;

            this.paymentOptions = [];
            for(let i=0; i<payInfo.length; i++) {
                var res = payInfo[i].ElixirSuite__Credit_Card_Number__c +' - '+ payInfo[i].ElixirSuite__Expiration_Month__c+ ' - '+payInfo[i].ElixirSuite__Expiration_Year__c;
                this.paymentOptions = [...this.paymentOptions ,{value: payInfo[i].Id , label: res}];
                this.paymentInfoMap.set(payInfo[i].Id,payInfo[i]);                            
            }

            }
            if(payInfo.length==0){
                this.content = validationScreenContent ;
                this.payInfOpt = false;
                this.validationScreen = true;
            }

            if(this.extSubsId == true){
                this.content = subsAlreadyCreated ;
                this.payInfOpt = false;
            }
        })
        .catch(error => {
            console.log('error***upd1',error);
            this.message = undefined;
            this.error = error;
        });
    }

    newPayment(obj)
    {
        this.isLoaded = true;
        newPaymentPlan({ amountPaid : this.amountPd, paymentPlanLine : this.paymentPlanLineLst, selectedProcedureRecords : '', accountId : this.patientId , createSubscription : true , PaymentPlanId : obj})
        .then(result => {
            console.log('result***upd2',result);
           window.location.href = window.location.origin + result.msgStr;
          // this.isLoaded = false;
        })
        .catch(error => {
            this.message = undefined;
            this.error = error;
        });
    }

    createPayment()
    {
        this.isLoaded = true;
        existingPaymentPlan({ acc : this.patientRec, paymentPlanInfo : this.paymentPlanRec, paymentInfo : this.paymentInfoMap.get(this.selectedPaymentInfo)})
        .then(result => {
            console.log('result***',result);
            this.isLoaded = false;
            const event = new ShowToastEvent({
                title: subsCreatedMsg,
                message: ' ',
                variant: 'Success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            
        this.isShowModal = false;
        this.dispatchEvent(new CloseActionScreenEvent()); 
        eval("$A.get('e.force:refreshView').fire();");
        })
        .catch(error => {
            console.log('error***upd1',error);
            const event = new ShowToastEvent({
                title: subsNotCreatedMsg,
                message: ' ',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.message = undefined;
            this.error = error;
            this.isShowModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
            
        });
    }
    
    handleCancel() {
        this.isShowModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    newPaymentMeth() {
        this.newPayment(this.recordId);
    }

    handleSubscribe() {
        this.createPayment();
    }

    handleRadioChange(event){
        this.selectedPaymentInfo = event.detail.value;
        console.log('value***',event.detail.value);
        console.log('handleRadioChange****upd1',JSON.stringify(this.selectedPaymentInfo));
    }

    connectedCallback() {
        // Perform initialization tasks here
        console.log('Component initialized***upd53');
        console.log('recordId****upd1',this.recordId);
        this.getPaymentInf(this.recordId);
    }
}
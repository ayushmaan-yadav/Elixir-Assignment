import { LightningElement ,api} from 'lwc';

export default class CreateSubscriptionButton extends LightningElement {
    @api message = 'In Progress';
    @api duration = 2000;

    connectedCallback() {
        alert(this.message);
        setTimeout(() => {
            const closeModalEvent = new CustomEvent('closemodal');
            this.dispatchEvent(closeModalEvent);
        }, this.duration);
    }
}
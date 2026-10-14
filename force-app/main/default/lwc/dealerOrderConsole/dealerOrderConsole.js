
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOrdersForDealer
    from '@salesforce/apex/DealerOrderService.getOrdersForDealer';

import createDraftOrder
    from '@salesforce/apex/DealerOrderService.createDraftOrder';

const COLUMNS = [
    { label: 'Order Number', fieldName: 'Name', type: 'text' },
    { label: 'Status', fieldName: 'Order_Status__c', type: 'text' },
    { label: 'Order Date', fieldName: 'Order_Date__c', type: 'date' },
    {
        label: 'Delivery Date',
        fieldName: 'Requested_Delivery_Date__c',
        type: 'date'
    },
    { label: 'Subtotal', fieldName: 'Subtotal__c', type: 'currency' },
    { label: 'Final Amount', fieldName: 'Final_Amount__c', type: 'currency' }
];

export default class DealerOrderConsole extends LightningElement {
    selectedDealerId;
    deliveryDate;
    orders = [];
    columns = COLUMNS;
    isBusy = false;
    hasLoadedOrders = false;

    get hasOrders() {
        return this.orders.length > 0;
    }

    get isCreateDisabled() {
        return !this.selectedDealerId ||
            !this.deliveryDate ||
            this.isBusy;
    }

    handleDealerChange(event) {
        this.selectedDealerId = event.detail.recordId;
        this.orders = [];
        this.hasLoadedOrders = false;

        if (this.selectedDealerId) {
            this.loadOrders();
        }
    }

    handleDateChange(event) {
        this.deliveryDate = event.target.value;
    }

    handleLoadOrders() {
        this.loadOrders();
    }

    async loadOrders() {
        if (!this.selectedDealerId) {
            return;
        }

        this.isBusy = true;

        try {
            this.orders = await getOrdersForDealer({
                dealerId: this.selectedDealerId
            });

            this.hasLoadedOrders = true;
        } catch (error) {
            this.showToast(
                'Unable to load orders',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isBusy = false;
        }
    }

    async handleCreateOrder() {
        if (this.isCreateDisabled) {
            return;
        }

        this.isBusy = true;

        try {
            await createDraftOrder({
                dealerId: this.selectedDealerId,
                requestedDeliveryDate: this.deliveryDate
            });

            this.showToast(
                'Success',
                'Draft order created successfully.',
                'success'
            );

            await this.loadOrders();
        } catch (error) {
            this.showToast(
                'Unable to create order',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isBusy = false;
        }
    }

    getErrorMessage(error) {
        return error?.body?.message ||
            error?.message ||
            'An unexpected error occurred.';
    }

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

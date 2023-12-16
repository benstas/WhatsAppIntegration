import { api, LightningElement, track } from 'lwc';

import listAllMessageByCustomer from '@salesforce/apex/WpLWCHandler.listAllMessageByCustomer';
import sendTextMessage from '@salesforce/apex/WpLWCHandler.sendTextMessage';
import getSingleMessage from '@salesforce/apex/WpLWCHandler.getSingleMessage';
import { subscribe, onError } from 'lightning/empApi';

export default class WhatsAppChatComponent extends LightningElement {
    
    @api recordId;

    @track ListMessage;
    @track errors;

    channelName = '/event/WAMessageEvent__e';

    subscription = {};

    chatMessage
    customerNo;
    isSpinner = false;
    chatEnabled = false;

    handleChatChange(event){
        event.preventDefault();
        this.chatMessage = event.target.value;
    }

    connectedCallback(){
        this.registerErrorListener();
        this.handleSubscribe();
    }

    handlelistAllMessageByCustomer(event){
        event.preventDefault();
        if(!this.handleValidate()){
            return;
        }
        this.isSpinner = true;
        listAllMessageByCustomer({
            customerPhone : this.customerNo
        })
        .then(result => {
            this.ListMessage =  result.map(item => {
                return {
                    ...item,
                    areaLabel: item.Outgoing__c ? `${item.AgentName__c} said at ${item.CreatedDate}` : `${item.CustomerName__c} said at ${item.CreatedDate}`
                }
            });
            this.chatEnabled = true;
        })
        .catch(error => {
            console.error('Error:', error);
            this.errors = error;
        })
        .finally(()=>{
            this.chatEnabled = true;
            console.log('turing off the spinner');
            const chatArea = this.template.querySelector('.messageContent');
            if(chatArea){
                chatArea.scrollTop = chatArea.scrollHeight
            }
            this.isSpinner = false;
            
            this.setUpChatMessage();
        })
    }

    setUpChatMessage(){
        let chatInput = this.template.querySelector(".chat-input");
        if(chatInput){
            chatInput.addEventListener("keydown", (event) => {
                console.log(`Enent handler added`)
                if (event.key === "Enter") {
                    this.handleSendMessage();
                }
            });
        }
    }

    handleSendMessage(){
        
        console.log('Enter Clicked ', this.chatMessage );
        if(!this.handleValidate()){
            return;
        }
        this.isSpinner = true;
        console.log(this.customerNo);
        sendTextMessage({
            messageContent : this.chatMessage,
            toPhone : this.customerNo
        })
        .then(result => {
            console.log(' message list ', result );
            this.chatMessage = '';
            this.ListMessage = [...this.ListMessage, result];
            console.log(' Updated Message from ', this.ListMessage );
        })
        .catch(error => {
            // TODO Error handling
        })
        .finally(()=>{
            console.log('turing off the spinner');
            this.isSpinner = false;
        })
    }

    handlePhoneChange(event){
        this.customerNo = event.target.value;
    }

    handleOtherChat(event){
        event.preventDefault();
        this.ListMessage = undefined;
        this.chatEnabled = false;
    }

    handleValidate(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = this.handleEventResponse.bind(this);

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleEventResponse(response) {
        console.log('New message received: ', JSON.stringify(response));
        let payload = response.data.payload;
        let MessageId = payload.MessageId__c;
        let CustomerPhone = payload.CustomerPhone__c;
        
        if(this.customerNo === CustomerPhone){
            getSingleMessage({
                recordId : MessageId,
                customerPhone : CustomerPhone
            })
            .then(result => {
                this.ListMessage = [...this.ListMessage, result];
                const chatArea = this.template.querySelector('.messageContent');
                if(chatArea){
                    chatArea.scrollTop = chatArea.scrollHeight
                }
            })
            .catch(error => {
                // TODO Error handling
                console.error(error);

            });
        }
    }
}
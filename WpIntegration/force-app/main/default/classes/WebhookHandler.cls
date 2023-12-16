@RestResource(urlMapping='/whatsapp/webhooks/v1/*')

global without sharing class WebhookHandler {
    
    private static Final String VALID_MESSAGE     = 'Verified...';
    private static Final String NOT_VALID_MESSAGE = 'Result could not be verified';
    @HttpGet 
    global static void getCol() {
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;
        if(request.params.get('hub.verify_token') == 'TOKENWHATSAPP'){
            response.responseBody = Blob.valueOf( request.params.get('hub.challenge') );
        }
    }

    @HttpPost // POST
    global static void postCol() {
        
        RestResponse response = RestContext.response;
        response.addHeader('Content-type','application/json');
        String responseString = RestContext.request.requestBody.toString();
        Map<String, String> headers = RestContext.request.headers;
        String responseValid = validateWhatsAppSignature(RestContext.request, responseString);
        
        if(responseValid == SIGNATURE_VALID_MESSAGE){
            
            String fResponseString = responseString.replace('type', 'typex');
            WhatsAppMessage parentMessage = (WhatsAppMessage)JSON.deserialize( fResponseString, WhatsAppMessage.class);
            List<WhatsAppMessage.entry> messageEntries = parentMessage.entry;
            if(messageEntries != null && messageEntries.size() > 0){
                WhatsAppMessage.entry entryMessage = messageEntries.get(0);
                List<WhatsAppMessage.changes> changeMessages = entryMessage.changes;
                if(changeMessages != null && changeMessages.size() > 0){
                    WhatsAppMessage.changes changeMessage = changeMessages.get(0);
                    List<WhatsAppMessage.contacts> contactList = changeMessage.value.contacts;
                    List<WhatsAppMessage.messages> messageList = changeMessage.value.messages;
                    WhatsAppMessage.metadata metadata = changeMessage.value.metadata;


                    WPMessage__c salesforceMessage = new WPMessage__c();
                    salesforceMessage.BusinessNumber__c = metadata != null ? metadata.display_phone_number : null;
                    
                    if(contactList != null && contactList.size() > 0){
                        WhatsAppMessage.contacts contact = contactList.get(0);
                        salesforceMessage.CustomerPhone__c = contact.wa_id;
                        salesforceMessage.CustomerName__c = contact.profile.name;
                    }
                    
                    if(messageList != null && messageList.size() > 0){
                        /* Simple Message */
                        WhatsAppMessage.messages message = messageList.get(0);
                        salesforceMessage.MessageID__c = message.id;
                        salesforceMessage.MessageType__c = message.typex;
                        salesforceMessage.MessageSentTime__c = System.now();
                        salesforceMessage.MessageContent__c = message.text != null? message.text.body : null;
                        
                        /* If message is reaction */
                        salesforceMessage.Reaction__c = message.reaction != null ? message.reaction.emoji : null;
                        salesforceMessage.ParentMessageID__c = message.reaction != null ? message.reaction.message_id : null;
                        
                        /* If message is Image */
                        salesforceMessage.ImageId__c = message.image != null ? message.image.id : null;
                        salesforceMessage.ImageType__c = message.image != null ? message.image.mime_type : null;
                        salesforceMessage.ImageSHA256__c = message.image != null ? message.image.sha256 : null;
                        
                        /* If message is Video */
                        salesforceMessage.VideoId__c = message.video != null ? message.video.id : null;
                        salesforceMessage.VideoType__c = message.video != null ? message.video.mime_type : null;
                        salesforceMessage.VideoSHA256__c = message.video != null ? message.video.sha256 : null;
                        
                        /* If the message is reply to another message */
                        salesforceMessage.ParentMessageID__c = message.context != null ? message.context.id : null;
                        
                        upsert salesforceMessage MessageID__c;
                        
                        /* Publish the Platform Event to be listened by LWC */
                        WAMessageEvent__e platformEvent = new WAMessageEvent__e();
                        platformEvent.MessageId__c = salesforceMessage.Id;
                        platformEvent.CustomerPhone__c = salesforceMessage.CustomerPhone__c;
                        Eventbus.publish( platformEvent );
                        
                    }
                    
                }
            }
        }else{
            response.responseBody = Blob.valueOf('{success:false, event:"Unknown","message:"'+responseValid+'"}');
            response.statusCode = 401;
            return;
        }
        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{success:true, event:"success"}');
    }


    // private static String validateWhatsAppSignature(RestRequest request, String responseString) {
    //     // Validate Stripe signature Start 
    //     Map<String, String> headers = request.headers;
        
    //     String whatsAppSignature = headers.get('X-Hub-Signature-256');
        
    //     String whatsAppPayload = RestContext.request.requestBody.toString();
        
    //     // Verify the signature using 'hmacSHA256'. I have the Webhook key stored in a Custom Label
    //     String whatsAppSecret = System.Label.WHATSAPPSECRET; // Facebook Application Secret Key
    //     Blob signedPayload = Crypto.generateMac('hmacSHA256', Blob.valueOf(whatsAppPayload), Blob.valueOf( whatsAppSecret ));
        
    //     String encodedPayload = 'sha256='+EncodingUtil.convertToHex(signedPayload);
    //     // Return status code based on whether signed payload matches or not
        
    //     String response = (encodedPayload == whatsAppSignature)? SIGNATURE_VALID_MESSAGE : SIGNATURE_NOT_VALID_MESSAGE;
    //     return response;
    //     // Validate Stripe signature End 
    // }
    
    
    
}
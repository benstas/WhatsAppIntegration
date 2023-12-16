public with sharing class WPMessageUt {
    public static List<WPMessage__c> listAllMessageByCustomer(String customerPhone){
        List<WPMessage__c> messages = new List<WPMessage__c>();
        messages = [SELECT Id, Name, MessageContent__c, MessageType__c, Outgoing__c FROM WPMessage__c WHERE CustomerPhone__c =: customerPhone];
        return messages;
    }
    public static WPMessage__c sendTextMessage(String messageContent, String toPhone){
        
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Authorization', 'Bearer '+System.Label.TOKENWHATSAPP);
        
        String messageBody = '{'+
		'    "messaging_product": "whatsapp",'+
		'    "recipient_type": "individual",'+
		'    "to": "'+toPhone+'",'+
		'    "type": "text",'+
		'    "text": {'+
		'        "preview_url": false,'+
		'        "body": "'+messageContent+'"'+
		'    }'+
		'}';
        
        httpReq.setBody(messageBody);
        
        Http http = new Http();
        WPMessage__c salesforceMessage = new WPMessage__c();
        try{
            HttpResponse response = http.send(httpReq);
            if( response.getStatusCode() == 200 ){
                // Parse & Create Message Record
                System.debug('Successful!');
                WhatsAppUtils responseFromWA = (WhatsAppUtils) JSON.deserialize( response.getBody() , WhatsAppUtils.class);
                
                salesforceMessage.MessageContent__c = messageContent;
                salesforceMessage.CustomerPhone__c = toPhone;
                salesforceMessage.MessageID__c = responseFromWA.messages.get(0).id;
                salesforceMessage.MessageType__c = 'text';
                salesforceMessage.Outgoing__c = True;
                salesforceMessage.AgentName__c = UserInfo.getFirstName()+' '+ UserInfo.getLastName();
                upsert salesforceMessage MessageID__c;
            }
        }catch(System.CalloutException ex){
            System.debug(' CalloutException Executed '+ ex.getStackTraceString() );
            System.debug(' CalloutException Executed '+ ex.getMessage() );
        }catch(System.Exception ex){
            System.debug(' System.Exception Executed '+ ex.getStackTraceString() );
        }
        return salesforceMessage;
    }
    
  public String messaging_product;
	public contacts[] contacts;
	public messages[] messages;
	public class contacts {
		public String input;
		public String wa_id;
	}
	public class messages {
		public String id;
	}
}
public class WpLWCHandler {

    @AuraEnabled//(cacheable=true)
    public static List<WPMessage__c> listAllMessages(String customerPhone){
        List<WPMessage__c> messages = new List<WPMessage__c>();
        messages = [SELECT Id, Name, MessageContent__c, MessageType__c, CustomerName__c, AgentName__c, Outgoing__c, CreatedDate
                    FROM WPMessage__c
                    WHERE CustomerName__c =: customerPhone
                    Order By CreatedDate ASC
                ];
        return messages;
    }

    @AuraEnabled
    public static WPMessage__c getSingleMessage(String recordId, String customerPhone){
        return [SELECT Id, Name, MessageContent__c, MessageType__c, CustomerName__c, AgentName__c, Outgoing__c, CreatedDate
                    FROM WPMessage__c
                    WHERE Id =: recordId
                AND CustomerPhone__c =: customerPhone
                Order By CreatedDate ASC
            ];
    }
    
    @AuraEnabled
    public static WPMessage__c sendTextMessage(String messageContent, String toPhone){
        WPMessage__c message = WhatsAppUtils.sendTextMessage(messageContent, toPhone);
        return [SELECT Id, Name, MessageContent__c, MessageType__c, CustomerName__c, AgentName__c, Outgoing__c, CreatedDate
                FROM WPMessage__c
                WHERE Id =: message.Id
                Order By CreatedDate ASC
            ];
    }
    
    @AuraEnabled(cacheable=true) 
    public static List<WPMessage__c> listAllMessageByCustomer(String customerPhone){
        List<WPMessage__c> messages = new List<WPMessage__c>();
        messages = [SELECT Id, Name, MessageContent__c, MessageType__c, CustomerName__c, AgentName__c, Outgoing__c, CreatedDate
                    FROM WPMessage__c 
                    WHERE CustomerPhone__c =: customerPhone 
                    Order By CreatedDate ASC
                ];
        return messages;
    }
}
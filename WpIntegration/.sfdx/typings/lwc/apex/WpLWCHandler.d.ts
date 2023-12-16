declare module "@salesforce/apex/WpLWCHandler.listAllMessages" {
  export default function listAllMessages(param: {customerPhone: any}): Promise<any>;
}
declare module "@salesforce/apex/WpLWCHandler.getSingleMessage" {
  export default function getSingleMessage(param: {recordId: any, customerPhone: any}): Promise<any>;
}
declare module "@salesforce/apex/WpLWCHandler.sendTextMessage" {
  export default function sendTextMessage(param: {messageContent: any, toPhone: any}): Promise<any>;
}
declare module "@salesforce/apex/WpLWCHandler.listAllMessageByCustomer" {
  export default function listAllMessageByCustomer(param: {customerPhone: any}): Promise<any>;
}

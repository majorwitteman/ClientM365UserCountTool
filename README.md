# ClientM365UserCountTool

## Environment Variables

- CwCompanyTypeId  
This is for the ConnectWise Manage Type ID number
- CwPublicKey  
ConnectWise Manage API Public Key
- CwPrivateKey  
ConnectWise Manage API Private Key
- CwCompany  
ConnectWise Manage API Company
- CwClientId  
ConnectWise Manage API ClientId, this is generated from the ConnectWise developer integration page
- CwApiUri  
ConnectWise Manage API location
- CwApiVersion  
ConnectWise Manage API version to use; this was built and tested against `2020.4` and should be periodically updated and tested
- MsGraphClientId  
Microsoft Graph Client ID for service principal that is in the AdminAgents group and have application permissions for `Reports.Read.All`
- MsGraphClientSecret  
Secret for above client
- MsGraphMailClientTenantId  
The tenant ID for where to send email from
- MsGraphMailClientId  
Microsoft Graph Client ID for service principal that is used to send mail, must have applications for `Mail.Send`
- MsGraphMailClientSecret  
Secret for above client
- MailTo  
Recipient for email with attachment
- MailFrom  
Account that is used to send the message through the MSGraphMailClient

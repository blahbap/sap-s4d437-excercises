@EndUserText.label: 'Travel projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true 

define root view entity Z10_c_travel
  as projection on Z10_I_TRAVEL
{
  key Trguid,
      @Search.defaultSearchElement: true
      AgencyID,
      TravelID,
      TravelDescription,
      @Consumption.valueHelpDefinition: [{
         entity: {
         name: 'D437_I_Customer',
         element: 'Customer'
         }
     }]
     @Search.defaultSearchElement: true
      CustomerID,
      StartDate,
      EndDate,
      Status,
      ChangedAt,
      ChangedBy
}
